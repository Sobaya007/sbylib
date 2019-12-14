module sbylib.wrapper.glfw.cursor;

import derelict.glfw3.glfw3;

import sbylib.wrapper.glfw.constants : CursorShape;

public import sbylib.wrapper.glfw.image : Image;

struct Cursor {

    package GLFWcursor *cursor;

    private this(GLFWcursor *cursor) {
        this.cursor = cursor;
    }

    this(Image image, int[2] hotspot) {
        this.cursor = glfwCreateCursor(image.image, hotspot[0], hotspot[1]);
    }

    static Cursor createStandardCursor(CursorShape shape) {
        return Cursor(glfwCreateStandardCursor(shape));
    }

    void destroy() {
        glfwDestroyCursor(cursor);
    }
}
