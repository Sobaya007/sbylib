module sbylib.graphics.util.unit;

struct Pixel {
    int value;
    alias value this;

    this(float value) {
        this.value = cast(int)value;
    }

    this(int value) {
        this.value = value;
    }

    Pixel opUnary(string op)() const {
        return Pixel(mixin(op ~ "this.value"));
    }

    Pixel opBinary(string op)(Pixel pixel) const
        if (op == "+" || op == "-")
    {
        return Pixel(mixin("this.value"~op~"pixel.value"));
    }

    Pixel opBinary(string op)(int s) const
        if (op == "*" || op == "/")
    {
        return Pixel(mixin("this.value"~op~"s"));
    }

    Pixel opBinaryRight(string op)(int s) const
        if (op == "*" || op == "/")
    {
        return Pixel(mixin("s"~op~"this.value"));
    }

    Pixel opOpAssign(string op,T)(T value)
    {
        this.value = this.opBinary!(op)(value).value;
        return this;
    }

    string toString() {
        import std.format : format;
        return this.value.format!"%dpixel";
    }
}

Pixel pixel(float value) {
    return Pixel(value);
}
