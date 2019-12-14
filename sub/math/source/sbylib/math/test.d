module sbylib.math.test;

import sbylib.math;

unittest {
    vec2 a = vec2(1,2);

    // simple comparison
    assert(a == vec2(1,2));

    // vector calculation
    assert(a + vec2(2,3) == vec2(3,5));
    assert(a - vec2(9,8) == vec2(-8, -6));

    // scalar calculation
    assert(a + 1 == vec2(2,3));
    assert(a - 2 == vec2(-1,0));
    assert(a * 3 == vec2(3,6));
    assert(a / 4 ==  vec2(0.25, 0.5));

    // assignment
    a = vec2(4,-2);
    assert(a == vec2(4,-2));
    const(vec2) b = vec2(2,2);
    a = b;
    assert(a == vec2(2));

    // short expression
    a = vec2(3);
    assert(a == vec2(3,3));

    // operator assign
    a += vec2(2,1);
    assert(a == vec2(5,4));
    a -= vec2(1);
    assert(a == vec2(4,3));
    a *= 2;
    assert(a == vec2(8,6));
    a /= 2;
    assert(a == vec2(4,3));
}

unittest {
    vec2 a = vec2(1,2);
    
    // read partial vector
    assert(a.xy == vec2(1,2));
    assert(a.yx == vec2(2,1));
    assert(a.xyyx == vec4(1,2,2,1));

    vec3 c;

    // write partial vector
    c.yxz = vec3(3,2,1);
    assert(c == vec3(2,3,1));
    c.xy = a.yx;
    assert(c == vec3(2,1,1));
    c.zx = 3;
    assert(c == vec3(3,1,3));
    c.xy = c.yx;
    assert(c == vec3(1,3,3));
    //c.xy += vec2(1); // cannot modify partial vector
    c.y--; // single member can be modified
    assert(c == vec3(1,2,3));
}

unittest {
    static assert(__traits(hasMember, vec3, "undefinedMember") == false);
    static assert(__traits(hasMember, vec3, "x") == true);
    static assert(__traits(hasMember, vec3, "yxz") == true);
}

unittest {
    auto m1 = mat3(
            1,4,7,
            2,5,8,
            3,6,9);
    auto m2 = mat3(vec3(1,2,3),vec3(4,5,6),vec3(7,8,9));

    assert(m1 == m2);

    auto m3 = mat3(
            1,0,1,
            0,1,1,
            0,0,1);
    auto m4 = mat3(
            1,2,3,
            4,5,6,
            1,1,1);

    auto m5 = mat3(
            2,2,4,
            4,6,7,
            1,1,2);
    auto m6 = mat3(
            2,3,4,
            5,6,7,
            1,1,1);

    assert(m3 + m4 == m5);
    assert(m3 * m4 == m6);

    auto p = vec4(0,1,2,1);
    auto m = mat4(
            1,0,0,100,
            0,1,0,200,
            0,0,1,300,
            0,0,0,1);
    assert(m * p == vec4(100,201,302,1));
    auto t = mat4.translate(vec3(100,200,300));
    assert(m == t);
}

unittest {
    struct S {
        auto get() { return mat2(0); }
        alias get this;
    }

    S s;
    vec2 a = s * vec2(0);

}

unittest {
    vec4 v;
    assert(!is(typeof({ v = mat4(0); })));
}
