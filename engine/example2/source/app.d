import std;
import sbylib.engine;
import sbylib.event;
import sbylib.graphics;
import sbylib.wrapper.glfw;

void main() {
    Window window;
    with (WindowBuilder()) {
        width = 800;
        height = 600;
        title = "title";
        clientAPI = ClientAPI.NoAPI;
        resizable = false;
        window = buildWindow();
    }
    scope (exit)
        window.destroy();
    
    assert(GLFW.hasVulkanSupport());

    when(Frame(90)).then({
        GLFW.pollEvents();
    });

    when(window.shouldClose).then({
        stopEngine();
    });

    EngineSetting setting = {
        projectDirectory: "project"
    };
    startEngine(setting, [
        "window": Variant(window)
    ]);
}
