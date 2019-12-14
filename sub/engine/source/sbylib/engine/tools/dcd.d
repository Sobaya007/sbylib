module sbylib.engine.tools.dcd; 

import std;
import sbylib.engine.util;

class DCD {

    enum PORT = 8090;

    private Pid server;

    this() {
        this.server = spawnProcess(["dcd-server"] ~ args,
                stdin, File("dcd-stdout.log", "w"), File("dcd-stderror.log", "w"));
    }

    ~this() {
        this.server.kill();
        this.server.wait();
    }

    string[] complete(string filename, long cursorPos) {
        return execute(["dcd-client"] ~ args ~ ["-c", cursorPos.format!"%s", filename])
            .output
            .split("\n")
            .map!(line => line.split("\t"))
            .filter!(words => words.length >= 2)
            .map!(words => words[0])
            .array;
    }

    private string[] args() {
        return [PORT.format!"-p%d"] ~ importPath.map!(i => i.format!"-I%s").array;
    }
}
