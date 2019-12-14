module sbylib.engine.project.modulecontext;

import std;
import sbylib.event;

class ModuleContext {

    EventContext context;
    alias context this;

    private void delegate()[] releaseList;

    this() {
        this.context = new EventContext;
    }

    ~this() {
        context.destroy();
        releaseList.retro.each!(r => r());
    }

    T pushResource(T)(T t) {
        this.releaseList ~= { t.destroy(); };
        return t;
    }

    void pushReleaseCallback(void delegate() release) {
        this.releaseList ~= release;
    }
}
