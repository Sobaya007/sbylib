module sbylib.graphics.material.standard.material;

public import std;
public import sbylib.math;
public import sbylib.wrapper.vulkan;
public import sbylib.graphics.wrapper.texture;

import sbylib.wrapper.glfw;
import erupted;
import sbylib.graphics.core.descriptor;
import sbylib.graphics.core.shader;
import sbylib.graphics.util.own;

mixin template UseMaterial(MaterialType) {
    alias DataType = MaterialType.DataSet;
    DataType _data;
    alias _data this;
    private void delegate() delegate() _reregister;
    private void delegate() _unregister;

    this(Geometry, Args...)(Window window, Geometry geom, Args args) {
        constructor(window, geom, args);
    }

    void constructor(Geometry, Args...)(Window window, Geometry geom, Args args) {
        auto tmp = MaterialType(window).build(geom, args);
        _data = tmp[0];
        auto register = tmp[1];
        this._reregister = () => StandardRenderPass(window).register(register);
        when(Frame).once({
            this._unregister = _reregister();
            _data.pushReleaseCallback(_unregister);
        });
    }

    ~this() {
        this._data.destroy();
    }


    void unregister() {
        _unregister();
    }

    void reregister() {
        _unregister = _reregister();
    }
}

class Material {

    mixin Descriptor;

    protected @own {
        PipelineLayout pipelineLayout;
        Pipeline pipeline;
    }

    mixin ImplReleaseOwn;

    mixin template Rasterization(Pipeline.RasterizationStateCreateInfo rs) {
        private Pipeline.RasterizationStateCreateInfo rasterizationState () {
            return rs;
        }
    }

    mixin template Multisample(Pipeline.MultisampleStateCreateInfo ms) {
        private Pipeline.MultisampleStateCreateInfo multisampleState () {
            return ms;
        }
    }

    mixin template DepthStencil(Pipeline.DepthStencilStateCreateInfo ds) {
        private Pipeline.DepthStencilStateCreateInfo depthStencilState () {
            return ds;
        }
    }

    mixin template ColorBlend(Pipeline.ColorBlendStateCreateInfo cs) {
        private Pipeline.ColorBlendStateCreateInfo colorBlendState () {
            return cs;
        }
    }

    mixin template Instance() {
        import sbylib.graphics.core;
        import sbylib.graphics.util;
        import sbylib.graphics.wrapper;
        import sbylib.graphics.material.standard.renderpass : StandardRenderPass;
        import sbylib.wrapper.glfw : Window;
        alias This = typeof(this);

        mixin ImplDescriptor;

        private static typeof(this)[Tuple!(Window,PrimitiveTopology)] instance;

        static opCall(Window window) {
            return Builder(window);
        }

        struct Builder {
            Window window;

            public auto build(Geometry)(Geometry geom) {
                with (getInstance(window, geom.primitive)) {
                    auto result = new DataSet(geom);
                    auto register = (CommandBuffer commandBuffer) {
                        with (result) {
                            if (!descriptorSet) initializeDescriptorSet(descriptorPool, descriptorSetLayout);
                            commandBuffer.cmdBindPipeline(PipelineBindPoint.Graphics, pipeline);
                            commandBuffer.cmdBindDescriptorSets(PipelineBindPoint.Graphics, pipelineLayout, 0, [descriptorSet]);
                            commandBuffer.cmdBindVertexBuffers(0, [vertexBuffer.buffer], [0]);

                            record(geom, commandBuffer);
                        }
                    };
                    return tuple(result, register);
                }
            }
        }

        static typeof(this) getInstance(Window window, PrimitiveTopology prim) {
            auto key = tuple(window,prim);
            if (auto r = key in instance) {
                return *r;
            }
            assert(window, "window is not registered.");
            auto r = instance[key] = new typeof(this)(window, prim);
            VulkanContext.pushReleaseCallback({
                r.destroy();
                instance.remove(key);
            });
            return r;
        }

        this(Window window, PrimitiveTopology topology) {
            auto device = VulkanContext.device;

            initializeDescriptor(device);

            PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
                setLayouts: [descriptorSetLayout]
            };
            this.pipelineLayout = new PipelineLayout(device, pipelineLayoutCreateInfo);

            Pipeline.GraphicsCreateInfo pipelineCreateInfo = {
                vertexInputState: vertexInputState!(This),
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
                rasterizationState: rasterizationState,
                multisampleState: multisampleState,
                depthStencilState: depthStencilState,
                colorBlendState: colorBlendState,
                layout: pipelineLayout,
                renderPass: StandardRenderPass(window),
                subpass: 0,
            };

            static foreach (f; getSymbolsByUDA!(typeof(this), stages)) {
                pipelineCreateInfo.stages ~= f(device);
            }
            assert(pipelineCreateInfo.stages.length > 0);
            this.pipeline = Pipeline.create(device, [pipelineCreateInfo])[0];
        }

        static class DataSet {
            mixin ImplResourceStack;
            mixin ImplReleaseOwn;
            mixin DefineInstanceMembers!(This);

            ~this() {
                destroyStack();
            }

            alias Vertex = getSymbolsByUDA!(This, vertex)[0];
            alias Index = uint;

            private @own {
                VBuffer!Vertex vertexBuffer;
                VBuffer!Index indexBuffer;
                DescriptorSet descriptorSet;
            }

            this(Geometry)(Geometry geom) {
                this.vertexBuffer = new VBuffer!Vertex(geom.vertexList.map!((vIn) {
                    Vertex v;
                    static foreach (mem; __traits(allMembers, Vertex)) {
                        static if (!isCallable!(__traits(getMember, Vertex, mem))) {
                            __traits(getMember, v, mem) = __traits(getMember, vIn, mem);
                        }
                    }
                    return v;
                }).array, BufferUsage.VertexBuffer);

                static if (Geometry.hasIndex) {
                    this.indexBuffer = new VBuffer!Index(geom.indexList, BufferUsage.IndexBuffer);
                }
                initializeDefinedBuffers();
            }

            void initializeDescriptorSet(DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
                this.descriptorSet = createDescriptorSet(VulkanContext.device, descriptorPool, descriptorSetLayout);
            }

            void record(Geometry)(Geometry geom, CommandBuffer commandBuffer) {
                bool indexBound = false;
                static if (Geometry.hasIndex) {
                    assert(this.indexBuffer);
                    if (this.indexBuffer) {
                        cmdBindIndexBuffer(commandBuffer);
                        commandBuffer.cmdDrawIndexed(cast(uint)geom.indexList.length, 1, 0, 0, 0);
                        indexBound = true;
                    }
                }
                if (!indexBound) {
                    commandBuffer.cmdDraw(cast(uint)geom.vertexList.length, 1, 0, 0);
                }
            }

            private void cmdBindIndexBuffer(CommandBuffer commandBuffer) {
                static if (is(Index == ubyte)) {
                    enum indexType = IndexType.Uint8;
                } else static if (is(Index == ushort)) {
                    enum indexType = IndexType.Uint16;
                } else static if (is(Index == uint)) {
                    enum indexType = IndexType.Uint32;
                } else {
                    static assert(false, "Invalid index type: " ~ Index.stringof);
                }
                commandBuffer.cmdBindIndexBuffer(indexBuffer.buffer, 0, indexType);
            }
        }
    }

    protected VkVertexInputAttributeDescription[] createVertexAttributeDescriptions(Vertex)(uint binding) {
        VkVertexInputAttributeDescription[] result;

        uint location = 0;
        static foreach (name; __traits(allMembers, Vertex)) {
            {
                static if (!isCallable!(__traits(getMember, Vertex, name))) {
                    VkVertexInputAttributeDescription description = {
                        binding: binding,
                        location: location++,
                        format: getFormat!(typeof(__traits(getMember, Vertex, name))),
                        offset: __traits(getMember, Vertex, name).offsetof
                    };
                    result ~= description;
                }
            }
        }

        return result;
    }

    protected template getFormat(Type) {
        static if (is(Type == float)) {
            enum getFormat = VK_FORMAT_R32_SFLOAT;
        } else static if (is(Type == vec2)) {
            enum getFormat = VK_FORMAT_R32G32_SFLOAT;
        } else static if (is(Type == vec3)) {
            enum getFormat = VK_FORMAT_R32G32B32_SFLOAT;
        } else static if (is(Type == vec4)) {
            enum getFormat = VK_FORMAT_R32G32B32A32_SFLOAT;
        } else static if (is(Type == int)) {
            enum getFormat = VK_FORMAT_R32_SINT;
        } else static if (is(Type == ivec2)) {
            enum getFormat = VK_FORMAT_R32G32_SINT;
        } else static if (is(Type == ivec3)) {
            enum getFormat = VK_FORMAT_R32G32B32_SINT;
        } else static if (is(Type == ivec4)) {
            enum getFormat = VK_FORMAT_R32G32B32A32_SINT;
        } else {
            static assert(false, "Unsupported type: " ~ Type.stringof);
        }
    }

    protected Pipeline.VertexInputStateCreateInfo vertexInputState(This)() {
        alias Vertex = getSymbolsByUDA!(This, vertex)[0];
        Pipeline.VertexInputStateCreateInfo result = {
            vertexBindingDescriptions: [{
                stride: Vertex.sizeof,
                inputRate: VertexInputRate.Vertex
            }],
            vertexAttributeDescriptions: createVertexAttributeDescriptions!(Vertex)(0)
        };
        return result;
    }
}
