module sbylib.wrapper.freetype.character;

struct Character {
    dchar character;
    long offsetX, offsetY;
    long width, height;
    long advance;
    long maxHeight;
    ubyte[] bitmap;
}
