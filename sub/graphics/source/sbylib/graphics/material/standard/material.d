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
    import sbylib.event;

    alias DataType = MaterialType.DataSet;
    DataType _data;
    alias _data this;
    private void delegate() delegate() _reregister;
    private void delegate() _unregister;

    this(Geometry)(Window window, Geometry geom) {
        constructor(window, geom);
    }

    void constructor(Geometry)(Window window, Geometry geom) {
        _data = new MaterialType.DataSet(geom);
        auto register = (CommandBuffer commandBuffer) {
            _data.record(geom, MaterialType.getInstance(window, geom.primitive), commandBuffer);
        };
        this._reregister = () => MaterialType.RenderPassType(window).register(register);
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

    struct CreateInfo {
        Pipeline.RasterizationStateCreateInfo rasterization;
        Pipeline.TessellationStateCreateInfo tessellation;
        Pipeline.MultisampleStateCreateInfo multisample;
        Pipeline.DepthStencilStateCreateInfo depthStencil;
        Pipeline.ColorBlendStateCreateInfo colorBlend;
    }

    mixin template Info(CreateInfo info_) {
        private CreateInfo info () {
            return info_;
        }
    }

    mixin template RenderPass(RenderPassType_) {
        alias RenderPassType = RenderPassType_;
    }

    mixin template Instance() {
        import sbylib.graphics.core;
        import sbylib.graphics.util;
        import sbylib.graphics.wrapper;
        import sbylib.wrapper.glfw : Window;
        alias This = typeof(this);

        mixin ImplDescriptor;

        private static typeof(this)[Tuple!(Window,PrimitiveTopology)] instance;

        static typeof(this) getInstance(Window window, PrimitiveTopology prim) {
            auto key = tuple(window,prim);
            if (auto r = key in instance) {
                return *r;
            }
            assert(window, "window is not registered.");
            auto r = instance[key] = new typeof(this)(window, prim);
            VDevice().pushReleaseCallback({
                r.destroy();
                instance.remove(key);
            });
            return r;
        }

        this(Window window, PrimitiveTopology topology) {
            initializeDescriptor();

            PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
                setLayouts: [descriptorSetLayout]
            };
            this.pipelineLayout = new PipelineLayout(VDevice(), pipelineLayoutCreateInfo);

            auto i = info();
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
                rasterizationState: i.rasterization,
                tessellationState: i.tessellation,
                multisampleState: i.multisample,
                depthStencilState: i.depthStencil,
                colorBlendState: i.colorBlend,
                layout: pipelineLayout,
                renderPass: RenderPassType(window),
                subpass: 0,
            };

            static foreach (f; getSymbolsByUDA!(typeof(this), stages)) {
                pipelineCreateInfo.stages ~= f();
            }
            assert(pipelineCreateInfo.stages.length > 0);
            this.pipeline = Pipeline.create(VDevice(), [pipelineCreateInfo])[0];
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

            public @own {
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
                this.descriptorSet = createDescriptorSet(descriptorPool, descriptorSetLayout);
            }

            void record(Geometry)(Geometry geom, Material inst, CommandBuffer commandBuffer) {
                if (!descriptorSet) initializeDescriptorSet(inst.descriptorPool, inst.descriptorSetLayout);
                commandBuffer.cmdBindPipeline(PipelineBindPoint.Graphics, inst.pipeline);
                commandBuffer.cmdBindDescriptorSets(PipelineBindPoint.Graphics, inst.pipelineLayout, 0, [descriptorSet]);
                commandBuffer.cmdBindVertexBuffers(0, [vertexBuffer.buffer], [0]);

                bool indexBound = false;
                static if (Geometry.hasIndex) {
                    assert(this.indexBuffer);
                    commandBuffer.cmdBindIndexBuffer(indexBuffer.buffer, 0, indexType);
                    commandBuffer.cmdDrawIndexed(cast(uint)geom.indexList.length, 1, 0, 0, 0);
                    indexBound = true;
                } else {
                    commandBuffer.cmdDraw(cast(uint)geom.vertexList.length, 1, 0, 0);
                }
            }

            static if (is(Index == ubyte)) {
                enum indexType = IndexType.Uint8;
            } else static if (is(Index == ushort)) {
                enum indexType = IndexType.Uint16;
            } else static if (is(Index == uint)) {
                enum indexType = IndexType.Uint32;
            } else {
                static assert(false, "Invalid index type: " ~ Index.stringof);
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
