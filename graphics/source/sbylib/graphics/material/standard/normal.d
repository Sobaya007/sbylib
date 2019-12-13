module sbylib.graphics.material.standard.normal;

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

import sbylib.graphics.material.standard.material;
import sbylib.graphics.material.standard.renderpass;

class NormalMaterial {

    enum MaxObjects = 10;

    mixin Material!(DataSet);

    struct Vertex {
        vec3 position;
        vec3 normal;
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
                }), createStage(ShaderStage.Fragment, shaders, q{
                    #version 450
                    layout (location = 0) in vec3 normal;
                    layout (location = 0) out vec4 fragColor;

                    void main() {
                        fragColor = vec4(normalize(normal)*.5+.5, 1);
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
                    depthTestEnable: true,
                    depthWriteEnable: true,
                    depthCompareOp: CompareOp.Less,
                },
                colorBlendState: {
                    logicOpEnable: false,
                    attachments: [{
                        blendEnable: false,
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

    struct VertexUniform {
        mat4 worldMatrix;
        mat4 viewMatrix;
        mat4 projectionMatrix;
    }

    static class DataSet {
        mixin StandardDataSet;
        mixin UseVertex!(Vertex);
        mixin UseIndex!(uint);
        @binding(0) mixin UseVertexUniform!(VertexUniform);
        mixin ImplDescriptorSet;
        mixin ImplReleaseOwn;
        mixin ImplRecord;

        this(Geometry)(Geometry geom, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
            initializeVertexBuffer(geom);
            initializeIndexBuffer(geom);
            initializeVertexUniform();
            initializeDescriptorSet(descriptorPool, descriptorSetLayout);
        }
    }
}
