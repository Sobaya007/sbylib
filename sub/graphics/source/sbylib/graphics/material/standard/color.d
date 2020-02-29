module sbylib.graphics.material.standard.color;

import sbylib.graphics.material.standard.material;
import sbylib.graphics.material.standard.renderpass;

class ColorMaterial : Material {

    mixin RenderPass!(StandardRenderPass);

    mixin ShaderSource!(ShaderStage.Vertex, q{
        #version 450
        layout (location = 0) in vec3 position;

        layout (binding = 0) uniform UniformData {
            mat4 worldMatrix;
            mat4 viewMatrix;
            mat4 projectionMatrix;
        } uni;

        void main() {
            gl_Position = uni.projectionMatrix * uni.viewMatrix * uni.worldMatrix * vec4(position, 1);
            gl_Position.y = -gl_Position.y;
        }
    });

    mixin ShaderSource!(ShaderStage.Fragment, q{
        #version 450
        layout (location = 0) out vec4 fragColor;

        layout (binding = 1) uniform UniformData {
            vec4 color;
        } uni;

        void main() {
            fragColor = uni.color;
        }
    });

    @vertex struct Vertex {
        vec3 position;
    }

    immutable CreateInfo i = {
        rasterization: {
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
        },
        multisample: {
            rasterizationSamples: SampleCount.Count1,
            sampleShadingEnable: false,
            alphaToCoverageEnable: false,
            alphaToOneEnable: false,
        },
        depthStencil: {
            depthTestEnable: true,
            depthWriteEnable: true,
            depthCompareOp: CompareOp.Less,
        },
        colorBlend: {
            logicOpEnable: false,
            attachments: [{
                blendEnable: false,
                colorWriteMask: ColorComponent.R
                              | ColorComponent.G
                              | ColorComponent.B
                              | ColorComponent.A,
            }]
        }
    };
    mixin Info!i;

    struct VertexUniform {
        mat4 worldMatrix;
        mat4 viewMatrix;
        mat4 projectionMatrix;
    }

    struct FragmentUniform {
        vec4 color;
    }

    @uniform @binding(0) @stage(ShaderStage.Vertex) VertexUniform vertexUniform;
    @uniform @binding(1) @stage(ShaderStage.Fragment) FragmentUniform fragmentUniform;

    mixin MaxObjects!(10);

    mixin Instance;
}
