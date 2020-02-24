module sbylib.graphics.util.own;

enum own;

mixin template ImplReleaseOwn() {
    ~this() {
        foreach (name; __traits(derivedMembers, typeof(this))) {
            static if (name != "this" && name != "__dtor") {
                alias mem = __traits(getMember, typeof(this), name);
                static if (is(typeof(hasUDA!(mem, own))) && hasUDA!(mem, own) && is(typeof(mem))) {
                    static if (isArray!(typeof(mem))) {
                        foreach (m; mem) {
                            m.destroy();
                        }
                    } else {
                        mem.destroy();
                    }
                }
            }
        }
    }
}
