module sbylib.wrapper.assimp.bone;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibMatrix, toArray;
import sbylib.wrapper.assimp.vertexweight : VertexWeight;
import sbylib.math : mat4;

struct Bone {
    
    private const(aiBone)* bone;

    string name() {
        return bone.mName.toRegularString;
    }

    auto weights() {
        return toArray!((aiVertexWeight w) => VertexWeight(w))
            (bone.mNumWeights, bone.mWeights);
    }

    mat4 offsetMatrix() {
        return bone.mOffsetMatrix.toSbylibMatrix;
    }

    string toString() {
        import std.format : format;
        return format!"Bone[%s]"(name);
    }
}
