module sbylib.graphics.geometry.geometry2d.triangle;

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
        static foreach (i; 0..3) {{
            auto angle = 90.deg + 120 * i.deg;
            auto v = vec2(cos(angle), sin(angle)) * 0.5;
            Vertex vertex = {
                position: vec3(v,0),
                normal: vec3(0,0,1),
                uv: v
            };
            add(vertex);
        }}
        return build();
    }
}
