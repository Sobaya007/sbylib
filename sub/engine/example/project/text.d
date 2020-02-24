import std;
import sbylib.graphics;
import sbylib.event;
import sbylib.engine;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;

mixin(Register!(entryPoint));

@depends("root")
void entryPoint(ModuleContext context, string fontDir) {
    Window window;
    with (WindowBuilder()) {
        width = 400;
        height = 400;
        window = buildWindow();
    }

    auto store = new GlyphStore(fontDir.buildPath("consola.ttf"), 256);
    context.pushResource(store);

    GlyphGeometry geom;
    vec2 pos = vec2(-0.9);
    foreach (i; cast(int)'a'..cast(int)'z'+1) {
        auto g = store.getGlyph(cast(dchar)i);
        auto size = vec2(g.advance, g.maxHeight) * 0.1 / g.maxHeight / (vec2(window.width, window.height) / window.height);
        geom.add(g, pos, size);
        pos.x += size.x;
    }

    auto textBoard = new TextBoard(window, geom.geom);
    textBoard.tex = store.texture;
    context.pushResource(textBoard);
    with (context()) {
        when(Frame(88)).then({
            StandardRenderPass(window).submitRender();
        });
        when(Frame).then({
            with (textBoard.vertexUniform.map) {
                worldMatrix = textBoard.worldMatrix;
            }
        });
    }
}

class TextBoard {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin UseMaterial!(GlyphMaterial);
}
