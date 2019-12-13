module sbylib.wrapper.assimp.animation;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toRegularString, toArray;
import sbylib.wrapper.assimp.nodeanim : NodeAnim;
import sbylib.wrapper.assimp.meshanim : MeshAnim;

struct Animation {

    private const(aiAnimation)* anim;

    string name() {
        return anim.mName.toRegularString;
    }

    double duration() {
        return anim.mDuration;
    }

    double ticksPerSecond() {
        return anim.mTicksPerSecond;
    }

    auto channels() {
        return toArray!((const(aiNodeAnim)* n) => NodeAnim(n))
            (anim.mNumChannels, anim.mChannels);
    }

    auto meshChannels() {
        return toArray!((const(aiMeshAnim)* m) => MeshAnim(m))
            (anim.mNumMeshChannels, anim.mMeshChannels);
    }
}
