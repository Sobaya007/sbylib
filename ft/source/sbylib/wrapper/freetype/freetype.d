module sbylib.wrapper.freetype.freetype;

import derelict.freetype.ft;

class FreeType {

static:

    package FT_Library library;
    private bool initialized;

    void initialize(string path = null) {
        if (initialized) return;
        initialized = true;

        if (path is null) {
            DerelictFT.load();
        } else {
            DerelictFT.load(path);
        }

        const result = FT_Init_FreeType(&library);
        assert(!result, "Failed to initialize FreeType");
    }
}
