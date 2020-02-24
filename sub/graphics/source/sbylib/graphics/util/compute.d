module sbylib.graphics.util.compute;

public import std;
public import sbylib.math;
public import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.util.descriptor;

class Compute {
    
    mixin Descriptor;

    protected @own {
        PipelineLayout pipelineLayout;
        Pipeline pipeline;
    }

    mixin ImplReleaseOwn;

    mixin template Instance() {
        import std : getSymbolsByUDA;
        import sbylib.wrapper.vulkan;
        import sbylib.graphics.util;

        alias This = typeof(this);

        mixin ImplDescriptor;

        this() {
            auto device = VulkanContext.device;

            initializeDescriptor(device);

            PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
                setLayouts: [descriptorSetLayout]
            };
            this.pipelineLayout = new PipelineLayout(device, pipelineLayoutCreateInfo);

            Pipeline.ComputeCreateInfo pipelineCreateInfo = {
                stage: getSymbolsByUDA!(typeof(this), stages)[0](device),
                layout: pipelineLayout,
            };

            this.pipeline = Pipeline.create(device, [pipelineCreateInfo])[0];
        }

        private static typeof(this) inst;

        static Inst opCall(Queue queue = null) {
            if (queue is null) queue = ComputeContext.queue;
            if (inst is null) {
                inst = new typeof(this);
                ComputeContext.pushResource(inst);
            }
            return Inst(queue, inst.pipeline, inst.pipelineLayout, inst.descriptorPool, inst.descriptorSetLayout);
        }

        static struct Inst {
            mixin ImplReleaseOwn;
            mixin DefineInstanceMembers!(This);

            private @own {
                DescriptorSet descriptorSet;
                CommandBuffer commandBuffer;
            }
            private Pipeline pipeline;
            private PipelineLayout pipelineLayout;
            private Queue queue;

            this(Queue queue, Pipeline pipeline, PipelineLayout pipelineLayout, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
                this.queue = queue;
                this.pipeline = pipeline;
                this.pipelineLayout = pipelineLayout;
                initializeDefinedBuffers();
                this.descriptorSet = createDescriptorSet(VulkanContext.device, descriptorPool, descriptorSetLayout);
                this.commandBuffer = ComputeContext.createCommandBuffer(CommandBufferLevel.Primary, 1)[0];
            }

            auto dispatch(int x, int y, int z) {
                with (commandBuffer) {
                    CommandBuffer.BeginInfo beginInfo;
                    begin(beginInfo);
                    cmdBindPipeline(PipelineBindPoint.Compute, pipeline);
                    cmdBindDescriptorSets(PipelineBindPoint.Compute, pipelineLayout, 0, [descriptorSet]);
                    cmdDispatch(x, y, z);
                    end();
                }
                Queue.SubmitInfo submitInfo = {
                    commandBuffers: [commandBuffer]
                };

                auto fence = VulkanContext.createFence("fence for dispatch compute");
                queue.submit([submitInfo], fence);

                struct Job {
                    Fence fence;

                    ~this() {
                        fence.destroy();
                    }

                    void wait() {
                        Fence.wait([fence], true, ulong.max);
                    }
                }
                return Job(fence);
            }
        }
    }
}
