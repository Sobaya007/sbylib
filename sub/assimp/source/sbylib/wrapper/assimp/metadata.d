module sbylib.wrapper.assimp.metadata;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.constants : MetaDataType;
import sbylib.wrapper.assimp.functions : toRegularString, toSbylibVector, toEnum;
import sbylib.math : vec3;

struct MetaData {

    private const(aiMetadata)* data;

    auto keys() {
        import std.algorithm : map;

        return data.mKeys[0..data.mNumProperties].map!(key => key.toRegularString);
    }

    auto values() {
        import std.algorithm : map;

        return data.mValues[0..data.mNumProperties].map!(value => MetaDataEntry(value));
    }

    auto opIndex(string key) {
        import std.algorithm : countUntil;
        import std.range : drop;

        auto idx = this.keys.countUntil(key);
        return values.drop(idx).front;
    }

    string toString() {
        import std.algorithm : map;
        import std.array : array;
        import std.range : zip;
        import std.format : format;
        import sbylib.wrapper.assimp.functions : tree;

        return tree("Material", zip(keys, values).map!(t => format!"%s : %s"(t[0], t[1].toString())).array);
    }
}

struct MetaDataEntry {

    private const aiMetadataEntry entry;

    MetaDataType type() {
        return entry.mType.toEnum!MetaDataType;
    }

    auto data(Type)() {
        static if (is(Type == bool)) {
            assert(this.type == MetaDataType.Bool);
            return *cast(bool*)entry.mData;
        } else static if (is(Type == int)) {
            assert(this.type == MetaDataType.Int);
            return *cast(int*)entry.mData;
        } else static if (is(Type == ulong)) {
            assert(this.type == MetaDataType.Ulong);
            return *cast(ulong*)entry.mData;
        } else static if (is(Type == float)) {
            assert(this.type == MetaDataType.Float);
            return *cast(float*)entry.mData;
        } else static if (is(Type == string)) {
            import std.conv : to;
            assert(this.type == MetaDataType.String);
            return to!string(cast(char*)(entry.mData+4));
        } else static if (is(Type == vec3)) {
            assert(this.type == MetaDataType.Vec3);
            return toSbylibVector(*cast(aiVector3D*)entry.mData);
        } else {
            import std.format : format;
            static assert(false, format!"Invalid type specification: %s"(Type.stringof));
        }
    }

    string toString() {
        import std.conv : to;
        import std.format : format;

        final switch (type) {
            case MetaDataType.Bool:
                return this.data!bool.to!string;
            case MetaDataType.Int:
                return this.data!int.to!string;
            case MetaDataType.Ulong:
                return this.data!ulong.to!string;
            case MetaDataType.Float:
                return this.data!float.to!string;
            case MetaDataType.String:
                return this.data!string;
            case MetaDataType.Vec3:
                return this.data!vec3.to!string;
        }
    }
}
