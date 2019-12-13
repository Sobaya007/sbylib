module sbylib.graphics.geometry.geometry;

import sbylib.math;
import sbylib.wrapper.vulkan;

struct Geometry(Vertex, Index) {

    private Vertex[] _vertexList;

    void add(Vertex vertex) {
        this._vertexList ~= vertex;
    }

    inout(Vertex[]) vertexList() inout {
        return _vertexList;
    }

    static if (!is(Index == void)) {
        private Index[] _indexList;

        void select(Index index) {
            _indexList ~= index;
        }

        inout(Index[]) indexList() inout {
            return _indexList;
        }
    }

    enum hasIndex = !is(Index == void);

    PrimitiveTopology primitive;

    auto build() {
        return this;
    }
}
