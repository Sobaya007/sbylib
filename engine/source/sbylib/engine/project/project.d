module sbylib.engine.project.project;

import std;
import sbylib.event;
import sbylib.engine.project.metainfo : MetaInfo;
import sbylib.engine.project.moduleunit : Module, isModule;
import sbylib.engine.compiler : CompileErrorException;
import sbylib.engine.util : resourcePath, blue, yellow, cyan, green, red, magenda;

enum ModuleStatus {
    WaitingForCompile,
    Compiling,
    WaitingForRun,
    Running,
    CompileError
}

class ModuleStatusList {
    private ModuleStatus[string] status;
    private string[string] msg;

    this(string[] keys) {
        foreach (key; keys) {
            status[key] = ModuleStatus.WaitingForCompile;
        }
        rewriteStatus();
    }

    ModuleStatus[] values() {
        return status.values;
    }

    ModuleStatus opIndex(string key) {
        return status[key];
    }

    ModuleStatus opIndexAssign(ModuleStatus s, string key) {
        status[key] = s;
        rewriteStatus();
        return s;
    }

    void opIndexAssign(Tuple!(ModuleStatus, string) t, string key) {
        status[key] = t[0];
        msg[key] = t[1];
        rewriteStatus();
    }

    private void rewriteStatus() {
        clearScreen();
        foreach (key, value; status) {
            writefln("%30s : %20s", key, colorize(value));
            if (value == ModuleStatus.CompileError) {
                writeln(msg[key].split("\n").map!(s => " ".repeat.take(32).join ~ s).join("\n").magenda);
            }
        }
    }

    private void clearScreen() {
        writefln("\033[%d;%dH" ,0,0); // move cursor
        writeln("\033[2J"); // clear screen
    }

    private string colorize(ModuleStatus status) {
        final switch (status) {
            case ModuleStatus.WaitingForCompile:
                return status.to!string.blue;
            case ModuleStatus.Compiling:
                return status.to!string.yellow;
            case ModuleStatus.WaitingForRun:
                return status.to!string.cyan;
            case ModuleStatus.Running:
                return status.to!string.green;
            case ModuleStatus.CompileError:
                return status.to!string.red;
        }
    }
}

class Project {

    private alias VModule = Module!(void);

    VModule[string] moduleList;

    Variant[string] global;
    alias global this;

    ModuleStatusList status;

    this() {
        status = new ModuleStatusList(this.projectFiles);
        this.refreshPackage();
        this.loadAll();
    }

    ~this() {
        foreach (mod; moduleList.values) {
            mod.destroy();
        }
    }

    void addFile(string file) {
        if (file.dirName.exists is false)
            file.dirName.mkdirRecurse();

        resourcePath("template.d").copy(file);
        this.refreshPackage();
    }

	private void loadAll() {
        foreach (file; this.projectFiles) {
            this.loadSingle(file);
        }
    }

    private void loadSingle(string file) {
        status[file] = ModuleStatus.Compiling;

        VModule mod = load(file);
        moduleList[mod.path] = mod;

        when(mod.hasLoaded).once({
            status[file] = ModuleStatus.WaitingForRun;

            // when all dependencies have been executed
            when(mod.dependencies.map!(d => findModule(d)).all!(d => !d.empty && d.front.executed)).once({
                status[file] = ModuleStatus.Running;
                mod.execute();
            });
        });

        when(mod.hasError).once({
            status[file] = tuple(ModuleStatus.CompileError, mod.error.msg);

            when(shouldReload(mod)).once({
                this.loadSingle(file);
            });
        });
    }

    void reloadAll() {
        const target = moduleList.values.filter!(mod => shouldReload(mod)).array;

        // stop all targets
        target.each!((mod) {
            // can stop a module on which no module depends 
            when(moduleList.values.map!(m => m.dependencies).join.all!(d => mod.name != d)).once({
                moduleList.remove(mod.path);
                mod.destroy();
            });
        });

        // when all targets stop, restart
        auto targetPaths = target.map!(t => t.path).array;
        when(targetPaths.all!(key => key !in moduleList)).once({
            targetPaths.each!((path) {
                auto newMod = load(path);
                moduleList[newMod.path] = newMod;

                // when module is loaded and all its dependencies have been executed
                when(newMod.hasLoaded
                        && newMod.dependencies.map!(d => findModule(d)).all!(d => !d.empty && d.front.executed))
                .once({
                    newMod.execute();
                });
            });
        });
	}

    private bool shouldReload(VModule mod) {
        return mod.hasModified || mod.dependencies.any!(d => shouldReload(findModule(d).front));
    }

    private VModule load(string file) {
        return new VModule(this, file.absolutePath.buildNormalizedPath);
    }

    bool shouldFinish() {
        return status.values.all!(s => s == ModuleStatus.CompileError || s == ModuleStatus.WaitingForRun)
            && moduleList.values.any!(mod => mod.hasError);
    }

    auto get(T)(string name) {
        if (name !in this) return null;
        return this[name].get!T;
    }

    string[] projectFiles() {
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

    private auto findModule(string modName) {
        auto result = moduleList.values
            .filter!(m => m.hasLoaded)
            .find!(m => m.name == modName);
        if (moduleList.values.all!(mod => mod.hasLoaded)) {
            enforce(!result.empty, "Cannot find module "~modName);
        }
        return result;
    }
}
