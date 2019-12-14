import std;
import sbylib.graphics;
import sbylib.event;
import sbylib.engine;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;

mixin(Register!(entryPoint));

@depends("root")
void entryPoint(Project proj, ModuleContext context) {
    auto window = proj.get!Window("window");
    auto camera = proj.get!Camera("camera");

    //setupTextBoard(context, camera);
}

private TextBoard setupTextBoard(ModuleContext context, Window window, Camera camera) {
    auto store = new GlyphStore("./font/consola.ttf", 256);
    context.pushResource(store);
    foreach (i; cast(int)'a'..cast(int)'z'+1) {
        store.getGlyph(cast(dchar)i);
    }

    auto result = new TextBoard(window, GeometryLibrary().buildPlane(), store.texture);
    context.pushResource(result);
    with (result) {
        scale = vec3(10);
    }
    with (context()) {
        when(Frame).then({
            with (result.vertexUniform) {
                worldMatrix = result.worldMatrix;
                viewMatrix = camera.viewMatrix;
                projectionMatrix = camera.projectionMatrix;
            }
        });
    }
    return result;
}

class TextBoard {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin UseMaterial!(TextureMaterial);
}
