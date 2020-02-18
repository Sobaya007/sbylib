module sbylib.graphics.material.standard.material2;

import std;
import erupted;
import sbylib.math;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.shader;
import sbylib.graphics.util.uniformreference;
import sbylib.graphics.util.vulkancontext;

class Material2 {

    enum stages;
    enum uniform;
    struct binding { int binding; }
    struct stage { ShaderStage stage; }
    struct type { DescriptorType type; }

    protected @own {
        DescriptorSetLayout descriptorSetLayout;
        PipelineLayout pipelineLayout;
        DescriptorPool descriptorPool;
        Pipeline pipeline;
    }

    mixin template VertexShaderSource(string code) {
        private @stages Pipeline.ShaderStageCreateInfo vertexShaderModule() {
            return createStage(ShaderStage.Vertex, code);
        }
    }

    mixin template FragmentShaderSource(string code) {
        private @stages Pipeline.ShaderStageCreateInfo fragmentShaderSource() {
            return createStage(ShaderStage.Fragment, code);
        }
    }

    mixin template VertexType(Vertex) {
        private alias VT = Vertex;
        private Pipeline.VertexInputStateCreateInfo vertexInputState() {
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

    mixin template MaxObjects(size_t n) {
        private enum maxObjects = n;
    }

    static foreach (ShaderStage ss; EnumMembers!ShaderStage) {
        mixin template Uniform(ShaderStage st : ss, UniformType) {
            private static @uniform @stage(ss) mixin(format!q{UniformType uni%s;}(st));
        }
    }

    mixin template Instance() {
        import sbylib.graphics.util.functions : ImplResourceStack;
        alias This = typeof(this);

        this(Window window, PrimitiveTopology topology) {
            auto device = VulkanContext.device;

            auto descriptorSetLayoutInfo = createDescriptorSetCreateInfo();
            this.descriptorSetLayout = new DescriptorSetLayout(device, descriptorSetLayoutInfo);

            PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
                setLayouts: [descriptorSetLayout]
            };
            this.pipelineLayout = new PipelineLayout(device, pipelineLayoutCreateInfo);

            DescriptorPool.CreateInfo.DescriptorPoolSize[] poolSizes = descriptorSetLayoutInfo.bindings.map!((binding) {
                DescriptorPool.CreateInfo.DescriptorPoolSize size = {
                    type: binding.descriptorType,
                    descriptorCount: maxObjects
                };
                return size;
            }).array;
            DescriptorPool.CreateInfo descriptorPoolInfo = {
                poolSizes: poolSizes,
                maxSets: maxObjects
            };
            this.descriptorPool = new DescriptorPool(device, descriptorPoolInfo);

            Pipeline.GraphicsCreateInfo pipelineCreateInfo = {
                stages: [getSymbolsByUDA!(typeof(this), stages)],
                vertexInputState: vertexInputState,
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
            this.pipeline = Pipeline.create(VulkanContext.device, [pipelineCreateInfo])[0];
        }

        static class DataSet {
            mixin ImplResourceStack;
            mixin ImplReleaseOwn;

            ~this() {
                destroyStack();
            }

            /*
               Define uniforms
            */
            private @own @type(DescriptorType.UniformBuffer) {
                static foreach (mem; getSymbolsByUDA!(This, uniform)) {
                    enum ss = getUDAs!(mem, stage)[0];
                    alias UniformType = typeof(mem);

                    @ss mixin(format!q{VBuffer!UniformType buffer%s;}(ss));
                    alias m = mixin(format!q{buffer%s}(ss));

                    UniformReference!(typeof(mem)) uniform(ShaderStage stage : ss)() {
                        return typeof(return)(m.memory);
                    }
                }
            }

            /* Define Vertex Buffer */
            private @own VBuffer!VT vertexBuffer;

            /* Define Index Buffer */
            alias Index = uint;
            private @own VBuffer!Index indexBuffer;

            /* Define DescriptorSet */
            private @own DescriptorSet descriptorSet;

            this(Geometry)(Geometry geom, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
                this.vertexBuffer = new VBuffer!VT(geom.vertexList.map!((vIn) {
                    Vertex v;
                    static foreach (mem; __traits(allMembers, VT)) {
                        static if (!isCallable!(__traits(getMember, VT, mem))) {
                            __traits(getMember, v, mem) = __traits(getMember, vIn, mem);
                        }
                    }
                    return v;
                }).array, BufferUsage.VertexBuffer);

                static assert(Geometry.hasIndex);
                this.indexBuffer = new VBuffer!Index(geom.indexList, BufferUsage.IndexBuffer);

                static foreach (mem; getSymbolsByUDA!(typeof(this), stage)) {
                    mem = new typeof(mem)([typeof(mem).Type.init], BufferUsage.UniformBuffer);
                }
                    
                DescriptorSet.AllocateInfo descriptorSetAllocInfo = {
                    descriptorPool: pool,
                    setLayouts: [layout]
                };
                this.descriptorSet = DescriptorSet.allocate(device, descriptorSetAllocInfo)[0];

                enum pred(alias m) = isAggregateType!(typeof(m));
                alias Symbols = Filter!(pred, getSymbolsByUDA!(typeof(this), binding));
                enum N = Symbols.length;

                DescriptorSet.Write[N] writes;
                static foreach (i; 0..N) {{
                    alias mem = Symbols[i];

                    assert(mem, mem.stringof ~ " is not set.");

                    static if (is(typeof(mem) == VBuffer!(U), U)) {
                        assert(mem.buffer);
                        DescriptorSet.Write w = {
                            dstSet: descriptorSet,
                            dstBinding: getUDAs!(mem, binding)[0].binding,
                            dstArrayElement: 0,
                            descriptorType: getUDAs!(mem, type)[0].type,
                            bufferInfo: [{
                                buffer: mem.buffer,
                                offset: 0,
                                range: U.sizeof
                            }]
                        };
                        writes[i] = w;
                    } else static if (is(typeof(mem) == Texture)) {
                        assert(mem.sampler);
                        assert(mem.imageView);
                        DescriptorSet.Write w = {
                            dstSet: descriptorSet,
                            dstBinding: getUDAs!(mem, binding)[0].binding,
                            dstArrayElement: 0,
                            descriptorType: getUDAs!(mem, type)[0].type,
                            imageInfo: [{
                                sampler: mem.sampler,
                                imageView: mem.imageView,
                                imageLayout: ImageLayout.ShaderReadOnlyOptimal
                            }]
                        };
                        writes[i] = w;
                    } else {
                        static assert(false);
                    }
                }}
                DescriptorSet.Copy[0] copies;
                descriptorSet.update(writes, copies);
            }

            void record(Geometry)(Geometry geom, CommandBuffer commandBuffer) {
                bool indexBound = false;
                static if (__traits(hasMember, this, "indexBuffer") && Geometry.hasIndex) {
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

    protected Pipeline.ShaderStageCreateInfo createStage(ShaderStage stage, string code) {
        auto mod = ShaderUtil.createModule(VulkanContext.device, stage, code);

        Pipeline.ShaderStageCreateInfo result = {
            stage: stage,
            pName: "main",
            _module: mod
        };
        return result;
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

    protected DescriptorSetLayout.CreateInfo createDescriptorSetCreateInfo() {
        enum pred(alias m) = isAggregateType!(typeof(m));
        alias Symbols = Filter!(pred, getSymbolsByUDA!(typeof(this), binding));
        enum N = Symbols.length;

        DescriptorSetLayout.CreateInfo.Binding[N] bindings;
        
        static foreach (i; 0..N) {{
            alias mem = Symbols[i];

            static if (is(typeof(mem) == VBuffer!(U), U)) {
                DescriptorSetLayout.CreateInfo.Binding b = {
                    binding: getUDAs!(mem, binding)[0].binding,
                    descriptorType: getUDAs!(mem, type)[0].type,
                    descriptorCount: 1,
                    stageFlags: getUDAs!(mem, stage)[0].stage
                };
                bindings[i] = b;
            } else static if (is(typeof(mem) == Texture)) {
                DescriptorSetLayout.CreateInfo.Binding b = {
                    binding: getUDAs!(mem, binding)[0].binding,
                    descriptorType: getUDAs!(mem, type)[0].type,
                    descriptorCount: 1,
                    stageFlags: getUDAs!(mem, stage)[0].stage
                };
                bindings[i] = b;
            } else {
                static assert(false);
            }
        }}

        DescriptorSetLayout.CreateInfo result = {
            bindings: bindings
        };

        return result;
    }
}
