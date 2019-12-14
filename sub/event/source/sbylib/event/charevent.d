module sbylib.event.charevent;

import std;
import sbylib.wrapper.glfw;
import sbylib.event;

private alias CharCallback = void delegate(Window, uint);

private struct CharNotification {}
private struct Char_t {}

Char_t Char() {
    return Char_t();
}

CharNotification typed(Char_t) {
    return CharNotification();
}

Event!(uint) when(CharNotification condition) {
    import sbylib.event : when;

    auto event = new Event!(uint);
    auto cb = CharEventWatcher.add((Window, uint codepoint) {
        event.fire(codepoint);
    });
    when(event.finish).then({
        CharEventWatcher.remove(cb);
    });
    return event;
}

private class CharEventWatcher {
static:
    private Array!CharCallback callbackList;
    private bool initialized = false;

    private void use() {
        if (initialized) return;
        initialized = true;
        Window.getCurrentWindow().setCharCallback!(charCallback, (Exception e) { assert(false, e.toString()); });
    }

    private CharCallback add(CharCallback callback) {
        use();
        callbackList ~= callback;
        return callback;
    }

    private void remove(CharCallback callback) {
        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    void charCallback(Window window, uint codepoint) {
        foreach (cb; callbackList) {
            cb(window, codepoint);
        }
    }
}
