module sbylib.wrapper.assimp.mesh;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.constants : PrimitiveType;
import sbylib.wrapper.assimp.functions : toSbylibVector, toRegularString, toArray;
import sbylib.wrapper.assimp.face : Face;
import sbylib.wrapper.assimp.bone : Bone;
import sbylib.wrapper.assimp.animmesh : AnimMesh;
import sbylib.wrapper.assimp.scene : Scene;
import sbylib.math : vec3;
import std.typecons : BitFlags;

struct Mesh {

    private const(aiMesh)* mesh;

    BitFlags!PrimitiveType primitiveTypes() {
        import std.traits : EnumMembers;
        BitFlags!PrimitiveType result;
        static foreach (e; EnumMembers!(PrimitiveType)) {
            if (mesh.mPrimitiveTypes & e)
                result |= e;
        }
        return result;
    }

    auto vertices() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mVertices);
    }

    auto normals() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mNormals);
    }

    auto tangents() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mTangents);
    }

    auto bitangents() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mBitangents);
    }

    auto colors(size_t i) {
        return toArray!((aiColor4D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mColors[i]);
    }

    auto textureCoords(size_t i) {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (mesh.mNumVertices, mesh.mTextureCoords[i]);
    }

    uint numUVComponents(size_t i) {
        return mesh.mNumUVComponents[i];
    }

    auto faces() {
        return toArray!((const aiFace f) => Face(f))
            (mesh.mNumFaces, mesh.mFaces);
    }

    auto bones() {
        return toArray!((const(aiBone)* b) => Bone(b))
            (mesh.mNumBones, mesh.mBones);
    }

    uint materialIndex() {
        return mesh.mMaterialIndex;
    }

    string name() {
        return mesh.mName.toRegularString;
    }

    auto animMeshes() {
        return toArray!((const(aiAnimMesh)* a) => AnimMesh(a))
            (mesh.mNumAnimMeshes, mesh.mAnimMeshes);
    }

    string toString(Scene scene) {
        import std.algorithm : map, filter;
        import std.array : array;
        import std.conv : to;
        import std.format : format;
        import std.string : join;
        import std.traits : EnumMembers;
        import sbylib.wrapper.assimp.functions : tree;

        string[] strs;
        strs ~= [EnumMembers!PrimitiveType].filter!(p => primitiveTypes & p).map!(p => p.to!string).join(",").format!"[%s](%d)"(vertices.length);
        strs ~= bones.map!(b => b.toString()).array;
        if (materialIndex >= 0) strs ~= scene.materials[materialIndex].toString();

        return tree(format!"Mesh[%s]"(name), strs);
    }
}
