module sbylib.engine.project.moduleunit;

import std;
import sbylib.event;
import sbylib.engine.compiler.compiler;
import sbylib.engine.compiler.dll;
import sbylib.engine.compiler.exception;
import sbylib.engine.project.project;
import sbylib.engine.project.metainfo;
import sbylib.engine.project.modulecontext;
import sbylib.engine.project.modulestatus;
import sbylib.engine.promise;

class Module(RetType) {
    private alias FuncType = RetType function(Project, ModuleContext);

    const string path;
    private ModuleContext _context;
    private Project proj;
    private DLL dll;
    private ModuleStatusList statusList;

    private FuncType func;
    private string _name;
    private string[] _dependencies;

    this(Project proj, ModuleStatusList statusList, string path) {
        this.proj = proj;
        this.statusList = statusList;
        this.path = path;
        this._context = new ModuleContext;

        this.status = ModuleStatus.Compiling;
        Compiler.compile(path)
        .error((Exception e) {
            assert(this.status == ModuleStatus.Compiling);
            this.status = tuple(ModuleStatus.CompileError, e.msg);
        })
        .then((DLL dll) {
            this.initFromDLL(dll);
            assert(this.status == ModuleStatus.Compiling);
            this.status = ModuleStatus.WaitingForRun;

            when(dependencies.map!(d => proj.findPath(d)).all!(d => d != "" && statusList[d] == ModuleStatus.Running)).once({
                this.execute(proj);
            });
        });
    }

    ~this() {
        if (this.status != ModuleStatus.Stopping)
            this.stop();
    }

    void stop() {
        this.context.destroy();
        this.status = ModuleStatus.Stopping;
        //this.dll.unload();
    }
    
    private void initFromDLL(DLL dll) {
        this.dll = dll;

        auto getFunctionName = dll.loadFunction!(string function())("getFunctionName");
        auto functionName = getFunctionName();
        this.func = dll.loadFunction!(FuncType)(functionName);

        auto getModuleName = dll.loadFunction!(string function())("getModuleName");
        this._name = getModuleName();

        auto getDependencies = dll.loadFunction!(string[] function())("getDependencies");
        this._dependencies = getDependencies();
    }

    private void execute(Project proj) 
        in (status == ModuleStatus.WaitingForRun)
    {
        this.status = ModuleStatus.Running;
        try {
            context.bind();
            func(proj, context);
        } catch (Exception e) {
            assert(this.status == ModuleStatus.Running);
            status = tuple(ModuleStatus.RuntimeError, e.toString());
        }
    }

    ModuleContext context() {
        return _context;
    }

    private void status(T)(T t) {
        statusList[path] = t;
    }

    private ModuleStatus status() const {
        return statusList[path];
    }

    package string name() const { return  _name; }
    package const(string[]) dependencies() const { return _dependencies; }

    package string[] inputFiles() {
        auto c = CompileConfig(path);
        return c.mainFile ~ c.inputFiles;
    }
}
