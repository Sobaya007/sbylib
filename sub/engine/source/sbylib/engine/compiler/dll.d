module sbylib.engine.compiler.dll;

import std;
import core.runtime;
import core.thread;
import core.sys.posix.dlfcn;

class DLL {

    private void* lib;
    private string dllname;

    this(string dllname) {
        this.dllname = dllname;

        if (dllname.exists is false)
            throw new Exception(format!"Shared library '%s' does not exist"(dllname));

        foreach (i; 0..10) {
            this.lib = Runtime.loadLibrary(dllname);
            if (lib is null)
                Thread.sleep(1.seconds);
            else
                return;
        }
        version (Posix) {
            throw new Exception(dlerror().fromStringz.format!"Could not load shared library:%s");
        } else {
            throw new Exception(format!"Could not load shared library: %s"(dllname));
        }
    }

    void unload() {
        Runtime.unloadLibrary(this.lib);
    }

    auto loadFunction(FunctionType)(string functionName) {
        const f = dlsym(lib, functionName.toStringz);
        if (f is null) throw new Exception(format!"Could not load function '%s' from %s"(functionName, dllname));

        auto func = cast(FunctionType)f;
        if (func is null) throw new Exception(format!"The type of '%s' is not '%s'"(functionName, FunctionType.stringof));

        return func;
    }

}
