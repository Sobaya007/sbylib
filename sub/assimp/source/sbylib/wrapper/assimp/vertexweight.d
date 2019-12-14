module sbylib.wrapper.assimp.vertexweight;

import bindbc.assimp.types;

struct VertexWeight {
    
    private aiVertexWeight w;

    uint vertexID() {
        return w.mVertexId;
    }

    float weight() {
        return w.mWeight;
    }
}
