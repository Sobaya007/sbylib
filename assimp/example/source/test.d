import std;
import sbylib.wrapper.assimp;

unittest {
    Assimp.initialize();
    auto scene = Scene.fromFile(__FILE__.dirName.dirName.buildPath("resource/test.blend"));
    assert(scene.rootNode.name == "<BlenderRoot>");
    assert(scene.cameras.length > 0);
    assert(scene.lights.length > 0);
}
