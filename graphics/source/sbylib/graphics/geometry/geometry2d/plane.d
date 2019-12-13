module sbylib.graphics.geometry.geometry2d.plane;

import sbylib.math;
import sbylib.wrapper.vulkan;
import sbylib.graphics.geometry.geometry;

auto buildGeometry(bool strip) {
    struct Vertex {
        vec3 position;
        vec3 normal;
        vec2 uv;
    }

    with (Geometry!(Vertex, void)()) {
        int[4] x, y;
        if (strip) {
            x = [0,0,1,1];
            y = [0,1,0,1];
            primitive = PrimitiveTopology.TriangleStrip;
        } else {
            x = [0,0,1,1];
            y = [0,1,1,0];
            primitive = PrimitiveTopology.TriangleFan;
        }

        static foreach (i; 0..4) {{
            auto v = vec2(x[i], y[i]);
            Vertex vertex = {
                position: vec3(v-0.5, 0),
                normal: vec3(0,0,1),
                uv: v,
            };
            add(vertex);
        }}
        return build();
    }
}
