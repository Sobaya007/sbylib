module sbylib.wrapper.freetype.fontloader;

public import sbylib.wrapper.freetype.font : Font;
import derelict.freetype.ft;

struct FontLoader {

    static FontLoader opCall() {
        import sbylib.wrapper.freetype.freetype : FreeType;
        FreeType.initialize();

        FontLoader result;
        return result;
    }

    Font load(string path, int size) {
        import sbylib.wrapper.freetype.constants : FontType;
        import sbylib.wrapper.freetype.freetype : FreeType;
        import std.string : toStringz;

        FT_Face face;
        const result = FT_New_Face(FreeType.library, path.toStringz, 0, &face);
        assert(!result, "Failed to load font");
        return new Font(face, size, FontType.Mono);
    }
}
