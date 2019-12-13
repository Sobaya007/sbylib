module sbylib.graphics.util.color;

import sbylib.math.vector;

struct Color {
    private vec4 v;
    alias toVector this;

    this(Args...)(Args args) {
        this.v = vec4(args);
    }

    static {
        Color rgb(Args...)(Args args) {
            return Color(vec3(args), 1);
        }
    }

    enum Black = Color.rgb(0);
    enum Red = Color.rgb(1,0,0);
    enum Green = Color.rgb(0,1,0);
    enum Blue = Color.rgb(0,0,1);
    enum White = Color.rgb(1);
    enum Gray = Color.rgb(0.5);

    vec4 toVector() {
        return v;
    }
}
