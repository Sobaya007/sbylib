module sbylib.engine.project.moduleunit;

import std;
import std.digest.md : md5Of;
import sbylib.event;
import sbylib.engine.compiler.compiler;
import sbylib.engine.compiler.dll;
import sbylib.engine.compiler.exception;
import sbylib.engine.project.project;
import sbylib.engine.project.metainfo;
import sbylib.engine.project.modulecontext;
import sbylib.engine.promise;

// TODO: implement seriously
bool isModule(string file) 
    in (file.exists)
{
    return readText(file).split("\n")
        .map!(chomp)
        .filter!(line => line.startsWith("//") is false)
        .filter!(line => line.canFind("mixin"))
        .filter!(line => line.canFind("Register"))
        .empty is false;
}

class Module(RetType) {

    private enum State { NotYet, Compling, Success, Fail }

    private alias FuncType = RetType function(Project, ModuleContext);

    private ModuleContext context;
    private FuncType func;
    private DLL dll;
    private Project proj;
    string path;
    string name;
    string[] dependencies;
    Promise!(RetType) execution;
    private immutable ubyte[16] hash;
    CompileErrorException error;

    this(Project proj, string path) {
        this.path = path;
        this.proj = proj;
        this.context = new ModuleContext;
        this.hash = md5Of(readText(path));
        Compiler.compile(path)
        .error((Exception e) {
            this.error = cast(CompileErrorException)e;
        })
        .then((DLL dll) {
            this.initFromDLL(dll);
        });
    }

    ~this() {
        this.context.destroy();
        //this.dll.unload();
    }
    
    private void initFromDLL(DLL dll) {
        this.dll = dll;

        auto getFunctionName = dll.loadFunction!(string function())("getFunctionName");
        auto functionName = getFunctionName();
        this.func = dll.loadFunction!(FuncType)(functionName);

        auto getModuleName = dll.loadFunction!(string function())("getModuleName");
        this.name = getModuleName();

        auto getDependencies = dll.loadFunction!(string[] function())("getDependencies");
        this.dependencies = getDependencies();
    }

    void execute() 
        in (execution is null)
    {
        execution = promise!({
            context.bind();
            return func(proj, context);
        });
    }

    package bool hasLoaded() {
        return func !is null;
    }

    package bool hasError() {
        return error !is null;
    }

    package bool executed() {
        return execution && execution.finished;
    }

    package bool hasModified() {
        return md5Of(readText(path)) != this.hash;
    }
}

template Register(alias f) {
    private enum fn = f.mangleof;
    private enum mn = moduleName!f;
    private alias d = getUDAs!(f, Depends);
    static if (d.length == 0) {
        private enum ds = "[]";
    } else {
        private enum ds = d[0].moduleNameList.map!(s => `"`~s~`"`).join(",").format!"[%s]";
    }

    enum Register = format!q{
        extern(C) string getFunctionName() { return "%s"; }
        extern(C) string getModuleName() { return "%s"; }
        extern(C) string[] getDependencies() { return %s; }
    }(fn, mn, ds);
}

struct Depends {
    string[] moduleNameList;
}

Depends depends(string[] moduleNameList...) {
    return Depends(moduleNameList);
}
