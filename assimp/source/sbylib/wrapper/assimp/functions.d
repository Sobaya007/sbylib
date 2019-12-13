module sbylib.wrapper.assimp.functions;

import bindbc.assimp.types;
import sbylib.math : vec2, vec3, vec4, quat, mat4;

string toRegularString(aiString str) {
    import std.conv : to;

    return str.data[0..str.length].to!string;
}

vec2 toSbylibVector(aiVector2D v) {
    return vec2(v.x, v.y);
}

vec3 toSbylibVector(aiVector3D v) {
    return vec3(v.x, v.y, v.z);
}

vec3 toSbylibVector(aiColor3D c) {
    return vec3(c.r, c.g, c.b);
}

vec4 toSbylibVector(aiColor4D c) {
    return vec4(c.r, c.g, c.b, c.a);
}

quat toSbylibQuaternion(aiQuaternion q) {
    return quat(q.x, q.y, q.z, q.w);
}

mat4 toSbylibMatrix(aiMatrix4x4 m) {
    return mat4(m.a1, m.a2, m.a3, m.a4,
            m.b1, m.b2, m.b3, m.b4,
            m.c1, m.c2, m.c3, m.c4,
            m.d1, m.d2, m.d3, m.d4);
}

auto toArray(alias postProcess, T)(uint len, T* data) {
    struct Result {
        size_t length;
        T* data;

        auto front() { return postProcess(data[0]); }

        void popFront() { data++; length--; }

        bool empty() { return length == 0; }

        Result save() { return Result(length, data); }

        auto back() { return postProcess(data[length-1]); }

        void popBack() { length--; }

        auto opIndex(size_t idx) { return postProcess(data[idx]); }
    }

    return Result(len, data);
}

E toEnum(E, O)(O o) {
    import std : asOriginalType, to;
    return o.asOriginalType.to!E;
}

string indent(string str) {
    import std.algorithm : map;
    import std.string : split, join;
    return str.split("\n").map!(line => "    " ~ line).join("\n");
}

string tree(string title, string[] components) {
    import std.algorithm : map;
    import std.range : enumerate;
    import std.string : join, split;
    import std.array : array;
    import std.format : format;
    import sbylib.wrapper.assimp.functions : indent;

    return (title
            ~ components.enumerate.map!(component =>
                component.value.split("\n").enumerate.map!(line =>
                    (component.index+1 == components.length ?
                     (line.index == 0 ? "L---" : "    ") : (line.index == 0 ? "|---" : "|    ")) ~ line.value
                    ).join("\n")).array).join("\n");
}

