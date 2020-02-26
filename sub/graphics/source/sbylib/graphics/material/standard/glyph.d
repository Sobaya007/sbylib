module sbylib.graphics.material.standard.glyph;

import sbylib.graphics.material.standard.material;
import sbylib.graphics.material.standard.renderpass;

class GlyphMaterial : Material { 

    mixin RenderPass!(StandardRenderPass);

    mixin ShaderSource!(ShaderStage.Vertex, q{
        #version 450
        layout (location = 0) in vec2 position;
        layout (location = 1) in ivec2 uv;
        layout (location = 0) out vec2 uv2;

        layout (binding = 0) uniform UniformData {
            mat4 worldMatrix;
        } uni;

        void main() {
            gl_Position = uni.worldMatrix * vec4(position, 0, 1);
            gl_Position.y = -gl_Position.y;
            uv2 = uv;
        }
    });

    mixin ShaderSource!(ShaderStage.Fragment, q{
        #version 450
        layout (location = 0) in vec2 uv;
        layout (location = 0) out vec4 fragColor;

        layout (binding = 1) uniform sampler2D tex;

        void main() {
            fragColor = texture(tex, uv / textureSize(tex,0)).rrrr;
        }
    });

    @vertex struct Vertex {
        vec2 position;
        ivec2 uv;
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
    }

    @uniform @binding(0) @stage(ShaderStage.Vertex) VertexUniform vertexUniform;
    @texture @binding(1) @stage(ShaderStage.Fragment) Texture tex;

    mixin MaxObjects!(10);

    mixin Instance;
}
