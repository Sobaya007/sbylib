module sbylib.engine.tools.dub;

import std;
import sbylib.engine.project.metainfo : MetaInfo;

class Dub {
static:

    string[] getImportPath() 
        out (r; r.all!(p => p.exists))
    {

        auto result = describe("--import-paths");
        result ~= absolutePath(MetaInfo().projectDirectory);

        return result;
    }

    string[] getVersions() {
        return getData("versions");
    }

    auto describe() {
        return DescribeResult(parseJSON(describe("").join("\n")));
    }

    private string[] getData(string name) {
        return describe("--data=" ~ name);
    }

    private string[] describe(string option) {
        return execute("describe " ~ option);
    }

    private string[] execute(string cmd) {
        const result = executeShell("dub " ~ cmd);
        if (result.status != 0) {
            throw new Exception(result.output);
        }
        return result.output
            .split("\n")
            .filter!(s => s.length > 0)
            .array;
    }
}

struct DescribeResult {
    private JSONValue content;

    auto root() const {
        return content.object;
    }

    auto packages() const {
        return root["packages"].array
            .map!(p => Package(p));
    }

    auto rootPackageName() const {
        return root["rootPackage"].str;
    }

    auto rootPackage() const {
        return findPackage(rootPackageName);
    }

    auto findPackage(string name) const {
        return packages
            .filter!(p => p.name == name)
            .front;
    }
}

struct Package {

    private JSONValue content;

    auto root() const { 
        return content.object; 
    }

    string name() const { 
        return root["name"].str; 
    }

    string path() const {
        return root["path"].str;
    }

    string targetFileName() const {
        return root["targetFileName"].str; 
    }

    string targetPath() const {
        return root["targetPath"].str; 
    }

    auto dependencies() const { 
        return root["dependencies"].array
            .map!(s => s.str);
    }

}
