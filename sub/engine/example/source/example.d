import std;
import sbylib;
import erupted;

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
    
    enforce(GLFW.hasVulkanSupport());

    VulkanContext.initialize("example app", VK_MAKE_VERSION(0,0,1), window);
    scope (exit) VulkanContext.deinitialize();

    when(KeyButton.Escape.pressed.on(window)).then({
        window.shouldClose = true;
    });
    when(window.shouldClose).then({
        stopEngine();
    });
    when(Frame(90)).then({
        GLFW.pollEvents();
    });
    when(Frame(88)).then({
        StandardRenderPass(window).submitRender();
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
