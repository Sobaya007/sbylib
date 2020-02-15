module sbylib.engine.project.project;

import std;
import sbylib.event;
import sbylib.engine.project.metainfo;
import sbylib.engine.project.moduleunit;
import sbylib.engine.project.modulestatus;
import sbylib.engine.compiler : CompileErrorException;
import sbylib.engine.util : resourcePath;

class Project {

    private alias VModule = Module!(void);
    alias global this;

    VModule[string] moduleList;
    Variant[string] global;
    private ModuleStatusList status;

    this() {
        status = new ModuleStatusList();
        this.refreshPackage();
        this.loadAll();
    }

    ~this() {
        foreach (mod; moduleList.values) {
            mod.destroy();
        }
    }

	private void loadAll() {
        foreach (file; this.projectFiles) {
            this.loadSingle(file);
        }
    }

    private void loadSingle(string file) {
        auto mod = new VModule(this, status, file.absolutePath.buildNormalizedPath); 
        moduleList[mod.path] = mod;

        auto modified = mod.path.hasModified;
        foreach (d; mod.dependencies)
            modified = modified | d.hasModified;
        foreach (f; mod.inputFiles)
            modified = modified | f.hasModified;

        when(modified).once({
            this.loadSingle(file);
        });
    }

    auto get(T)(string name) {
        if (name !in this) return null;
        return this[name].get!T;
    }

    string[] projectFiles() {
        enforce(MetaInfo().projectDirectory.exists,
                format!`"%s" does not exists.`(MetaInfo().projectDirectory));
        return MetaInfo().projectDirectory.dirEntries(SpanMode.breadth)
            .filter!(entry => entry.isFile)
            .filter!(entry => entry.baseName != "package.d")
            .filter!(entry => entry.isModule)
            .map!(entry => cast(string)entry)
            .array;
    }

    void refreshPackage() {
        import std.file : write;

        auto projectName = MetaInfo().projectDirectory;
        if (!projectName.exists)
            mkdirRecurse(projectName);

        foreach (entry; projectName.dirEntries(SpanMode.breadth)) {
            if (entry.isFile) continue;

            const fileName = entry.buildPath("package.d");

            auto dirImportList = entry
                .dirEntries(SpanMode.shallow)
                .filter!(e => e.isDir)
                .map!(e => e.relativePath(projectName))
                .map!(p => p.replace("/", "."))
                .map!(name => name.format!"import %s;")
                .array;
            auto fileImportList = entry
                .dirEntries(SpanMode.shallow)
                .filter!(e => e.isFile)
                .map!(e => e.relativePath(projectName))
                .filter!(p => p.extension == ".d")
                .filter!(p => p.baseName != "package.d")
                .map!(e => e.stripExtension.replace("/", "."))
                .map!(name => name.format!"import %s;")
                .array;

            const moduleName = entry.replace("/", ".");
            const content = resourcePath("package.d").readText
                .replace("${moduleName}", moduleName)
                .replace("${importList}", (dirImportList ~ fileImportList).join("\n"));

            fileName.write(content);
        }
    }

    // name -> path
    string findPath(string name) {
        auto findResult = moduleList.values.find!(mod => mod.name == name);
        enforce(!findResult.empty || moduleList.values.any!(m => status[m.path] != ModuleStatus.Compiling), format!"Module '%s' is not found."(name));
        return findResult.empty ? "" : findResult.front.path;
    }

    private auto findLoadedModule(string modName) {
        auto result = moduleList.values
            .find!(m => m.name == modName);
        return result;
    }
}

// TODO: implement seriously
private bool isModule(string file) 
    in (file.exists)
{
    return readText(file).split("\n")
        .map!(chomp)
        .filter!(line => line.startsWith("//") is false)
        .filter!(line => line.canFind("mixin"))
        .filter!(line => line.canFind("Register"))
        .empty is false;
}
