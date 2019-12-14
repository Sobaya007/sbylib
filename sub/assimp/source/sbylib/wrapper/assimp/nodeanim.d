module sbylib.wrapper.assimp.nodeanim;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.constants : AnimBehaviour;
import sbylib.wrapper.assimp.functions : toRegularString, toArray, toEnum;
import sbylib.wrapper.assimp.vectorkey : VectorKey;
import sbylib.wrapper.assimp.quatkey : QuatKey;

struct NodeAnim {

    private const(aiNodeAnim)* node;

    string nodeName() {
        return node.mNodeName.toRegularString;
    }

    auto positionKeys() {
        return toArray!((aiVectorKey key) => VectorKey(key))
            (node.mNumPositionKeys, node.mPositionKeys);
    }

    auto rotationKeys() {
        return toArray!((aiQuatKey key) => QuatKey(key))
            (node.mNumRotationKeys, node.mRotationKeys);
    }

    auto scalingKeys() {
        return toArray!((aiVectorKey key) => VectorKey(key))
            (node.mNumScalingKeys, node.mScalingKeys);
    }

    auto preState() {
        return node.mPreState.toEnum!AnimBehaviour;
    }

    auto postState() {
        return node.mPostState.toEnum!AnimBehaviour;
    }
}
