module sbylib.graphics.glyph.glyphgeometry;

import sbylib.graphics.glyph.glyph;
import sbylib.graphics.geometry;
import sbylib.math;
import sbylib.wrapper.vulkan;

struct GlyphGeometry {

    struct Vertex {
        vec2 position;
        ivec2 uv;
    }

    Geometry!(Vertex, uint) geom;
    alias geom this;

    void add(Glyph g, vec2 pos, vec2 size) {
        const indexOffset = cast(int)this.vertexList.length;

        alias lvec2 = Vector!(long,2);

        geom.add(Vertex(pos+vec2(     0, -size.y), cast(ivec2)(lvec2(g.x,g.y) + lvec2(        0, g.maxHeight))));
        geom.add(Vertex(pos+vec2(     0,       0), cast(ivec2)(lvec2(g.x,g.y) + lvec2(        0,           0))));
        geom.add(Vertex(pos+vec2(size.x, -size.y), cast(ivec2)(lvec2(g.x,g.y) + lvec2(g.advance, g.maxHeight))));
        geom.add(Vertex(pos+vec2(size.x,       0), cast(ivec2)(lvec2(g.x,g.y) + lvec2(g.advance,           0))));

        geom.select(indexOffset + 0);
        geom.select(indexOffset + 1);
        geom.select(indexOffset + 2);
        geom.select(indexOffset + 2);
        geom.select(indexOffset + 1);
        geom.select(indexOffset + 3);

        geom.primitive = PrimitiveTopology.TriangleList;
    }
}
