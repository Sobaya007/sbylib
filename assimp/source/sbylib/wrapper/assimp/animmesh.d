module sbylib.wrapper.assimp.animmesh;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibVector, toSbylibMatrix, toArray;
import sbylib.wrapper.assimp.vertexweight : VertexWeight;

struct AnimMesh {

    private const(aiAnimMesh)* animMesh;

    auto vertices() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mVertices);
    }

    auto normals() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mNormals);
    }

    auto tangents() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mTangents);
    }

    auto bitangents() {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mBitangents);
    }

    auto colors(size_t i) {
        return toArray!((aiColor4D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mColors[i]);
    }

    auto textureCoords(size_t i) {
        return toArray!((aiVector3D v) => v.toSbylibVector)
            (animMesh.mNumVertices, animMesh.mTextureCoords[i]);
    }
}
