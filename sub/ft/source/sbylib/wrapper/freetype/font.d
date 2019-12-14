module sbylib.wrapper.freetype.font;

import derelict.freetype.ft;

public import sbylib.wrapper.freetype.character : Character;
import sbylib.wrapper.freetype.constants;

class Font {

    private FT_Face face;
    private FontType fontType;

    package this(FT_Face face, int size, FontType fontType) {
        this.face = face;
        const result = FT_Set_Pixel_Sizes(this.face, 0, size);
        assert(!result);
    }

    Character getLetterInfo(dchar c) {
        const result = FT_Load_Char(this.face, c, FontLoadType.Render);
        assert (!result);

        const glyph = face.glyph;
        const sz = face.size.metrics;
        const met = glyph.metrics;

        const bearingX = met.horiBearingX/64;
        const bearingY = met.horiBearingY/64;
        const width = glyph.bitmap.width;
        const height = glyph.bitmap.rows;

        const ascender = sz.ascender / 64;
        const advance = glyph.advance.x/64;
        const maxHeight = (sz.ascender - sz.descender) / 64;

        const offsetX = bearingX;
        const offsetY = ascender - bearingY;

        const bm = glyph.bitmap;

        assert(bm.pitch == width);

        auto bm2 = bm.buffer[0..width*height].dup;

        return Character(c, offsetX, offsetY, width, height, advance, maxHeight, bm2);
    }
}
