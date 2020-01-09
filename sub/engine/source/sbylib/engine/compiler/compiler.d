module sbylib.engine.compiler.compiler;

import std;
import core.thread : Thread;
import core.atomic : atomicOp;
import core.sync.semaphore;

import sbylib.engine;
import sbylib.event;
import sbylib.engine.compiler.exception;

class Compiler {
static:

    private __gshared int[string] seedList;
    private __gshared Semaphore semaphore;

    struct CompileResult { string output, outputFileName; bool success; }

    void finalize() {
        foreach (file, seed; seedList) {
            foreach (i; 0..seed) {
                if (getFileName(file,i).exists) remove(getFileName(file, i));
            }
            if (getFileName(file, seed).exists) rename(getFileName(file, seed), getFileName(file, 0));
        }
    }

    auto compile(string inputFileName) {
        try {
            auto dependencies = memoize!dependentLibraries();
            auto config = immutable CompileConfig(
                    inputFileName,
                    DScanner.importListRecursive!((string f) => isProjectFile(f))(inputFileName)
                        .filter!((string f) =>
                            f.asAbsolutePath.asNormalizedPath.array != inputFileName.asAbsolutePath.asNormalizedPath.array)
                        .array.idup,
                    memoize!importPath.idup,
                    dependencies.libraryPathList.idup,
                    dependencies.librarySearchPathList.idup);

            return build(config).then((CompileResult r) {
                if (!r.success) throw new CompileErrorException(r.output);
                return new DLL(r.outputFileName); });
        } catch (ResolveLocationException e) {
            return promise!({
                if (e !is null) {
                    throw new CompileErrorException(
                        "Error in compiling " ~ inputFileName ~ ":\n" ~ e.msg);
                }
                return cast(DLL)null;
            });
        }
    }

    private auto build(immutable CompileConfig config) {
        const base = config.mainFile.baseName(config.mainFile.extension);
        auto seed = base in seedList ? seedList[base] : (seedList[base] = 0);
        auto outputFileName = getFileName(base, seed);

        if (outputFileName.exists) {

            auto modifiedDependencies = config.dependencies
                .filter!(dep => dep.timeLastModified > outputFileName.timeLastModified);

            if (modifiedDependencies.empty) {
                return promise!({ return CompileResult("", outputFileName, true); });
            }

            seed = ++seedList[base];
            outputFileName = getFileName(base, seed);
        }

        const command = config.createCommand(outputFileName);

        if (semaphore is null) semaphore = new Semaphore(1);

        return promise!((void delegate(CompileResult) resolve) {
            new Thread({
                semaphore.wait();
                scope (exit) semaphore.notify();

                auto dmd = execute(command);

                if (dmd.status != 0) {
                    resolve(CompileResult(format!"Compilation failed\n%s"(dmd.output), outputFileName, false));
                    return;
                }
                remove(format!"%s/%s%d.o"(cacheDir, base, seed));

                resolve(CompileResult(dmd.output, outputFileName, true));
            }).start();
        });
    }

    private bool isProjectFile(string f) {
        const projectRoot = MetaInfo().projectDirectory.absolutePath;
        f = f.absolutePath.asNormalizedPath.array;

        while (f != f.dirName) {
            if (f == projectRoot) return true;
            f = f.dirName;
        }
        return false;
    }

    private string getFileName(string base, int seed) {
        return format!"%s/%s%d.so"(cacheDir, base, seed);
    }
}

private struct CompileConfig {
    string   mainFile;
    string[] inputFiles;
    string[] importPath;
    string[] libraryPath;
    string[] librarySearchPath;

    string[] createCommand(string outputFileName) const {
        version (DigitalMars) {
            return ["dmd"]
                ~ "-L=-fuse-ld=gold"
                ~ "-g"
                ~ mainFile
                ~ inputFiles
                ~ ("-of="~ outputFileName)
                ~ "-shared"
                ~ importPath.map!(p => "-I" ~ p).array
                ~ librarySearchPath.map!(f => "-L-L" ~ f).array
                ~ libraryPath.map!(f => "-L-l" ~ f[3..$-2]).array;
        } else version (LDC) {
            return ["dmd"]
                ~ "-g"
                ~ mainFile
                ~ inputFiles
                ~ ("-of="~ outputFileName)
                ~ "-shared"
                ~ importPath.map!(p => "-I" ~ p).array
                ~ librarySearchPath.map!(f => "-L-L" ~ f).array
                ~ libraryPath.map!(f => "-L-l" ~ f[3..$-2]).array;
        } else {
            static assert("This compiler is not supported");
        }
    }

    auto lastModified() const {
        return dependencies
            .map!(p => p.timeLastModified)
            .reduce!max;
    }

    auto dependencies() const {
        return ([mainFile]
             ~ inputFiles
             ~ importPath
             ~ libraryPath.map!(p => search(p)).array)
            .filter!(p => p.isFile)
            .array;
    }

    private auto search(string p) const {
        auto tmp = librarySearchPath
            .map!(d => d.buildPath(p))
            .filter!(p => p.exists);
        enforce(tmp.empty is false, "Library not found: " ~ p);
        return tmp.front;
    }
}
