module sbylib.graphics.material.gbuffer.material;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.math;
import sbylib.graphics.util.buffer;
import sbylib.graphics.util.rendercontext;

mixin template ImplPreRenderer() {
    import sbylib.graphics.material.gbuffer.gbuffer;

    GBufferOutputMaterial.DataSet prerenderer;

    auto vertexUniform() {
        return prerenderer.vertexUniform;
    }
}

mixin template GBufferMaterial(DataSet) {
    import sbylib.graphics.material.standard.renderpass;
    import sbylib.graphics.material.gbuffer.renderpass;
    import sbylib.graphics.material.gbuffer.gbuffer;
    import sbylib.graphics.geometry.geometrylibrary;
    import sbylib.graphics.util.own;
    import sbylib.graphics.util.pipelineutil;
    import sbylib.graphics.util.vulkancontext;
    import sbylib.wrapper.vulkan;

    @own {
        DescriptorSetLayout descriptorSetLayout;
        PipelineLayout pipelineLayout;
        DescriptorPool descriptorPool;
    }

    mixin ImplReleaseOwn;
    private mixin ImplPipelineUtil!(DataSet) P;

    private static typeof(this)[Tuple!(Window)] instance;
    private static ReturnType!(GeometryLibrary.buildPlane) rect;

    static opCall(Window window) {
        return Builder(window);
    }

    package static typeof(this) getInstance(Window window) {
        auto key = tuple(window);
        if (auto r = key in instance) {
            return *r;
        }
        assert(window, "window is not registered.");

        rect = GeometryLibrary().buildPlane();
        auto r = instance[key] = new typeof(this)(window, rect.primitive);
        RenderContext(window).pushReleaseCallback({
            r.destroy();
            instance.remove(key);
        });
        return r;
    }

    private void initialize(int maxObjects) {
        P.initialize(VulkanContext.device, maxObjects);
    }
    
    private Pipeline.ShaderStageCreateInfo createStage(ShaderStage stage, ref ShaderModule[] shaders, string code) {

        auto mod = P.createStage(VulkanContext.device, stage, code);

        shaders ~= mod;

        Pipeline.ShaderStageCreateInfo result = {
            stage: stage,
            pName: "main",
            _module: mod
        };
        return result;
    }

    private VkVertexInputAttributeDescription[] createVertexAttributeDescriptions(Type)(uint binding) {
        VkVertexInputAttributeDescription[] result;

        uint location = 0;
        static foreach (name; __traits(allMembers, Type)) {
            {
                static if (!isCallable!(__traits(getMember, Type, name))) {
                    VkVertexInputAttributeDescription description = {
                        binding: binding,
                        location: location++,
                        format: getFormat!(typeof(__traits(getMember, Type, name))),
                        offset: __traits(getMember, Type, name).offsetof
                    };
                    result ~= description;
                }
            }
        }

        return result;
    }

    Pipeline.VertexInputStateCreateInfo getVertexInputState(Vertex)() {
        Pipeline.VertexInputStateCreateInfo result = {
            vertexBindingDescriptions: [{
                stride: Vertex.sizeof,
                inputRate: VertexInputRate.Vertex
            }],
            vertexAttributeDescriptions: createVertexAttributeDescriptions!(Vertex)(0)
        };
        return result;
    }

    struct Builder {
        Window window;

        public DataSet build(Geometry, Args...)(Geometry geom, Args args) {
            DataSet result;

            // GBufferを使って色をつける用
            with (getInstance(window)) {
                result = new DataSet(rect, descriptorPool, descriptorSetLayout, window, args);
                result.pushReleaseCallback(StandardRenderPass(window).register((CommandBuffer commandBuffer) {
                    with (result) {
                        commandBuffer.cmdBindPipeline(PipelineBindPoint.Graphics, pipeline);
                        commandBuffer.cmdBindDescriptorSets(PipelineBindPoint.Graphics, pipelineLayout, 0, [descriptorSet]);
                        commandBuffer.cmdBindVertexBuffers(0, [vertexBuffer.buffer], [0]);

                        record(geom, commandBuffer);
                    }
                }));
            }
            // GBufferを出力するマン
            with (GBufferOutputMaterial.getInstance(window, geom.primitive)) {
                auto tmp = new GBufferOutputMaterial.DataSet(geom, descriptorPool, descriptorSetLayout);

                tmp.pushReleaseCallback(GBufferRenderPass(window).register((CommandBuffer commandBuffer) {
                    with (tmp) {
                        commandBuffer.cmdBindPipeline(PipelineBindPoint.Graphics, pipeline);
                        commandBuffer.cmdBindDescriptorSets(PipelineBindPoint.Graphics, pipelineLayout, 0, [descriptorSet]);
                        commandBuffer.cmdBindVertexBuffers(0, [vertexBuffer.buffer], [0]);

                        record(geom, commandBuffer);
                    }
                }));
                result.pushResource(tmp);
                result.prerenderer = tmp;
            }
            return result;
        }
    }
}

mixin template GBufferDataSet() {
    import sbylib.graphics.util.pipelineutil : DataSet;
    import sbylib.graphics.util.functions : ImplResourceStack;

    mixin ImplResourceStack;

    ~this() {
        destroyStack();
    }

    mixin DataSet D;

    mixin template UseVertex(Vertex) {
        @own VBuffer!Vertex vertexBuffer;
        private void initializeVertexBuffer(Geometry)(Geometry geom) {
            this.vertexBuffer = new VBuffer!Vertex(geom.vertexList.map!((vIn) {
                Vertex v;
                static foreach (mem; __traits(allMembers, Vertex)) {
                    static if (!isCallable!(__traits(getMember, Vertex, mem))) {
                        __traits(getMember, v, mem) = __traits(getMember, vIn, mem);
                    }
                }
                return v;
            }).array, BufferUsage.VertexBuffer);
        }
    }

    mixin template UseIndex(Index) {
        @own VBuffer!Index indexBuffer;
        private void initializeIndexBuffer(Geometry)(Geometry geom) {
            static if (Geometry.hasIndex) {
                this.indexBuffer = new VBuffer!Index(geom.indexList, BufferUsage.IndexBuffer);
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

    mixin template ImplDescriptorSet() {
        mixin D.ImplDescriptorSet DS;

        void initializeDescriptorSet(DescriptorPool pool, DescriptorSetLayout layout) {
            DS.initializeDescriptorSet(VulkanContext.device, pool, layout);
        }
    }

    mixin template ImplRecord() {
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
    }
}
