module sbylib.graphics.material.gbuffer.normal;

import std;
import erupted;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;
import sbylib.math;

import sbylib.graphics.util.buffer;
import sbylib.graphics.util.uniformreference;
import sbylib.graphics.util.pipelineutil;
import sbylib.graphics.util.rendercontext;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;
import sbylib.graphics.util.texture;

import sbylib.graphics.material.gbuffer.material;
import sbylib.graphics.material.gbuffer.renderpass;

import sbylib.graphics.material.standard.renderpass;

class GBufferNormalMaterial {

    enum MaxObjects = 10;

    mixin GBufferMaterial!(DataSet);

    struct Vertex {
        vec3 position;
        vec2 uv;
    }

    private @own ShaderModule[] shaders;
    private @own Pipeline pipeline;

    mixin ImplReleaseOwn;

    this(Window window, PrimitiveTopology topology) {
        initialize(MaxObjects);
        with (RenderContext) {
            Pipeline.GraphicsCreateInfo pipelineCreateInfo = {
                stages: [createStage(ShaderStage.Vertex, shaders, q{
                    #version 450
                    layout (location = 0) in vec3 position;
                    layout (location = 1) in vec2 uv;
                    layout (location = 0) out vec2 outUV;

                    void main() {
                        gl_Position = vec4(position * 2, 1);
                        outUV = position.xy + 0.5;
                    }
                }), createStage(ShaderStage.Fragment, shaders, q{
                    #version 450
                    layout (location = 0) in vec2 uv;
                    layout (location = 0) out vec4 fragColor;

                    layout (binding = 0) uniform sampler2D position;
                    layout (binding = 1) uniform sampler2D normal;
                    layout (binding = 2) uniform sampler2D albedo;

                    void main() {
                        vec3 n = texture(normal, uv).xyz;
                        vec4 a = texture(albedo, uv);

                        fragColor = vec4(normalize(n)*.5+.5, a);
                    }
                })],
                vertexInputState: getVertexInputState!(Vertex),
                inputAssemblyState: {
                    topology: topology
                },
                viewportState: {
                    viewports: [{
                        x: 0.0f,
                        y: 0.0f,
                        width: window.width,
                        height: window.height,
                        minDepth: 0.0f,
                        maxDepth: 1.0f
                    }],
                    scissors: [{
                        offset: {
                            x: 0,
                            y: 0
                        },
                        extent: {
                            width: window.width,
                            height: window.height
                        }
                    }]
                },
                rasterizationState: {
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
                multisampleState: {
                    rasterizationSamples: SampleCount.Count1,
                    sampleShadingEnable: false,
                    alphaToCoverageEnable: false,
                    alphaToOneEnable: false,
                },
                depthStencilState: {
                    depthTestEnable: false,
                    depthWriteEnable: false,
                },
                colorBlendState: {
                    logicOpEnable: false,
                    attachments: [{
                        blendEnable: true,
                        srcColorBlendFactor: BlendFactor.SrcAlpha,
                        dstColorBlendFactor: BlendFactor.OneMinusSrcAlpha,
                        colorBlendOp: BlendOp.Add,
                        srcAlphaBlendFactor: BlendFactor.One,
                        dstAlphaBlendFactor: BlendFactor.Zero,
                        alphaBlendOp: BlendOp.Add,
                        colorWriteMask: ColorComponent.R
                                      | ColorComponent.G
                                      | ColorComponent.B
                                      | ColorComponent.A,
                    }]
                },
                layout: pipelineLayout,
                renderPass: StandardRenderPass(window),
                subpass: 0,
            };
            this.pipeline = Pipeline.create(VulkanContext.device, [pipelineCreateInfo])[0];
        }
    }

    static class DataSet {
        mixin GBufferDataSet;
        mixin UseVertex!(Vertex);
        mixin UseIndex!(uint);
        @type(DescriptorType.CombinedImageSampler) @stage(ShaderStage.Fragment) {
            @binding(0) Texture positionTexture;
            @binding(1) Texture normalTexture;
            @binding(2) Texture albedoTexture;
        }
        mixin ImplDescriptorSet;
        mixin ImplReleaseOwn;
        mixin ImplRecord;
        mixin ImplPreRenderer;

        this(Geometry)(Geometry geom, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout, Window window) {
            with (GBufferRenderPass(window)) {
                this.positionTexture = position.texture;
                this.normalTexture = normal.texture;
                this.albedoTexture = albedo.texture;
            }
            initializeVertexBuffer(geom);
            initializeIndexBuffer(geom);
            initializeDescriptorSet(descriptorPool, descriptorSetLayout);
        }
    }
}
