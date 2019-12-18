module sbylib.wrapper.glfw.glfw;

import derelict.glfw3.glfw3;
import erupted;
mixin DerelictGLFW3_VulkanBind;

public import sbylib.wrapper.glfw.constants : ErrorCode, KeyButton;

class GLFW {

static:
    private bool initialized;

    void initialize() {
        if (initialized) return;
        initialized = true;

        DerelictGLFW3.load();
        DerelictGLFW3_loadVulkan();
        const initResult = glfwInit();
        assert(initResult,"Failed to initialize GLFW");
    }

    void terminate() {
        glfwTerminate();
    }

    int[3] getVersion() {
        int[3] result;
        glfwGetVersion(&result[0], &result[1], &result[2]);
        return result;
    }

    string getVersionString() {
        import std.conv : to;
        import std.string : fromStringz;

        return glfwGetVersionString().fromStringz().to!string;
    }

    void setErrorCallback(alias cb)() {
        import std.conv : to;
        import std.string : fromStringz;

        extern(C) void callback(int error, const(char)* description) nothrow {
            try {
                cb(error.to!ErrorCode, description.fromStrinz.to!string);
            } catch (Throwable e) {
                assert(false, e.toString);
            }
        }

        glfwSetErrorCallback(callback);
    }

    void waitEvents() {
        glfwWaitEvents();
    }

    void waitEventsTimeout(double timeout) {
        glfwWaitEventsTimeout(timeout);
    }

    void pollEvents() {
        glfwPollEvents();
    }

    void postEmptyEvent() {
        glfwPostEmptyEvent();
    }

    double time() {
        return glfwGetTime();
    }

    size_t timeFrequency() {
        return glfwGetTimerFrequency();
    }

    size_t timerValue() {
        return glfwGetTimerValue();
    }

    double time(double time) {
        glfwSetTime(time);
        return time;
    }

    int swapInterval(int interval) {
        glfwSwapInterval(interval);
        return interval;
    }

    bool hasExtensionSupport(string extension) {
        import std.string : toStringz;

        return glfwExtensionSupported(extension.toStringz) == GLFW_TRUE;
    }

    string getKeyName(KeyButton key, int scancode) {
        import std.conv : to;
        import std.string : fromStringz;

        return glfwGetKeyName(key, scancode).fromStringz.to!string;
    }

    string[] getRequiredInstanceExtensions() {
        import std : map, fromStringz, array;

        uint count;
        auto result = glfwGetRequiredInstanceExtensions(&count);

        return result[0..count].map!(cs => fromStringz(cs).idup).array;
    }

    bool hasVulkanSupport() {
        return glfwVulkanSupported() == GLFW_TRUE;
    }
}
