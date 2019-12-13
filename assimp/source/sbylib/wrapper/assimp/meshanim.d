module sbylib.wrapper.assimp.meshanim;

import bindbc.assimp.types;
import sbylib.wrapper.assimp.functions : toRegularString, toArray;
import sbylib.wrapper.assimp.meshkey : MeshKey;

struct MeshAnim {

    private const(aiMeshAnim)* mesh;

    string name() {
        return mesh.mName.toRegularString;
    }

    auto channels() {
        return toArray!((aiMeshKey key) => MeshKey(key))
            (mesh.mNumKeys, mesh.mKeys);
    }
}
