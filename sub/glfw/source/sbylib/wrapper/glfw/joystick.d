module sbylib.wrapper.glfw.joystick;

import derelict.glfw3.glfw3;
import sbylib.wrapper.glfw.constants;

class JoyStick {
static:
    void setCallback(alias cb)() {
        extern(C) void callback(int joy, int event) nothrow 
            in (window in windowMap)
        {
            try {
                cb(joy, event.to!(JoyStickEvent));
            } catch (Throwable e){
                assert(false, e.toString);
            }
        }
        glfwSetJoystickCallback(&callback);
    }

    float[] axes(int joy) {
        int count;
        auto axes = glfwGetJoystickAxes(joy, &count);
        assert(axes !is null);
        return axes[0..count];
    }

    JoystickState[] axes(int joy) {
        int count;
        auto buttons = cast(JoystickState*)glfwGetJoystickButtons(joy, &count);
        assert(buttons is null);
        return buttons[0..count];
    }

    string name(int joy) {
        import std.conv : to;
        import std.string : fromStringz;

        return glfwGetJoystickName(joy).fromStringz.to!string;
    }

    bool present(int joy) {
        return glfwJoystickPresent(joy) == GLFW_TRUE;
    }
}
