module sbylib.event.keyevent;

import std;
import sbylib.wrapper.glfw;
import sbylib.event;

private alias KeyCallback = void delegate(Window, KeyButton, int, ButtonState, BitFlags!ModKeyButton);

private struct KeyButtonWithSpecial {
    Nullable!KeyButton button;
    bool[ModKeyButton] mod;

    this(KeyButton button) {
        this.button = button;
    }

    this(ModKeyButton button) {
        this.mod[button] = true;
    }

    this(KeyButton button, bool[ModKeyButton] mod) {
        this.button = button;
        this.mod = mod;
    }

    this(Nullable!KeyButton button, bool[ModKeyButton] mod) {
        this.button = button;
        this.mod = mod;
    }

    KeyButtonWithSpecial opBinary(string op)(KeyButton key) 
        if (op == "+")
    {
        return KeyButtonWithSpecial(key, this.mod);
    }

    KeyButtonWithSpecial opBinary(string op)(KeyButtonWithSpecial key) 
        if (op == "+")
        in (this.button.isNull || key.button.isNull)
    {
        auto mod = this.mod;
        foreach (modKey, value; key.mod) mod[modKey] = true;

        auto button = this.button;
        if (!key.button.isNull) button = nullable(key.button);
        return KeyButtonWithSpecial(button, mod);
    }
}

KeyButtonWithSpecial Ctrl() {
    return KeyButtonWithSpecial(ModKeyButton.Control);
}

KeyButtonWithSpecial Shift() {
    return KeyButtonWithSpecial(ModKeyButton.Shift);
}

KeyButtonWithSpecial Alt() {
    return KeyButtonWithSpecial(ModKeyButton.Alt);
}

KeyButtonWithSpecial Super() {
    return KeyButtonWithSpecial(ModKeyButton.Super);
}

private struct KeyNotification {
    KeyButtonWithSpecial button;
    ButtonState state; 
    Window window;

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        if (button != this.button.button.get()) return false;
        if (state != this.state) return false;
        foreach (key, value; this.button.mod) {
            if (value && !(mods & key)) return false;
        }
        return true;
    }
}

private struct OrKeyNotification {
    KeyNotification[] keys;
    Window window;

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (key; keys) {
            if (key.judge(button, state, mods)) return true;
        }
        return false;
    }
}

OrKeyNotification or(KeyNotification[] keys...) {
    typeof(return) result;
    foreach (key; keys)
        result.keys ~= key;
    return result;
}

private struct AndKeyNotification {
    KeyNotification[] keys;
    Window window;

    bool judge(KeyButton button, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (key; keys) {
            if (!key.judge(button, state, mods)) return false;
        }
        return true;
    }
}

AndKeyNotification and(KeyNotification[] keys...) {
    typeof(return) result;
    foreach (key; keys)
        result.keys ~= key;
    return result;
}

KeyNotification pressed(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Press);
}

KeyNotification pressed(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Press);
}

KeyNotification repeated(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Repeat);
}

KeyNotification repeated(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Repeat);
}

KeyNotification released(KeyButton key) {
    return KeyNotification(KeyButtonWithSpecial(key), ButtonState.Release);
}

KeyNotification released(KeyButtonWithSpecial button) {
    return KeyNotification(button, ButtonState.Release);
}

struct KeyPressing {
    KeyButton key;
}

auto pressing(KeyButton key, uint priority = FrameEventWatcher.DefaultPriority) {
    return KeyPressing(key);
}

auto on(KeyPressing k, Window window, uint priority = FrameEventWatcher.DefaultPriority) {
    return FrameNotification(() => k.key.isPressed.on(window), priority);
}

struct KeyReleasing {
    KeyButton key;
}

auto releasing(KeyButton key, uint priority = FrameEventWatcher.DefaultPriority) {
    return KeyReleasing(key);
}

auto on(KeyReleasing k, Window window, uint priority = FrameEventWatcher.DefaultPriority) {
    return FrameNotification(() => k.key.isReleased.on(window), priority);
}

struct KeyPressed {
    KeyButton key;
}

KeyPressed isPressed(KeyButton key) {
    return KeyPressed(key);
}

auto on(KeyPressed k, Window window) {
    return window.getKey(k.key) == ButtonState.Press;
}

struct KeyReleased {
    KeyButton key;
}

KeyReleased isReleased(KeyButton key) {
    return KeyReleased(key);
}

auto on(KeyReleased k, Window window) {
    return window.getKey(k.key) == ButtonState.Release;
}

static foreach (NotificationType; AliasSeq!(KeyNotification, OrKeyNotification, AndKeyNotification)) {
    VoidEvent when(NotificationType notification) {
        import sbylib.event : when;

        auto event = new VoidEvent;
        auto cb = KeyEventWatcher(notification.window).add((Window, KeyButton button, int, ButtonState state, BitFlags!ModKeyButton mods) {
            if (notification.judge(button, state, mods)) event.fire();
        });
        when(event.finish).then({ KeyEventWatcher(notification.window).remove(cb); });
        return event;
    }

    NotificationType on(NotificationType notification, Window window) {
        notification.window = window;
        return notification;
    }
}

private struct AnyKey {}

AnyKey Key() {
    return AnyKey();
}

private struct AnyKeyNotification {
    ButtonState state; 
    Window window;
}

AnyKeyNotification pressed(AnyKey key) {
    return AnyKeyNotification(ButtonState.Press);
}

AnyKeyNotification repeated(AnyKey key) {
    return AnyKeyNotification(ButtonState.Repeat);
}

AnyKeyNotification released(AnyKey key) {
    return AnyKeyNotification(ButtonState.Release);
}

auto when(AnyKeyNotification notification) {
    import sbylib.event : when;

    auto event = new Event!KeyButton;
    auto cb = KeyEventWatcher(notification.window).add((Window, KeyButton button, int, ButtonState state, BitFlags!ModKeyButton mods) {
        if (notification.state == state) event.fire(button);
    });
    when(event.finish).then({ KeyEventWatcher(notification.window).remove(cb); });
    return event;
}

AnyKeyNotification on(AnyKeyNotification notification, Window window) {
    notification.window = window;
    return notification;
}

private class KeyEventWatcher {
    private static KeyEventWatcher[Window] instances;
    private Array!KeyCallback callbackList;
    private bool initialized;
    private Window window;

    static KeyEventWatcher opCall(Window window) 
        in (window !is null, "Key Event's window is not specified.")
    {
        if (auto r = window in instances) 
            return *r;

        return instances[window] = new KeyEventWatcher(window);
    }

    this(Window window) {
        this.window = window;
    }

    private void use() {
        if (initialized) return;
        initialized = true;
        this.window.setKeyCallback!(
            keyCallback,
            (Exception e) {
                if (cast(ConvException)e) return;
                assert(false, e.toString());
            });
    }

    private KeyCallback add(KeyCallback callback) {
        use();
        callbackList ~= callback;
        return callback;
    }

    private void remove(KeyCallback callback) {
        callbackList.linearRemove(callbackList[].find(callback).take(1));
    }

    static void keyCallback(Window window, KeyButton button, int scanCode, ButtonState state, BitFlags!ModKeyButton mods) {
        foreach (cb; instances[window].callbackList) {
            cb(window, button, scanCode, state, mods);
        }
    }
}

unittest {
    with (WindowBuilder()) {
        auto window = buildWindow();
        window.
    }
}
