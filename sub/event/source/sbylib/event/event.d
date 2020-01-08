module sbylib.event.event;

import std;
import sbylib.wrapper.glfw;
import sbylib.event;

interface IEvent {
    void kill();
    void addFinishCallback(void delegate());
    bool isAlive() const;
    EventContext[] context();
}

class Event(Args...) : IEvent {
    private void delegate(Args) callback;
    private void delegate(Exception) onerror;
    public bool delegate() killCondition;
    private void delegate()[] finishCallbackList;
    package EventContext[] _context;
    private bool alive = true;

    this() {
        foreach (c; EventContext.currentContext) {
            _context ~= c;
        }
        foreach (c; context) {
            c.eventList ~= this;
        }
        EventWatcher._eventList ~= this;
    }

    void fire(Args args) {
        try {
            if (this.isAlive is false) return;
            if (killCondition && killCondition()) {
                this.alive = false;
                foreach (cb; finishCallbackList) cb();
                return;
            }
            if (context.any!(c => c.isBound is false)) return;
            if (callback) callback(args);
        } catch (Throwable e) {
            if (context.empty) {
                this.kill();
            } else {
                assert(context.all!(c => c.eventList[].canFind(this))); // for destroy myself
                context.each!(c => c.destroy());
            }
            assert(this.killCondition !is null && this.killCondition()); // to ensure this event is already dead.
            throw e;
        }
    }

    void fireOnce(Args args) {
        this.fire(args);
        this.kill();
        this.fire(args); // for launch finish callback
    }

    void throwError(Exception e) {
        this.kill();
        if (onerror) onerror(e);
        else throw e;
    }

    override bool isAlive() const {
        return alive;
    }

    override void kill() {
        this.killCondition = () => true;
    }

    override void addFinishCallback(void delegate() finishCallback) {
        if (this.isAlive) {
            this.finishCallbackList ~= finishCallback;
        } else {
            finishCallback();
        }
    }

    override EventContext[] context() {
        return _context;
    }
}

Event!(Args) then(Args...)(Event!(Args) event, void delegate() callback) 
    if (Args.length > 0)
{
    assert(event.callback is null);
    event.callback = (Args _) { callback(); };
    return event;
}

Event!(Args) then(Args...)(Event!(Args) event, void delegate(Args) callback) {
    assert(event.callback is null);
    event.callback = callback;
    return event;
}

Event!(Args) error(Args...)(Event!(Args) event, void delegate(Exception) callback) {
    assert(event.onerror is null);
    event.onerror = callback;
    return event;
}

Event!(Args) until(Args...)(Event!(Args) event, bool delegate() condition) {
    assert(event.killCondition is null);
    event.killCondition = condition;
    return event;
}

Event!(Args) once(Args...)(Event!(Args) event) {
    bool hasRun;
    event.killCondition = {
        if (hasRun) return true;
        hasRun = true;
        return false;
    };
    return event;
}

Event!(Args) once(Args...)(Event!(Args) event, void delegate() callback) 
    if (Args.length > 0)
{
    return event.then(callback).once;
}

Event!(Args) once(Args...)(Event!(Args) event, void delegate(Args) callback) {
    return event.then(callback).once;
}

alias VoidEvent = Event!();

class EventWatcher {
static:

    Array!IEvent _eventList;

    void update() {
        _eventList.linearRemove(_eventList[].find!(e => !e.isAlive));
    }

    const(Array!IEvent) eventList() {
        return _eventList;
    }

}

class EventException : Exception {
    mixin basicExceptionCtors;
}
