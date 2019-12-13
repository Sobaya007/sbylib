module sbylib.wrapper.glfw.screen;

import derelict.glfw3.glfw3;

public import sbylib.wrapper.glfw.gammaramp : GammaRamp;

alias VideoMode = GLFWvidmode;

struct Screen {

    package GLFWmonitor* screen;

    invariant (screen !is null);

    package this(GLFWmonitor* screen) {
        this.screen = screen;
    }

    static Screen[] getAllScreens() {
        int count;
        auto screens = glfwGetMonitors(&count);
        auto result = new Screen[count];
        foreach (i; 0..count) {
            result[i] = Screen(screens[i]);
        }
        return result;
    }

    static Screen getPrimaryScreen() {
        return Screen(glfwGetPrimaryMonitor());
    }

    auto getCurrentGammaRamp() {
        return GammaRamp(glfwGetGammaRamp(this.screen));
    }

    string name() {
        import std.conv : to;
        return glfwGetMonitorName(this.screen).to!string();
    }

    int[2] physicalSize() {
        int[2] result;
        glfwGetMonitorPhysicalSize(this.screen, &result[0], &result[1]);
        return result;
    }

    auto pos() {
        struct Point {int x, y;}
        Point result;
        glfwGetMonitorPos(this.screen, &result.x, &result.y);
        return result;
    }

    const(VideoMode) currentVideoMode() {
        const result = glfwGetVideoMode(this.screen);
        assert(result !is null);
        return *result;
    }

    const(VideoMode)[] supportedVideoModes() {
        int count;
        auto videoModes = glfwGetVideoModes(this.screen, &count);
        const(VideoMode)[] result;
        foreach (i; 0..count) {
            result ~= videoModes[i];
        }
        return result;
    }

    float gamma(float gamma) {
        glfwSetGamma(this.screen, gamma);
        return gamma;
    }

    GammaRamp gammaRamp(GammaRamp ramp) {
        const r = ramp.ramp;
        glfwSetGammaRamp(this.screen, &r);
        return ramp;
    }

    //void setMonitorCallback(void function(Monitor, MonitorCallbackState) cb) {
    //}
}
