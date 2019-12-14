module sbylib.wrapper.assimp.material;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.constants : PropertyTypeInfo;
import sbylib.wrapper.assimp.functions : toRegularString, toArray, toEnum;

struct Material {

    private const(aiMaterial)* mat;

    auto properties() {
        return toArray!((const(aiMaterialProperty)* p) => MaterialProperty(p))
            (mat.mNumProperties, mat.mProperties);
    }

    string toString() {
        import std.algorithm : map;
        import std.array : array;
        import sbylib.wrapper.assimp.functions : tree;

        return tree("Material", properties.map!(p => p.toString).array);
    }
}

struct MaterialProperty {

    private const(aiMaterialProperty)* prop;

    string key() {
        return prop.mKey.toRegularString;
    }

    PropertyTypeInfo type() {
        return prop.mType.toEnum!PropertyTypeInfo;
    }

    uint semantic() { // used for only texture property
        return prop.mSemantic;
    }

    uint index() { // used for only texture property
        return prop.mIndex;
    }

    auto data(Type)() {
        static if (is(Type == float)) {
            assert(type == PropertyTypeInfo.Float);
            return *(cast(float*)prop.mData);
        } else static if (is(Type == string)) {
            import std.conv : to;
            assert(type == PropertyTypeInfo.String);
            return to!string(cast(char*)(prop.mData+4));
        } else static if (is(Type == int)) {
            assert(type == PropertyTypeInfo.Integer);
            return *(cast(int*)prop.mData);
        } else static if (is(Type == ubyte[])) {
            assert(type == PropertyTypeInfo.Buffer);
            return prop.mData[0..prop.mDataLength];
        }
    }
    
    string toString() {
        import std.conv : to;
        import std.format : format;

        string value;
        final switch (type) {
            case PropertyTypeInfo.Float:
                value = this.data!float.to!string;
                break;
            case PropertyTypeInfo.String:
                value = this.data!string;
                break;
            case PropertyTypeInfo.Integer:
                value = this.data!int.to!string;
                break;
            case PropertyTypeInfo.Buffer:
                value = "<Buffer>";
                break;
        }
        return format!"%s : %s"(key, value);
    }
}
