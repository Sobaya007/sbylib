module sbylib.wrapper.assimp.node;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.mesh : Mesh;
import sbylib.wrapper.assimp.metadata : MetaData;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibMatrix, toArray;
import sbylib.wrapper.assimp.scene : Scene;
import sbylib.math : mat4;
import std.typecons : nullable, Nullable;

struct Node {

    private const(aiNode)* node;

    string name() const {
        return node.mName.toRegularString();
    }

    mat4 transformation() const {
        return node.mTransformation.toSbylibMatrix();
    }

    Node parent() {
        return Node(node.mParent);
    }

    auto children() {
        return toArray!((const(aiNode)* n) => Node(n))
            (node.mNumChildren, node.mChildren);
    }

    auto meshes() {
        return toArray!((uint i) => i)
            (node.mNumMeshes, node.mMeshes);
    }

    Nullable!MetaData metaData() {
        if (node.mMetaData is null) return typeof(return).init;
        return nullable(MetaData(node.mMetaData));
    }

    string toString(Scene scene) {
        import std.algorithm : map;
        import std.array : array;
        import std.format : format;
        import sbylib.wrapper.assimp.functions : tree;

        string[] strs;
        strs ~= children.map!(c => c.toString(scene)).array;
        strs ~= meshes.map!(i => scene.meshes[i].toString(scene)).array;
        strs ~= "matrix: " ~ this.transformation.toString();
        if (metaData.isNull is false) strs ~= metaData.toString();

        return tree(format!"Node[%s]"(name), strs);
    }
}
