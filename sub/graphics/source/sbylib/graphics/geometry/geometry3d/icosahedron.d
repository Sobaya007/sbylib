module sbylib.graphics.geometry.geometry3d.icosahedron;

import std : map, array, sqrt;
import sbylib.math;
import sbylib.wrapper.vulkan;
import sbylib.graphics.geometry.geometry;

auto buildGeometry(uint level = 0) {
    struct Vertex {
        vec3 position;
        vec3 normal;
        vec2 uv;
    }

    with (Geometry!(Vertex, uint)()) {
        primitive = PrimitiveTopology.TriangleList;
        auto vertexIndex = createVertexIndex(level);

        foreach (v; vertexIndex.vertex) {
            Vertex vertex = {
                position: v,
                normal: v
            };
            add(vertex);
        }
        foreach (index; vertexIndex.index) {
            select(index);
        }

        return build();
    }
}

private auto createVertexIndex(uint level) {
    struct Result {
        vec3[] vertex;
        uint[] index;
    }

    if (level == 0) return Result(OriginalVertex, OriginalIndex);

    Result result = createVertexIndex(level-1);

    with (result) {
        uint idx = cast(uint)vertex.length;

        uint[uint] cache;
        uint getMiddleIndex(uint a, uint b) {
            const key = a < b ? (a * 114_514 + b) : (b * 114_514 + a);
            if (auto r = key in cache) return *r;
            auto newVertex = normalize(vertex[a] + vertex[b]);
            vertex ~= newVertex;
            cache[key] = idx;
            return idx++;
        }

        const faceNum = index.length/3;

        foreach (i; 0..faceNum) {
            const v0 = getMiddleIndex(index[i*3+0],index[i*3+1]);
            const v1 = getMiddleIndex(index[i*3+1],index[i*3+2]);
            const v2 = getMiddleIndex(index[i*3+2],index[i*3+0]);

            index ~= [index[i*3+0], v0, v2];
            index ~= [v0, index[i*3+1], v1];
            index ~= [v2,v1,index[i*3+2]];
            index ~= [v0, v1, v2];
        }
    }

    return result;
}


private enum GoldenRatio = (1 + sqrt(5.0f)) / 2;

private enum OriginalVertex = [
    vec3(-1, +GoldenRatio, 0),
    vec3(+1, +GoldenRatio, 0),
    vec3(-1, -GoldenRatio, 0),
    vec3(+1, -GoldenRatio, 0),

    vec3(0, -1, +GoldenRatio),
    vec3(0, +1, +GoldenRatio),
    vec3(0, -1, -GoldenRatio),
    vec3(0, +1, -GoldenRatio),

    vec3(+GoldenRatio, 0, -1),
    vec3(+GoldenRatio, 0, +1),
    vec3(-GoldenRatio, 0, -1),
    vec3(-GoldenRatio, 0, +1)
].map!(v => normalize(v)).array;

private enum OriginalIndex = [
    0,  11,  5,
    0,   5,  1,
    0,   1,  7,
    0,   7, 10,
    0,  10, 11,

    1,   5,  9,
    5,  11,  4,
    11,  10,  2,
    10,   7,  6,
    7,   1,  8,

    3,   9,  4,
    3,   4,  2,
    3,   2,  6,
    3,   6,  8,
    3,   8,  9,

    4,   9,  5,
    2,   4, 11,
    6,   2, 10,
    8,   6,  7,
    9,   8,  1
];
