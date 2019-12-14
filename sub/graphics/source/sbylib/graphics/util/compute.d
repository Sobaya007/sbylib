module sbylib.graphics.util.compute;

import std;
import erupted;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;
import sbylib.math;

import sbylib.graphics.util.buffer;
import sbylib.graphics.util.uniformreference;
import sbylib.graphics.util.own;

mixin template Compute() {
    import sbylib.graphics.util.computecontext;
    import sbylib.graphics.util.own;
    import sbylib.graphics.util.pipelineutil;
    import sbylib.graphics.util.vulkancontext;
    import sbylib.wrapper.vulkan;

    @own {
        private {
            ShaderModule shader;
            Pipeline pipeline;
            DescriptorSetLayout descriptorSetLayout;
            PipelineLayout pipelineLayout;
            DescriptorPool descriptorPool;
        }
        public {
            CommandBuffer commandBuffer;
            Fence fence;
        }
    }

    private __gshared typeof(this) instance;

    static opCall() {
        if (instance) return instance;
        return instance = new typeof(this);
    }

    static void deinitialize() {
        if (instance) {
            instance.destroy();
        }
    }

    mixin ImplReleaseOwn;

    private mixin ImplPipelineUtil!(typeof(this)) P;

    private void initialize(string code) {
        P.initialize(VulkanContext.device, 10);

        this.shader = P.createStage(VulkanContext.device, ShaderStage.Compute, code);

        Pipeline.ComputeCreateInfo pipelineCreateInfo = {
            stage: {
                stage: ShaderStage.Compute,
                pName: "main",
                _module: shader
            },
            layout: pipelineLayout,
        };
        this.pipeline = Pipeline.create(VulkanContext.device, [pipelineCreateInfo])[0];

        this.commandBuffer = ComputeContext.createCommandBuffer(CommandBufferLevel.Primary, 1)[0];

        this.fence = VulkanContext.createFence("compute shader fence");
    }

    mixin DataSet;
    mixin ImplDescriptorSet;

    mixin template UseBuffer(Type, string name = "buffer") {
        mixin(q{
            private @stage(ShaderStage.Compute) @own VBuffer!Type _${name};

            protected void initialize(string mem : "${name}")(size_t size, BufferUsage usage) {
                this._${name} = new VBuffer!Type(size, usage, MemoryProperties.MemoryType.Flags.HostVisible);
            }
 
            UniformReference!(Type) ${name}() {
                return typeof(return)(_${name}.memory);
            }
        }.replace("${name}", name));
    }

    void record(int x, int y, int z) {
        CommandBuffer.BeginInfo beginInfo;
        this.commandBuffer.begin(beginInfo);
        this.commandBuffer.cmdBindPipeline(PipelineBindPoint.Compute, pipeline);
        this.commandBuffer.cmdBindDescriptorSets(PipelineBindPoint.Compute, pipelineLayout, 0, [descriptorSet]);
        this.commandBuffer.cmdDispatch(x, y, z);
        this.commandBuffer.end();
    }
}
