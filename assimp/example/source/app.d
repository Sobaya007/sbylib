import std.stdio;
import sbylib.wrapper.assimp;

void main() {
    Assimp.initialize();
    auto scene = Scene.fromFile("resource/test.blend");
    writeln(scene.toString());
}
