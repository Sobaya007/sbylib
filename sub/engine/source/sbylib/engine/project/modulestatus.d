module sbylib.engine.project.modulestatus;

import std;
import sbylib.engine.util : blue, yellow, cyan, green, red, magenda, gray;

enum ModuleStatus {
    Compiling,
    WaitingForRun,
    Running,
    CompileError,
    RuntimeError,
    Stopping,
}

class ModuleStatusList {
    private ModuleStatus[string] status;
    private string[string] msg;

    ModuleStatus[] values() {
        return status.values;
    }

    ModuleStatus opIndex(string key) const 
        in (key in status, key ~ " is not registered")
    {
        return status[key];
    }

    ModuleStatus opIndexAssign(ModuleStatus s, string key) 
        in (key !in status || status[key] != s)
    {
        status[key] = s;
        rewriteStatus();
        return s;
    }

    void opIndexAssign(Tuple!(ModuleStatus, string) t, string key)
        in (key !in status || status[key] != t[0])
    {
        status[key] = t[0];
        msg[key] = t[1];
        rewriteStatus();
    }

    private void rewriteStatus() {
        clearScreen();
        foreach (key, value; status.byKeyValue.array.sort!((a,b) => a.key < b.key).map!(p => tuple(p.key, p.value)).assocArray) {
            writefln("%30s : %20s", key, colorize(value));
            if (value == ModuleStatus.CompileError) {
                writeln(msg[key].magenda);
            }
            if (value == ModuleStatus.RuntimeError) {
                writeln(msg[key].magenda);
            }
        }
    }

    private void clearScreen() const {
        writefln("\033[%d;%dH" ,0,0); // move cursor
        writeln("\033[2J"); // clear screen
    }

    private static string colorize(in ModuleStatus status) {
        final switch (status) {
            case ModuleStatus.Compiling:
                return status.to!string.yellow;
            case ModuleStatus.WaitingForRun:
                return status.to!string.cyan;
            case ModuleStatus.Running:
                return status.to!string.green;
            case ModuleStatus.CompileError:
                return status.to!string.red;
            case ModuleStatus.RuntimeError:
                return status.to!string.red;
            case ModuleStatus.Stopping:
                return status.to!string.gray;
        }
    }
}
