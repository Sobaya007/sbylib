module sbylib.engine.entry;

import std;
import core.exception : AssertError;
import sbylib.event;
import sbylib.engine;

private bool running = true;

struct EngineSetting {
    string projectDirectory;
}

void startEngine(EngineSetting setting, Variant[string] env = null) {

    registerErrorHandler();

    MetaInfo().projectDirectory = setting.projectDirectory;

    auto proj = new Project();
    scope (exit) Compiler.finalize();

    foreach (key, value; env) {
        proj[key] = value;
    }

    while (running) {
        FrameEventWatcher.update();
    }
    proj.destroy();

    engineStopEventList.each!(e => e.fire());
}

void stopEngine() {
    running = false;
}
