module sbylib.wrapper.assimp.quatkey;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toSbylibQuaternion;
import sbylib.math : quat;

struct QuatKey {

    private aiQuatKey key;

    double time() {
        return key.mTime;
    }

    quat value() {
        return key.mValue.toSbylibQuaternion;
    }
}
