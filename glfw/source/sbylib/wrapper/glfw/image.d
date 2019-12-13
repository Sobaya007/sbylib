module sbylib.wrapper.glfw.image;

import derelict.glfw3.glfw3;

struct Image {
    private GLFWimage mImage;

    package this(GLFWimage image) {
        this.mImage = image;
    }

    this(uint width, uint height) {
        this(width, height, new ubyte[width * height]);
    }

    this(uint width, uint height, ubyte[] data) 
    in (data.length == width * height)
    {
        this.mImage.width = width;
        this.mImage.height = height;
        this.mImage.pixels = data.ptr;
    }

    uint width() const {
        return this.mImage.width;
    }

    uint height() const {
        return this.mImage.height;
    }
    
    ubyte[] data() {
        return this.mImage.pixels[0..width * height];
    }

    package const(GLFWimage*) image() const {
        return &mImage;
    }

}
