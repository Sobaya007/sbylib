module sbylib.graphics.util.model;

import std;
import sbylib.math;
import sbylib.graphics.geometry;
import sbylib.wrapper.vulkan;
import sbylib.wrapper.assimp;
import sbylib.wrapper.assimp : AssimpScene = Scene,
       AssimpNode = Node, 
       AssimpMesh = Mesh, 
       AssimpMaterial = Material,
       AssimpPrimitiveType = PrimitiveType,
       AssimpPropertyTypeInfo = PropertyTypeInfo;

ModelNode loadModel(string path, PostProcessFlag flags = PostProcessFlag.None) {
    Assimp.initialize();
    auto scene = AssimpScene.fromFile(path, flags);
    return new ModelNode(scene.rootNode, scene);
}

class ModelNode {
    ModelNode[] children;
    ModelMesh[] meshes;
    mat4 transformation;

    this(AssimpNode node, AssimpScene scene) {
        this.children = node.children.map!(c => new ModelNode(c, scene)).array;
        this.meshes = node.meshes.map!(i => new ModelMesh(scene.meshes[i], scene)).array;
        this.transformation = node.transformation;
    }
}

private class ModelMesh {
    ModelGeometry geom;
    string name;
    Variant[string] material;

    this(AssimpMesh mesh, AssimpScene scene) {
        this.geom = createGeometry(mesh);
        this.name = mesh.name;
        if (mesh.materialIndex >= 0) {
            this.material = createMaterial(scene.materials[mesh.materialIndex]);
        }
    }
}

struct ModelVertex {
    vec3 position;
    vec3 normal;
}

alias ModelGeometry = Geometry!(ModelVertex, uint);

private ModelGeometry createGeometry(AssimpMesh mesh) {
    with (ModelGeometry()) {
        with (mesh) {
            primitive = conv(primitiveTypes);
            foreach (t; zip(vertices, normals)) {
                add(ModelVertex(t.expand));
            }
            foreach (face; faces) {
                foreach (i; face.indices) {
                    select(i);
                }
            }
        }
        return build();
    }
}

private PrimitiveTopology conv(BitFlags!AssimpPrimitiveType t) {
    if (t & AssimpPrimitiveType.Point)    return PrimitiveTopology.PointList;
    if (t & AssimpPrimitiveType.Line)     return PrimitiveTopology.LineList;
    if (t & AssimpPrimitiveType.Triangle) return PrimitiveTopology.TriangleList;
    if (t & AssimpPrimitiveType.Polygon) return PrimitiveTopology.TriangleStrip;
    assert(false);
}

private Variant[string] createMaterial(AssimpMaterial mat) {
    Variant[string] result;
    foreach (prop; mat.properties) {
        final switch (prop.type) {
            case AssimpPropertyTypeInfo.Float:
                result[prop.key] = prop.data!float;
                break;
            case AssimpPropertyTypeInfo.String:
                result[prop.key] = prop.data!string;
                break;
            case AssimpPropertyTypeInfo.Integer:
                result[prop.key] = prop.data!int;
                break;
            case AssimpPropertyTypeInfo.Buffer:
                assert(false);
        }
    }
    return result;
}
