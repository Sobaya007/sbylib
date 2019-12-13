import sbylib.engine;
import sbylib.event;
import sbylib.graphics;
import sbylib.wrapper.gl;
import sbylib.wrapper.glfw;

void main() {
    Window window;
    with (WindowBuilder()) {
        width = 800;
        height = 600;
        contextVersionMajor = 4;
        contextVersionMinor = 5;
        floating = true;
        window = buildWindow();
    }
    scope(exit) window.destroy();
    window.makeCurrent();
    
    GL.initialize();

    when(Frame(90)).then({
        GLFW.pollEvents();
        window.swapBuffers();
    });

    when(window.shouldClose).then({
        stopEngine();
    });

    EngineSetting setting = {
        projectDirectory: "project"
    };
    startEngine(setting);
}
