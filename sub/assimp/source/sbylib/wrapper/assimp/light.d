module sbylib.wrapper.assimp.light;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.constants : LightSourceType;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibVector, toEnum;
import sbylib.math : vec3, vec2;

struct Light {

    private const(aiLight)* light;

    string name() {
        return light.mName.toRegularString;
    }

    LightSourceType type() {
        return light.mType.toEnum!LightSourceType;
    }

    vec3 position() {
        return light.mPosition.toSbylibVector;
    }

    vec3 direction() {
        return light.mDirection.toSbylibVector;
    }

    vec3 up() {
        return light.mUp.toSbylibVector;
    }

    float attenuationConstant() {
        return light.mAttenuationConstant;
    }

    float attenuationLinear() {
        return light.mAttenuationLinear;
    }

    float attenuationQuadratic() {
        return light.mAttenuationQuadratic;
    }

    vec3 colorDiffuse() {
        return light.mColorDiffuse.toSbylibVector;
    }

    vec3 colorSpecular() {
        return light.mColorSpecular.toSbylibVector;
    }

    vec3 colorAmbient() {
        return light.mColorAmbient.toSbylibVector;
    }

    float angleInnerCone() {
        return light.mAngleInnerCone;
    }

    float angleOuterCone() {
        return light.mAngleOuterCone;
    }

    vec2 size() {
        return light.mSize.toSbylibVector;
    }

    string toString() {
        import std.format : format;
        import sbylib.wrapper.assimp.functions : tree;

        string[] strs;
        strs ~= format!"type: %s"(type);
        strs ~= format!"position: %s"(position);
        strs ~= format!"direction: %s"(direction);
        strs ~= format!"up: %s"(up);
        strs ~= format!"attenuationConstant: %s"(attenuationConstant);
        strs ~= format!"attenuationLinear: %s"(attenuationLinear);
        strs ~= format!"attenuationQuadratic: %s"(attenuationQuadratic);
        strs ~= format!"colorDiffuse: %s"(colorDiffuse);
        strs ~= format!"colorSpecular: %s"(colorSpecular);
        strs ~= format!"colorAmbient: %s"(colorAmbient);
        strs ~= format!"angleInnerCone: %s"(angleInnerCone);
        strs ~= format!"angleOuterCone: %s"(angleOuterCone);
        strs ~= format!"size: %s"(size);

        return tree(format!"Light[%s]"(name), strs);
    }
}
