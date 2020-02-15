module sbylib.engine.project.entry;

import std;
import sbylib.engine.project.project : Project;
import sbylib.engine.project.modulecontext : ModuleContext;

template Register(alias f, string mn = moduleName!f) {
    static if (is(Parameters!f == AliasSeq!(Project, ModuleContext))) {
        private enum fn = f.mangleof;
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
    } else {
        @(__traits(getAttributes, f))
        ReturnType!f __entryPoint__(Project proj, ModuleContext context) {
            Parameters!f args;
            static foreach (i, a; args) {
                static if (is(typeof(a) == ModuleContext)) {
                    a = context;
                } else static if (is(typeof(a) == Project)) {
                    a = proj;
                } else {
                    a = proj.get!(typeof(a))(ParameterIdentifierTuple!f[i]);
                }
            }
            return f(args);
        }

        enum Register = Register!(__entryPoint__, moduleName!f);
    }
}

struct Depends {
    string[] moduleNameList;
}

Depends depends(string[] moduleNameList...) {
    return Depends(moduleNameList);
}
