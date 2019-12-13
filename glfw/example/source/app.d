import sbylib.wrapper.glfw;

void main() {
    Window window;
    with (WindowBuilder()) {
        width = 800;
        height = 600;
        title = "po";
        resizable = false;
        window = buildWindow();
    }

    window.setKeyCallback!(keyCallback, (Exception e) { assert(false, e.toString()); });
    
    while (!window.shouldClose()) {

        if (GLFW.time > 1 && !window.visible) window.show();
        if (GLFW.time > 1 && window.minimized) window.show();
        window.swapBuffers();
        GLFW.pollEvents();
    }

    window.destroy();

    GLFW.terminate();
}

void keyCallback(Window window, KeyButton button, int scanCode, ButtonState state, BitFlags!ModKeyButton mods) nothrow {
    try {
        const key = GLFW.getKeyName(button, scanCode);
        if (state == ButtonState.Press) {
            switch (button) {
                case KeyButton.KeyM:
                    if (mods.Shift)
                        window.maximize();
                    else {
                        window.minimize();
                        GLFW.time = 0;
                    }
                    break;
                case KeyButton.KeyF:
                    window.setFullScreenMode(Screen.getPrimaryScreen(), [800,600]);
                    break;
                case KeyButton.KeyW:
                    window.setWindowMode([0,0], [800,600]);
                    break;
                case KeyButton.KeyH:
                    window.hide();
                    GLFW.time = 0;
                    break;
                case KeyButton.Left:
                    if (mods.Shift)
                        window.pos = [0, window.pos[1]];
                    else
                        window.pos = [window.pos[0]-10, window.pos[1]];
                    break;
                case KeyButton.Right:
                    if (mods.Shift)
                        window.pos = [Screen.getPrimaryScreen().currentVideoMode.width-window.size[0], window.pos[1]];
                    else
                        window.pos = [window.pos[0]+10, window.pos[1]];
                    break;
                case KeyButton.Up:
                    if (mods.Shift)
                        window.pos = [window.pos[0], 0];
                    else
                        window.pos = [window.pos[0], window.pos[1]-10];
                    break;
                case KeyButton.Down:
                    if (mods.Shift)
                        window.pos = [window.pos[0], Screen.getPrimaryScreen().currentVideoMode.height-window.size[1]];
                    else
                        window.pos = [window.pos[0], window.pos[1]+10];
                    break;
                case KeyButton.Escape:
                    window.shouldClose = true;
                    break;
                default:
                    break;
            }
        }
        import std.stdio : writeln;
        writeln(key);
    } catch (Throwable e) {
        assert(false, e.toString);
    }
}
