module sbylib.graphics.geometry.geometry2d.circle;

import sbylib.math;
import sbylib.wrapper.vulkan;
import sbylib.graphics.geometry.geometry;

auto buildGeometry(int division) 
    in (division >= 3)
{
    struct Vertex {
        vec3 position;
        vec3 normal;
        vec2 uv;
    }

    with (Geometry!(Vertex, void)()) {
        primitive = PrimitiveTopology.TriangleFan;

        Vertex center = {
            position: vec3(0),
            normal: vec3(0,0,1),
            uv: vec2(0.5)
        };
        add(center);

        foreach (i; 0..division+1) {
            auto angle = 360.deg * i / division;
            auto v = vec2(cos(angle), sin(angle)) * 0.5;
            Vertex vertex = {
                position: vec3(v,0),
                normal: vec3(0,0,1),
                uv: v + 0.5
            };
            add(vertex);
        }
        return build();
    }
}
