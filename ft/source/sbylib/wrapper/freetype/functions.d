module sbylib.wrapper.freetype.functions;

import derelict.freetype.ft;
import sbylib.wrapper.freetype.constants;

class FtFunction {
static:
    int[3] getVersion(FT_Library library) {
        int[3] result;
        FT_Library_Version(library, &result[0], &result[1], &result[2]);
        return result;
    }
}
