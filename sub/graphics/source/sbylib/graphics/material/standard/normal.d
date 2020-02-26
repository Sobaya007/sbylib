module sbylib.graphics.material.standard.normal;

import sbylib.graphics.material.standard.material;
import sbylib.graphics.material.standard.renderpass;

class NormalMaterial : Material {

    mixin RenderPass!(StandardRenderPass);

    mixin ShaderSource!(ShaderStage.Vertex, q{
        #version 450
        layout (location = 0) in vec3 position;
        layout (location = 1) in vec3 normal;
        layout (location = 0) out vec3 outNormal;

        layout (binding = 0) uniform UniformData {
            mat4 worldMatrix;
            mat4 viewMatrix;
            mat4 projectionMatrix;
        } uni;

        void main() {
            gl_Position = uni.projectionMatrix * uni.viewMatrix * uni.worldMatrix * vec4(position, 1);
            gl_Position.y = -gl_Position.y;
            outNormal = normal;
        }
    });

    mixin ShaderSource!(ShaderStage.Fragment, q{
        #version 450
        layout (location = 0) in vec3 normal;
        layout (location = 0) out vec4 fragColor;

        void main() {
            fragColor = vec4(normalize(normal)*.5+.5, 1);
        }
    });

    @vertex struct Vertex {
        vec3 position;
        vec3 normal;
    }

    immutable Pipeline.RasterizationStateCreateInfo rs = {
        depthClampEnable: false,
        rasterizerDiscardEnable: false,
        polygonMode: PolygonMode.Fill,
        cullMode: CullMode.None,
        frontFace: FrontFace.CounterClockwise,
        depthBiasEnable: false,
        depthBiasConstantFactor: 0.0f,
        depthBiasClamp: 0.0f,
        depthBiasSlopeFactor: 0.0f,
        lineWidth: 1.0f,
    };
    mixin Rasterization!(rs);

    immutable Pipeline.MultisampleStateCreateInfo ms = {
        rasterizationSamples: SampleCount.Count1,
        sampleShadingEnable: false,
        alphaToCoverageEnable: false,
        alphaToOneEnable: false,
    };
    mixin Multisample!(ms);

    immutable Pipeline.DepthStencilStateCreateInfo ds = {
        depthTestEnable: true,
        depthWriteEnable: true,
        depthCompareOp: CompareOp.Less,
    };
    mixin DepthStencil!(ds);

    immutable Pipeline.ColorBlendStateCreateInfo cs = {
        logicOpEnable: false,
        attachments: [{
            blendEnable: false,
            colorWriteMask: ColorComponent.R
                          | ColorComponent.G
                          | ColorComponent.B
                          | ColorComponent.A,
        }]
    };
    mixin ColorBlend!(cs);

    struct VertexUniform {
        mat4 worldMatrix;
        mat4 viewMatrix;
        mat4 projectionMatrix;
    }

    @uniform @binding(0) @stage(ShaderStage.Vertex) VertexUniform vertexUniform;

    mixin MaxObjects!(10);

    mixin Instance;
}
