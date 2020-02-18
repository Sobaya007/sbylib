module sbylib.wrapper.glfw.window;

import derelict.glfw3.glfw3;
import sbylib.wrapper.glfw.constants;
import erupted;
import sbylib.wrapper.glfw.glfw : glfwCreateWindowSurface;

private Window[GLFWwindow*] windowMap;

public import sbylib.wrapper.glfw.cursor : Cursor;
public import sbylib.wrapper.glfw.screen : Screen;
public import sbylib.wrapper.glfw.image : Image;
public import std.typecons : BitFlags;

/**
GLFW based window class
*/
class Window {

    private GLFWwindow* window;
    private string mTitle; // There is no API like glfwGetWindowTitle

    package this(int width, int height, string title) {
        this(width, height, title, cast(GLFWmonitor*)null, null);
    }

    package this(int width, int height, string title, Window share) {
        this(width, height, title, null, share.window);
    }

    package this(int width, int height, string title, Screen screen) {
        this(width, height, title, screen, null);
    }

    package this(int width, int height, string title, Screen screen, Window share) {
        this(width, height, title, screen.screen, share.window);
    }

    private this(int width, int height, string title, GLFWmonitor* screen, GLFWwindow* share) {
        import std.string : toStringz;

        this.mTitle = title;

        this.window = glfwCreateWindow(width, height, title.toStringz, screen, share);

        assert(this.window !is null, "Failed to create window");

        windowMap[this.window] = this;
    }

    void destroy() {
        glfwDestroyWindow(window);
        windowMap.remove(window);
    }

    void focus() {
        glfwFocusWindow(window);
    }

    bool focused() {
        return getAttribute(Attribute.Focused) == GLFW_TRUE;
    }

    void setFocusCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int focused) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), focused == GLFW_TRUE);
        }
        glfwSetWindowFocusCallback(window, &callback);
    } 

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setFocusCallback!((w, f) {}, (Exception e) {});

            window.focus();
            assert(window.focused);
        }
    }

    void minimize() {
        glfwIconifyWindow(window);
    }

    bool minimized() {
        return getAttribute(Attribute.Iconified) == GLFW_TRUE;
    }

    void setIconifyCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int iconified) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), iconified == GLFW_TRUE);
        }
        glfwSetWindowIconifyCallback(window, &callback);
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setIconifyCallback!((w, i) {} , (Exception e) {});

            window.minimize();
            Thread.sleep(1.seconds);
            assert(window.minimized);
        }
    }

    void maximize() {
        glfwMaximizeWindow(window);
    }

    bool maximized() {
        return getAttribute(Attribute.Maximized) == GLFW_TRUE;
    }

    int[2] pos(int[2] p...) {
        glfwSetWindowPos(window, p[0], p[1]);
        return this.pos;
    }

    int[2] pos() {
        int[2] result;
        glfwGetWindowPos(window, &result[0], &result[1]);
        return result;
    }

    int x(int x) {
        this.pos = [x, this.y];
        return x;
    }

    int y(int y) {
        this.pos = [this.x, y];
        return y;
    }

    int x() {
        return pos[0];
    }

    int y() {
        return pos[1];
    }

    void setPosCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int x, int y) nothrow 
            in (window in windowMap)
        {
            int[2] pos = [x,y];
            call!(cb, catcher)(getWindow(window), pos);
        }
        glfwSetWindowPosCallback(window, &callback);
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setPosCallback!((w, p) {}, (Exception e) {});

            window.pos = [100, 100];
            Thread.sleep(1.seconds);
            assert(window.pos == [100, 100]);

            window.x = 200;
            Thread.sleep(1.seconds);
            assert(window.x == 200);

            window.y = 150;
            Thread.sleep(1.seconds);
            assert(window.y == 150);
        }
    }

    int[2] size(int[2] size...) {
        glfwSetWindowSize(window, size[0], size[1]);
        return this.size;
    }

    int width(int w) {
        this.size = [w, this.height];
        return w;
    }

    int height(int h) {
        this.size = [this.width, h];
        return h;
    }

    int[2] size() {
        int width, height;
        glfwGetWindowSize(window, &width, &height);
        return [width, height];
    }

    int width() {
        return size[0];
    }

    int height() {
        return size[1];
    }

    void setSizeCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int width, int height) nothrow 
            in (window in windowMap)
        {
            int[2] size = [width, height];
            call!(cb, catcher)(getWindow(window), size);
        }
        glfwSetWindowSizeCallback(window, &callback);
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setSizeCallback!((w, s) {}, (Exception e) {});

            window.size = [100, 100];
            Thread.sleep(1.seconds);
            assert(window.size == [100, 100]);

            window.width = 200;
            Thread.sleep(1.seconds);
            assert(window.width == 200);

            window.height = 150;
            Thread.sleep(1.seconds);
            assert(window.height == 150);
        }
    }

    void hide() {
        glfwHideWindow(window);
    }

    void restore() {
        glfwRestoreWindow(window);
    }

    bool visible(bool v) {
        if (v) restore();
        else hide();
        return v;
    }

    bool visible() {
        return getAttribute(Attribute.Visible) == GLFW_TRUE;
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.visible = true;
            Thread.sleep(1.seconds);
            assert(window.visible == true);

            window.visible = false;
            Thread.sleep(1.seconds);
            assert(window.visible == false);
        }
    }

    /**
    Returns true if this window should close.

    Returns: true if this window should close
    */
    bool shouldClose(bool shouldClose) {
        glfwSetWindowShouldClose(window, shouldClose ? GLFW_TRUE : GLFW_FALSE);
        return shouldClose;
    }

    bool shouldClose() {
        return glfwWindowShouldClose(window) == GLFW_TRUE;
    }

    void setCloseCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window));
        }
        glfwSetWindowCloseCallback(window, &callback);
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setCloseCallback!((w) {}, (Exception e) {});

            window.shouldClose = false;
            assert(window.shouldClose == false);

            window.shouldClose = true;
            assert(window.shouldClose == true);
        }
    }

    string clipboard(string str) {
        import std.string : toStringz;

        glfwSetClipboardString(window, str.toStringz);
        return str;
    }

    string clipboard() {
        import std.conv : to;
        import std.string : fromStringz;

        return glfwGetClipboardString(window).fromStringz.to!string;
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.clipboard = "foo";
            assert(window.clipboard == "foo");
        }
    }

    double[2] mousePos(double[2] mousePos) {
        glfwSetCursorPos(window, mousePos[0], mousePos[1]);
        return mousePos;
    }

    double[2] mousePos() {
        double[2] result;
        glfwGetCursorPos(window, &result[0], &result[1]);
        return result;
    }

    void setMousePosCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, double x, double y) nothrow 
            in (window in windowMap)
        {
            double[2] pos = [x,y];
            call!(cb, catcher)(getWindow(window), pos);
        }
        glfwSetCursorPosCallback(window, &callback);
    }

    unittest {
        import sbylib.wrapper.glfw.windowbuilder : WindowBuilder;
        import core.thread : Thread, seconds;
        with (WindowBuilder()) {
            auto window = buildWindow();
            scope (exit) window.destroy();

            window.setMousePosCallback!((w, p) {}, (Exception e) {});

            window.mousePos = [100, 120];
            assert(window.mousePos == [100, 120]);
        }
    }

    int[2] framebufferSize() {
        int[2] result;
        glfwGetFramebufferSize(window, &result[0], &result[1]);
        return result;
    }

    void setFramebufferSizeCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int width, int height) nothrow 
            in (window in windowMap)
        {
            int[2] size = [width, height];
            call!(cb, catcher)(getWindow(window), size);
        }
        glfwSetFramebufferSizeCallback(window, &callback);
    }

    bool resizable() {
        return getAttribute(Attribute.Resizable) == GLFW_TRUE;
    }

    bool decorated() {
        return getAttribute(Attribute.Decorated) == GLFW_TRUE;
    }

    bool floating() {
        return getAttribute(Attribute.Floating) == GLFW_TRUE;
    }

    ClientAPI clientAPI() {
        import std.conv : to;
        return getAttribute(Attribute.ClientAPI).to!(ClientAPI);
    }

    int contextVersionMajor() {
        return getAttribute(Attribute.ContextVersionMajor);
    }

    int contextVersionMinor() {
        return getAttribute(Attribute.ContextVersionMinor);
    }

    int contextRevision() {
        return getAttribute(Attribute.ContextRevision);
    }

    bool forwardCompatible() {
        return getAttribute(Attribute.OpenGLForwardCompat) == GLFW_TRUE;
    }

    bool hasDebugContext() {
        return getAttribute(Attribute.OpenGLDebugContext) == GLFW_TRUE;
    }

    OpenGLProfile profile() {
        import std.conv : to;
        return getAttribute(Attribute.OpenGLProfile).to!(OpenGLProfile);
    }

    ContextRobustness contextRobustness() {
        import std.conv : to;
        return getAttribute(Attribute.ContextRobustness).to!(ContextRobustness);
    }

    int[4] frameSize() {
        int[4] result;
        glfwGetWindowFrameSize(window, &result[0], &result[1], &result[2], &result[3]);
        return result;
    }

    Screen screen() {
        import std.stdio : writeln;
        auto screen = glfwGetWindowMonitor(window);
        assert(screen !is null);
        return Screen(screen);
    }

    void* userPointer() {
        return glfwGetWindowUserPointer(window);
    }

    void aspectRatio(int[2] ratio) {
        glfwSetWindowAspectRatio(window, ratio[0], ratio[1]);
    }

    void setIcon(Image[] image) {
        import std.algorithm : map;
        import std.array : array;

        const imageList = image.map!(i => *i.image).array;
        glfwSetWindowIcon(window, cast(int)image.length, imageList.ptr);
    }

    void setFullScreenMode(Screen screen, int[2] size, int refreshRate = DontCare) {
        glfwSetWindowMonitor(window, screen.screen, 0, 0, size[0], size[1], refreshRate);
    }

    void setWindowMode(int[2] pos, int[2] size) {
        glfwSetWindowMonitor(window, null, pos[0], pos[1], size[0], size[1], 0);
    }

    void setRefreshCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window));
        }
        glfwSetWindowRefreshCallback(window, &callback);
    }

    void setSizeLimit(int[2] min, int[2] max) 
    in (min[0] <= max[0] || min[0] == DontCare || max[0] == DontCare)
    in (min[1] <= max[1] || min[1] == DontCare || max[1] == DontCare)
    {
        glfwSetWindowSizeLimits(window, min[0], min[1], max[0], max[1]);
    }

    string title(string title) {
        import std.string : toStringz;

        this.mTitle = title;
        window.glfwSetWindowTitle(title.toStringz);
        return this.title;
    }

    string title() const {
        return mTitle;
    }

    void* userPointer(void* ptr) {
        glfwSetWindowUserPointer(window, ptr);
        return ptr;
    }

    void show() {
        glfwShowWindow(window);
    }

    void swapBuffers() {
        window.glfwSwapBuffers();
    }

    CursorMode cursorMode() {
        import std.conv : to;

        return glfwGetInputMode(window, InputMode.Cursor).to!CursorMode;
    }

    bool stickyKey() {
        return glfwGetInputMode(window, InputMode.StickyKeys) == GLFW_TRUE;
    }

    bool stickyMouseButton() {
        return glfwGetInputMode(window, InputMode.StickyMouseButtons) == GLFW_TRUE;
    }

    ButtonState getKey(KeyButton button) {
        import std.conv : to;

        return glfwGetKey(window, button).to!ButtonState;
    }

    ButtonState getMouse(MouseButton button) {
        import std.conv : to;

        return glfwGetMouseButton(window, button).to!ButtonState;
    }

    void setCharCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, uint codepoint) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), codepoint);
        }
        glfwSetCharCallback(window, &callback);
    }

    void setCharModsCallback(alias cb, alias catcher)() {
        import std.bitmanip : bitsSet;
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;

        extern(C) void callback(GLFWwindow *window, uint codepoint, int mods) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), codepoint, mods.bitsSet.map!(to!ModKeyButton).array);
        }
        glfwSetCharModsCallback(window, &callback);
    }

    Cursor cursor(Cursor cursor) {
        glfwSetCursor(window, cursor.cursor);
        return cursor;
    }

    void setMouseEnterCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int enter) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), enter == GLFW_TRUE);
        }
        glfwSetCursorEnterCallback(window, &callback);
    }

    void setDropCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, int count, const char** paths) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), paths[0..count].to!(string[]));
        }
        glfwSetDropCallback(window, &callback);
    }

    CursorMode cursorMode(CursorMode mode) {
        glfwSetInputMode(window, InputMode.Cursor, mode);
        return mode;
    }

    bool stickyKey(bool enabled) {
        glfwSetInputMode(window, InputMode.StickyKeys, enabled ? GLFW_TRUE : GLFW_FALSE);
        return enabled;
    }

    bool stickyMouseButton(bool enabled) {
        glfwSetInputMode(window, InputMode.StickyMouseButtons, enabled ? GLFW_TRUE : GLFW_FALSE);
        return enabled;
    }

    void setKeyCallback(alias cb, alias catcher)() {
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;
        import std.typecons : BitFlags;

        extern(C) void callback(GLFWwindow *window, int key, int scancode, int action, int mods) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), key.to!KeyButton, scancode,
                    action.to!ButtonState, decompose!(ModKeyButton)(mods));
        }
        glfwSetKeyCallback(window, &callback);
    }

    void setMouseButtonCallback(alias cb, alias catcher)() {
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;
        import std.bitmanip : bitsSet;

        extern(C) void callback(GLFWwindow *window, int button, int action, int mods) nothrow 
            in (window in windowMap)
        {
            call!(cb, catcher)(getWindow(window), button.to!MouseButton,
                    action.to!ButtonState, decompose!(ModKeyButton)(mods));
        }
        glfwSetMouseButtonCallback(window, &callback);
    }

    void setScrollCallback(alias cb, alias catcher)() {
        extern(C) void callback(GLFWwindow *window, double xoffset, double yoffset) nothrow 
            in (window in windowMap)
        {
            double[2] offset = [xoffset, yoffset];
            call!(cb, catcher)(getWindow(window), offset);
        }
        glfwSetScrollCallback(window, &callback);
    }

    static Window getCurrentWindow() {
        auto window = glfwGetCurrentContext();
        return windowMap[window];
    }

    void makeCurrent() {
        glfwMakeContextCurrent(window);
    }

    VkResult createWindowSurface(VkInstance instance, const VkAllocationCallbacks* allocator, VkSurfaceKHR* surface) {
        return glfwCreateWindowSurface(instance, window, allocator, surface);
    }

    private int getAttribute(Attribute attrib) {
        return glfwGetWindowAttrib(this.window, attrib);
    }

    private static void call(alias callback, alias catcher, Args...)(lazy Args args) {
        try {
            callback(args);
        } catch (Exception e) {
            catcher(e);
        }
    }

    private static decompose(T)(int flags) {
        import std.traits : EnumMembers;

        BitFlags!T result;
        static foreach(mem; EnumMembers!T) {
            if (flags & mem)
                result |= mem;
        }

        return result;
    }

    private static getWindow(GLFWwindow* window) 
    out(r; r !is null)
    {
        return windowMap[window];
    }
}
