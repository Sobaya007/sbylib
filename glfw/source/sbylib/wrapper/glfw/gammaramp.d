module sbylib.wrapper.glfw.gammaramp;

import derelict.glfw3.glfw3;

struct GammaRamp {

    private ushort[] red, green, blue; 

    invariant(red.length == green.length);
    invariant(green.length == blue.length);

    alias ramp this;

    package this(const(GLFWgammaramp)* ramp) {
        this.red = ramp.red[0..ramp.size].dup;
        this.green = ramp.green[0..ramp.size].dup;
        this.blue = ramp.blue[0..ramp.size].dup;
    }

    uint size() const {
        return cast(uint)this.red.length;
    }

    uint size(uint s) {
        this.red.length = s;
        this.green.length = s;
        this.blue.length = s;
        return s;
    }

    ushort getRed(uint i) const {
        return red[i];
    }

    void setRed(uint i, ushort v) {
        red[i] = v;
    }

    ushort getGreen(uint i) const {
        return green[i];
    }

    void setGreen(uint i, ushort v) {
        green[i] = v;
    }

    ushort getBlue(uint i) const {
        return blue[i];
    }

    void setBlue(uint i, ushort v) {
        blue[i] = v;
    }

    package GLFWgammaramp ramp() {
        GLFWgammaramp result;
        result.red = this.red.ptr;
        result.green = this.green.ptr;
        result.blue = this.blue.ptr;
        result.size = cast(uint)this.red.length;
        return result;
    }
}
