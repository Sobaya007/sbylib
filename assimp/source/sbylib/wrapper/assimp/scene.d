module sbylib.wrapper.assimp.scene;

import bindbc.assimp;
import sbylib.wrapper.assimp.constants : PostProcessFlag;
import sbylib.wrapper.assimp.functions : toArray, indent;
import sbylib.wrapper.assimp.node : Node;
import sbylib.wrapper.assimp.mesh : Mesh;
import sbylib.wrapper.assimp.material : Material;
import sbylib.wrapper.assimp.animation : Animation;
import sbylib.wrapper.assimp.texture : Texture;
import sbylib.wrapper.assimp.light : Light;
import sbylib.wrapper.assimp.camera : Camera;

class Scene {

    private const(aiScene)* scene;

    private this(const(aiScene)* scene) 
        in (scene !is null)
    {
        this.scene = scene;
    }

    static fromFile(string file, PostProcessFlag flags = PostProcessFlag.None) {
        import std.format : format;
        import std.string : toStringz;

        auto scene = aiImportFile(file.toStringz, flags);
        assert(scene !is null, format!"Load error: %s cannot be loaded."(file));
        return new Scene(scene);
    }

    void destroy() {
        aiReleaseImport(scene);
    }

    Scene dup() {
        aiScene* newScene;
        aiCopyScene(this.scene, &newScene);
        return new Scene(newScene);
    }

    uint flags() {
        return scene.mFlags;
    }

    Node rootNode() {
        return Node(scene.mRootNode);
    }

    auto meshes() {
        return toArray!((const(aiMesh)* mesh) => Mesh(mesh))
            (scene.mNumMeshes, scene.mMeshes);
    }

    auto materials() {
        return toArray!((const(aiMaterial)* mat) => Material(mat))
            (scene.mNumMaterials, scene.mMaterials);
    }

    auto animations() {
        return toArray!((const(aiAnimation)* anim) => Animation(anim))
            (scene.mNumAnimations, scene.mAnimations);
    }

    auto textures() {
        return toArray!((const(aiTexture)* tex) => Texture(tex))
            (scene.mNumTextures, scene.mTextures);
    }

    auto lights() {
        return toArray!((const(aiLight)* light) => Light(light))
            (scene.mNumLights, scene.mLights);
    }

    auto cameras() {
        return toArray!((const(aiCamera)* camera) => Camera(camera))
            (scene.mNumCameras, scene.mCameras);
    }

    override string toString() {
        import std.algorithm : map;
        import std.array : array;
        import sbylib.wrapper.assimp.functions : tree;

        string[] strs;
        strs ~= rootNode.toString(this);
        strs ~= lights.map!(l => l.toString()).array;
        strs ~= cameras.map!(c => c.toString()).array;

        return tree("Scene", strs);
    }
}
