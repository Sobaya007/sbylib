module sbylib.engine.tools.dscanner;

import std;
import sbylib.engine.util : importPath;

class DScanner {
static:

    Tuple!(string[], SysTime)[string] importListMemo;

    string[] importListRecursive(alias constraint = (string f) => true)(string file) {
        string[] result = importList(file).filter!(constraint).array;
        while (true) {
            const n = result.length;
            result = (result ~ result.map!(f => importList(f).filter!(constraint)).join).sort.uniq.array;
            if (result.length == n) break;
        }
        return result;
    }

    string[] importList(string file) 
        out (r; r.all!(exists), r.to!string)
    {
        if (auto memo = file in importListMemo) {
            if ((*memo)[1] == file.timeLastModified) {
                return (*memo)[0];
            }
        }

        auto result = execute("-i " ~ file ~ " " ~ importPath.map!(p => "-I" ~ p).join(" "))
            .filter!(line => line.isValidPath)
            .array;

        importListMemo[file] = tuple(result, file.timeLastModified);

        enum Head = "Could not resolve location of";
        auto errors = result.filter!(r => r.startsWith(Head));
        if (!errors.empty) {
            throw new ResolveLocationException(format!"%s:\n%s\nimportPath=%s"
                    (Head, errors.map!(e => e.split(Head).back).join("\n"), 
                     importPath.join("\n")));
        }

        return result;
    }

    private string[] execute(string cmd) {
        const result = executeShell("dscanner " ~ cmd);
        if (result.status != 0) {
            throw new Exception(result.output);
        }
        return result.output
            .split("\n")
            .filter!(s => s.length > 0)
            .array;
    }
}

class ResolveLocationException : Exception {
    mixin basicExceptionCtors;
}
