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
            initializeDescriptor();

            PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
                setLayouts: [descriptorSetLayout]
            };
            this.pipelineLayout = new PipelineLayout(VDevice(), pipelineLayoutCreateInfo);

            Pipeline.ComputeCreateInfo pipelineCreateInfo = {
                stage: getSymbolsByUDA!(typeof(this), stages)[0](),
                layout: pipelineLayout,
            };

            this.pipeline = Pipeline.create(VDevice(), [pipelineCreateInfo])[0];
        }

        private static typeof(this) inst;

        static Inst opCall(VQueue queue = null) {
            if (queue is null) queue = VQueue(VQueue.Type.Compute);
            if (inst is null) {
                inst = new typeof(this);
                VDevice().pushResource(inst);
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
                this.descriptorSet = createDescriptorSet(descriptorPool, descriptorSetLayout);
                this.commandBuffer = VCommandBuffer.allocate(VCommandBuffer.Type.Compute);
            }

            auto dispatch(int[3] xyz) {
                record(xyz);
                auto fence = queue.submitWithFence(commandBuffer, "dispatch");
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

            auto dispatch(int[3] xyz, VFence fence) {
                record(xyz);
                struct Job {
                    VFence fence;

                    void wait() {
                        fence.wait();
                    }
                }
                return Job(fence);
            }

            private void record(int[3] xyz) {
                with (commandBuffer()) {
                    cmdBindPipeline(PipelineBindPoint.Compute, pipeline);
                    cmdBindDescriptorSets(PipelineBindPoint.Compute, pipelineLayout, 0, [descriptorSet]);
                    cmdDispatch(xyz[0], xyz[1], xyz[2]);
                }
            }
        }
    }
}
