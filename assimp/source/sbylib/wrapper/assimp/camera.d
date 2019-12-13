module sbylib.wrapper.assimp.camera;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibVector;
import sbylib.math : vec3;

struct Camera {

    private const(aiCamera)* camera;

    string name() {
        return camera.mName.toRegularString;
    }

    vec3 position() {
        return camera.mPosition.toSbylibVector;
    }

    vec3 up() {
        return camera.mUp.toSbylibVector;
    }

    vec3 lookAt() {
        return camera.mLookAt.toSbylibVector;
    }

    float horizontalFOV() {
        return camera.mHorizontalFOV;
    }

    float clipPlaneNear() {
        return camera.mClipPlaneNear;
    }

    float clipPlaneFar() {
        return camera.mClipPlaneFar;
    }

    float aspect() {
        return camera.mAspect;
    }

    string toString() {
        import std.format : format;
        import sbylib.wrapper.assimp.functions : tree;

        string[] strs;
        strs ~= format!"position: %s"(position);
        strs ~= format!"up: %s"(up);
        strs ~= format!"lookAt: %s"(lookAt);
        strs ~= format!"horizontalFOV: %s"(horizontalFOV);
        strs ~= format!"clipPlaneNear: %s"(clipPlaneNear);
        strs ~= format!"clipPlaneFar: %s"(clipPlaneFar);
        strs ~= format!"aspect: %s"(aspect);

        return tree(format!"Camera[%s]"(name), strs);
    }
}
