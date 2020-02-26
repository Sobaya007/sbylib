module sbylib.graphics.wrapper.renderpass;

public import erupted;
public import sbylib.wrapper.glfw : Window;
public import sbylib.wrapper.vulkan;
public import sbylib.graphics.wrapper;
import std;
import sbylib.graphics.util.own;
import sbylib.graphics.core.presenter;

class VRenderPass : RenderPass {

    mixin template ImplOpCall() {
        private static typeof(this)[Window] instance;

        static opCall(Window window) {
            if (window !in instance) {
                instance[window] = new typeof(this)(window);
                VDevice().pushReleaseCallback({ deinitialize(window); });
            }
            return instance[window];
        }

        private static void deinitialize(Window window) {
            assert(window in instance, "this window is not registered one.");
            instance[window].destroy();
            instance.remove(window);
        }
    }

    mixin template Info(RenderPass.CreateInfo info_) {
        protected override RenderPass.CreateInfo info() {
            return info_;
        }
    }

    protected abstract RenderPass.CreateInfo info();

    private {
        Window window;
        void delegate(CommandBuffer)[] renderList;
        bool submitted;

        @own {
            Framebuffer[] framebuffers;
            VCommandBuffer[] commandBuffers;
            VFence submitFence;
        }
    }
    mixin ImplReleaseOwn;

    private this(Window window) {
        super(VDevice(), info);
        this.window = window;
    }

    protected void registerFrameBuffers(Framebuffer[] framebuffers) {
        this.framebuffers = framebuffers;
        this.commandBuffers = VCommandBuffer.allocate(VCommandBuffer.Type.Graphics, CommandBufferLevel.Primary, cast(uint)framebuffers.length);
        this.submitFence = VFence.create("standard renderpass submission fence");
        Presenter(window).pushPresentFence(submitFence);
        updateCommandBuffers();
        VDevice().pushResource(this);
    }

    void submitRender() {
        submitFence.reset();
        auto currentImageIndex = Presenter(window).getImageIndex();

        VQueue(VQueue.Type.Graphics).submitWithFence(commandBuffers[currentImageIndex], submitFence);
        submitted = true;
    }

    auto register(void delegate(CommandBuffer) render) {
        this.renderList ~= render;
        updateCommandBuffers();
        return { unregister(render); };
    }

    void unregister(void delegate(CommandBuffer) render) {
        this.renderList = this.renderList.remove!(r => r == render);
        updateCommandBuffers();
    }

    private void updateCommandBuffers() {
        if (submitted && submitFence.signaled is false) {
            Fence.wait([submitFence], true, ulong.max);
            submitted = false;
        }
        enforce(!submitted || submitFence.signaled);

        foreach (cb, framebuffer; zip(commandBuffers, framebuffers)) {
            with (cb()) {
                CommandBuffer.RenderPassBeginInfo renderPassBeginInfo = {
                    renderPass: this,
                    framebuffer: framebuffer,
                    renderArea: { 
                        extent: VkExtent2D(window.width, window.height) 
                    },
                    clearValues: [{
                        color: {
                            float32: [0.0f, 0.0f, 0.0f, 1.0f]
                        },
                    }, {
                        depthStencil: {
                            depth: 1.0f
                        }
                    }]
                };
                cmdBeginRenderPass(renderPassBeginInfo, SubpassContents.Inline);

                foreach (r; this.renderList) {
                    r(commandBuffer);
                }

                cmdEndRenderPass();
            }
        }
    }
}
