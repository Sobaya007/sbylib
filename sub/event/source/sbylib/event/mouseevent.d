module sbylib.event.mouseevent;

import std;
import sbylib.math;
import sbylib.wrapper.glfw;
import sbylib.event;

private alias MouseEnterCallback = void delegate(bool);
private alias MousePosCallback = void delegate(double[2]);
private alias MouseScrollCallback = void delegate(double[2]);
private alias MouseButtonCallback = void delegate(MouseButton, ButtonState, BitFlags!ModKeyButton);

private struct MouseEnterNotification { Window window; }
private struct MouseLeaveNotification { Window window; }
private struct MousePosNotification { Window window; }
private struct MouseScrollNotification { Window window; }
private struct MouseButtonNotification {
    Window window;
    MouseButton button;
    ButtonState state;
}
private struct MousePos {}

private struct Mouse {
    MouseEnterNotification entered() { return MouseEnterNotification(); }
    MouseLeaveNotification left() { return MouseLeaveNotification(); }
    MousePosNotification moved() { return MousePosNotification(); }
    MouseScrollNotification scrolled() { return MouseScrollNotification(); }
    MousePos pos() { return MousePos(); }
}

static foreach (T; AliasSeq!(MouseEnterNotification, MouseLeaveNotification, MousePosNotification, MouseScrollNotification)) {
    T on(T t, Window window) {
        t.window = window;
        return t;
    }
}

vec2 on(MousePos, Window window) {
    return vec2(window.mousePos());
}

Mouse mouse() { return Mouse(); }

MouseButtonNotification pressed(MouseButton mouse) {
    return MouseButtonNotification(null, mouse, ButtonState.Press);
}

MouseButtonNotification released(MouseButton mouse) {
    return MouseButtonNotification(null, mouse, ButtonState.Release);
}

struct MousePressing {
    MouseButton button;
}

MousePressing pressing(MouseButton button) {
    return MousePressing(button);
}

MouseButtonNotification on(MouseButtonNotification notification, Window window) {
    notification.window = window;
    return notification;
}

auto on(MousePressing m, Window window) {
    return FrameNotification(() => window.getMouse(m.button) == ButtonState.Press);
}

auto when(MouseEnterNotification notification) {
    import sbylib.event : when;

    auto event = new Event!();
    auto cb = MouseEventWatcher.add(notification.window, (bool entered) {
        if (!entered) return;
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(notification.window, cb);
    });
    return event;
}

auto when(MouseLeaveNotification notification) {
    import sbylib.event : when;

    auto event = new Event!();
    auto cb = MouseEventWatcher.add(notification.window, (bool entered) {
        if (entered) return;
        event.fire();
    });
    when(event.finish).then({
        MouseEventWatcher.remove(notification.window, cb);
    });
    return event;
}

auto when(MousePosNotification notification) {
    import sbylib.event : when;

    auto event = new Event!(vec2);
    auto cb = MouseEventWatcher.add(notification.window, (double[2] pos) {
        event.fire(vec2(pos));
    });
    when(event.finish).then({
        MouseEventWatcher.remove(notification.window, cb);
    });
    return event;
}

auto when(MouseScrollNotification notification) {
    import sbylib.event : when;

    auto event = new Event!(vec2);
    auto cb = MouseEventWatcher.addScroll(notification.window, (double[2] scroll) {
        event.fire(vec2(scroll));
    });
    when(event.finish).then({
        MouseEventWatcher.removeScroll(notification.window, cb);
    });
    return event;
}

auto when(MouseButtonNotification notification) {
    import sbylib.event : when;

    auto event = new Event!(BitFlags!ModKeyButton);
    auto cb = MouseEventWatcher.add(notification.window,
            (MouseButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        if (button != notification.button) return;
        if (state != notification.state) return;
        event.fire(mods);
    });
    when(event.finish).then({
        MouseEventWatcher.remove(notification.window, cb);
    });
    return event;
}

private class MouseEventWatcher {
static:
    private Array!MouseEnterCallback[Window] enterCallbackList;
    private Array!MousePosCallback[Window] posCallbackList;
    private Array!MouseScrollCallback[Window] scrollCallbackList;
    private Array!MouseButtonCallback[Window] buttonCallbackList;
    private Array!Window registered;

    private void use(Window window) {
        foreach (r; registered) {
            if (r == window) return;
        }
        registered ~= window;

        alias errorHandler = (Exception e) { assert(false, e.toString()); };
        window.setMouseEnterCallback!(enterCallback, errorHandler);
        window.setMousePosCallback!(posCallback, errorHandler);
        window.setScrollCallback!(scrollCallback, errorHandler);
        window.setMouseButtonCallback!(buttonCallback, errorHandler);

        enterCallbackList[window] = Array!MouseEnterCallback();
        posCallbackList[window] = Array!MousePosCallback();
        scrollCallbackList[window] = Array!MouseScrollCallback();
        buttonCallbackList[window] = Array!MouseButtonCallback();
    }

    private MouseEnterCallback add(Window window, MouseEnterCallback callback) {
        use(window);
        enterCallbackList[window] ~= callback;
        return callback;
    }

    private void remove(Window window, MouseEnterCallback callback) {
        auto target = enterCallbackList[window];
        target.linearRemove(target[].find(callback).take(1));
    }

    void enterCallback(Window window, bool enter) {
        foreach (cb; enterCallbackList[window]) {
            cb(enter);
        }
    }

    private MousePosCallback add(Window window, MousePosCallback callback) {
        use(window);
        posCallbackList[window] ~= callback;
        return callback;
    }

    private void remove(Window window, MousePosCallback callback) {
        auto target = posCallbackList[window];
        target.linearRemove(target[].find(callback).take(1));
    }

    void posCallback(Window window, double[2] pos) {
        foreach (cb; posCallbackList[window]) {
            cb(pos);
        }
    }

    private MouseScrollCallback addScroll(Window window, MouseScrollCallback callback) {
        use(window);
        scrollCallbackList[window] ~= callback;
        return callback;
    }

    private void removeScroll(Window window, MouseScrollCallback callback) {
        auto target = scrollCallbackList[window];
        target.linearRemove(target[].find(callback).take(1));
    }

    void scrollCallback(Window window, double[2] scroll) {
        foreach (cb; scrollCallbackList[window]) {
            cb(scroll);
        }
    }

    private MouseButtonCallback add(Window window, MouseButtonCallback callback) {
        use(window);
        buttonCallbackList[window] ~= callback;
        return callback;
    }

    private void remove(Window window, MouseButtonCallback callback) {
        auto target = buttonCallbackList[window];
        target.linearRemove(target[].find(callback).take(1));
    }

    void buttonCallback(Window window, MouseButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (cb; buttonCallbackList[window]) {
            cb(button, state, mods);
        }
    }
}
