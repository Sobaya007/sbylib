module sbylib.graphics.geometry.geometry3d.box;

import std;
import sbylib.math;
import sbylib.wrapper.vulkan;
import sbylib.graphics.geometry.geometry;

auto buildGeometry() {
    struct Vertex {
        vec3 position;
        vec3 normal;
        vec2 uv;
    }

    with (Geometry!(Vertex, void)()) {
        primitive = PrimitiveTopology.TriangleList;
        static foreach (i; 0..6) {{
            const s = i % 2 * 2 - 1;
            alias swap = (a, i) => vec3(a[(0+i)%3], a[(1+i)%3], a[(2+i)%3]);
            const positions = [
                vec3(+s, +s, +s),
                vec3(+s, +s, -s),
                vec3(+s, -s, +s),
                vec3(+s, -s, -s)
            ].map!(a => swap(a, i/2)).array;

            const normal = swap(vec3(+s,0,0), i/2);

            const uvs = [
                vec2(0,0),
                vec2(0,1),
                vec2(1,0),
                vec2(1,1)
            ];

            int[6] order;
            if (i&1) order = [0,1,2, 2,1,3];
            else order = [2,1,0, 3,1,2];
            foreach(j; order) {
                Vertex vertex = {
                    position: positions[j],
                    normal: normal,
                    uv: uvs[j]
                };
                add(vertex);
            }
        }}
        return build();
    }
}
