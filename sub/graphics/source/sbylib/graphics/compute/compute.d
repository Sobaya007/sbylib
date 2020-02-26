module sbylib.graphics.compute.compute;

public import std;
public import sbylib.math;
public import sbylib.wrapper.vulkan;
import sbylib.graphics.core.descriptor;
import sbylib.graphics.util.own;

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
        import sbylib.graphics.core;
        import sbylib.graphics.util;
        import sbylib.graphics.wrapper;

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

        static Inst opCall(VQueue queue = null) {
            if (queue is null) queue = VulkanContext.computeQueue;
            if (inst is null) {
                inst = new typeof(this);
                VulkanContext.pushResource(inst);
            }
            return Inst(queue, inst.pipeline, inst.pipelineLayout, inst.descriptorPool, inst.descriptorSetLayout);
        }

        static struct Inst {
            mixin ImplReleaseOwn;
            mixin DefineInstanceMembers!(This);

            private @own {
                DescriptorSet descriptorSet;
                VCommandBuffer commandBuffer;
            }
            private Pipeline pipeline;
            private PipelineLayout pipelineLayout;
            private VQueue queue;

            this(VQueue queue, Pipeline pipeline, PipelineLayout pipelineLayout, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
                this.queue = queue;
                this.pipeline = pipeline;
                this.pipelineLayout = pipelineLayout;
                initializeDefinedBuffers();
                this.descriptorSet = createDescriptorSet(VulkanContext.device, descriptorPool, descriptorSetLayout);
                this.commandBuffer = VCommandBuffer.allocate(QueueFamilyProperties.Flags.Compute);
            }

            auto dispatch(int x, int y, int z) {
                with (commandBuffer()) {
                    cmdBindPipeline(PipelineBindPoint.Compute, pipeline);
                    cmdBindDescriptorSets(PipelineBindPoint.Compute, pipelineLayout, 0, [descriptorSet]);
                    cmdDispatch(x, y, z);
                }
                auto fence = queue.submitWithFence(commandBuffer);
                struct Job {
                    VFence fence;

                    ~this() {
                        if (!fence.signaled) wait();
                        fence.destroy();
                    }

                    void wait() {
                        fence.wait();
                    }
                }
                return Job(fence);
            }
        }
    }
}
