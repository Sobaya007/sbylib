import std;
import sbylib.engine;
import sbylib.event;
import sbylib.graphics;
import sbylib.wrapper.glfw;

void entryPoint() {
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
        projectDirectory: __FILE_FULL_PATH__.dirName.dirName.buildPath("project")
    };
    string baseDir = __FILE_FULL_PATH__.dirName.dirName;
    startEngine(setting, [
        "window": Variant(window),
        "fontDir": Variant(baseDir.buildPath("font")),
        "resourceDir": Variant(baseDir.buildPath("resource"))
    ]);
}
