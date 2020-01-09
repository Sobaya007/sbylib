module sbylib.engine.util;

import std;
import sbylib.engine;

string[] importPath() {
    return Dub.getImportPath() ~ findPhobosPath() ~ ".";
}

auto dependentLibraries() {
    const data = Dub.describe();

    string[] dependentPackageList(string root) {
        void func(string root, ref string[] current) {
            foreach (dependency; data.findPackage(root).dependencies
                    .filter!(n => current.canFind(n) is false)) {
                current ~= dependency;
                func(dependency, current);
            }
        }
        string[] result;
        func(root, result);
        return result;
    }

    struct Result {
        string[] librarySearchPathList;
        string[] libraryPathList;
    }

    Result result;

    foreach (p; dependentPackageList(data.rootPackageName)
        .map!(n => data.findPackage(n))
        .filter!(p => p.targetFileName.endsWith(".a"))) {

        result.librarySearchPathList ~= buildPath(p.path, p.targetPath);
        result.libraryPathList ~= p.targetFileName;
    }

    result.librarySearchPathList = result.librarySearchPathList.sort.uniq.array;
    result.libraryPathList = result.libraryPathList.sort.uniq.array;
    return result;
}

string fontPath(string filename) {
    import std.path : buildPath;
    return fontDir.buildPath(filename);
}

string fontDir() {
    import std.path : buildPath;
    return rootDir.buildPath("font");
}

string resourcePath(string filename) {
    import std.path : buildPath;
    return resourceDir.buildPath(filename);
}

string resourceDir() {
    import std.path : buildPath;
    return rootDir.buildPath("resource");
}

string rootDir() {
    import std.algorithm : filter;
    import std.conv : to;
    import std.file : dirEntries, SpanMode;
    import std.path : dirName, buildNormalizedPath;
    import std.string : endsWith;
    
    string file = __FILE_FULL_PATH__.dirName;

    while (file.dirEntries(SpanMode.shallow).filter!(path => path.to!string.endsWith(".dub")).empty) {
        assert(file.dirName != file);
        file = file.dirName;
    }

    return file.buildNormalizedPath();
}

string cacheDir() {
    auto dir = ".cache";
    if (dir.exists == false)
        mkdirRecurse(dir);

    return dir;
}

private string[] findPhobosPath() {
    import std.file : write;

    const cacheFile = cacheDir.buildPath("phobospath");
    if (cacheFile.exists)
        return readText(cacheFile).chomp.split("\n");

    auto file = cacheDir.buildPath("tmp.d");
    file.write(q{
/+dub.sdl:
dependency "dmd" version="~master"
+/
void main()
{
    import dmd.frontend;
    import std.stdio;
    findImportPaths().writeln;
}
});
    
    auto result = execute(["dub", file]).output
    .split("\n")
    .filter!(line => line.startsWith("["))
    .map!(line => line.to!(string[]))
    .join;

    foreach (r; result) enforce(r.exists, format!"'%s' does not exist."(r));
    cacheFile.write(result.join("\n"));

    return result;
}

string color(int colorCode)(string str) {
    return format!"\x1b[%dm%s\x1b[39m"(colorCode, str);
}

alias red = color!(31); 
alias green = color!(32); 
alias yellow = color!(33); 
alias blue = color!(34); 
alias magenda = color!(35); 
alias cyan = color!(36); 
alias white = color!(37); 
