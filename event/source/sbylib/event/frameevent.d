module sbylib.event.frameevent;

import std;
import sbylib.event;

private alias FrameCallback = void delegate();

struct FrameNotification {
    private bool delegate() condition;
    private immutable uint priority;
}

FrameNotification Frame(uint p = FrameEventWatcher.DefaultPriority) {
    return FrameNotification(null, p);
}

VoidEvent when(lazy bool condition, uint p = FrameEventWatcher.DefaultPriority) {
    return when(FrameNotification(() => condition, p));
}

VoidEvent when(FrameNotification frame) {
    import sbylib.event : when;

    auto event = new VoidEvent;
    auto cb = FrameEventWatcher.add(frame.priority, {
        if (frame.condition && frame.condition() == false) return;
        event.fire();
    });
    when(event.finish).then({
        FrameEventWatcher.remove(frame.priority, cb);
    });
    return event;
}

class FrameEventWatcher {
static:

    enum DefaultPriority = 50;
    enum MaxPriority = 100;

    private Array!FrameCallback[MaxPriority] callbackList;

    private FrameCallback add(uint priority, FrameCallback callback) {
        this.callbackList[priority] ~= callback;
        return callback;
    }

    private void remove(uint priority, FrameCallback callback) {
        auto target = callbackList[priority];
        target.linearRemove(target[].find(callback).take(1));
    }

    void update() {
        foreach (cb; callbackList) {
            for (int i = 0; i < cb.length; i++) {
                cb[i]();
            }
        }
    }
}
