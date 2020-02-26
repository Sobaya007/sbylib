module sbylib.graphics.material.standard.renderpass;

import std;
import erupted;
import sbylib.wrapper.glfw : Window;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.commandbuffer;
import sbylib.graphics.util.fence;
import sbylib.graphics.util.rendercontext;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;

class StandardRenderPass : RenderPass {

    private Window window;

    @own {
        private {
            ImageView[] colorImageViews;
            Image depthImage;
            DeviceMemory depthImageMemory;
            VFence submitFence;
        }

        public {
            Framebuffer[] framebuffers;
            VCommandBuffer[] commandBuffers;
            ImageView depthImageView;
        }
    }

    private void delegate(CommandBuffer)[] renderList;
    private bool submitted;

    mixin ImplReleaseOwn;

    private static typeof(this)[Window] instance;

    static opCall(Window window) {
        if (window !in instance) {
            with (RenderContext(window)) {
                instance[window] = new typeof(this)(swapchain.getImages(), window);
                RenderContext(window).pushReleaseCallback({ StandardRenderPass.deinitialize(window); });
            }
        }
        return instance[window];
    }

    private static void deinitialize(Window window) {
        assert(window in instance, "this window is not registered one.");
        instance[window].destroy();
        instance.remove(window);
    }

    private this(Image[] colorImages, Window window) {
        this.window = window;

        RenderPass.CreateInfo renderPassCreateInfo = {
            attachments: [{
                format: VK_FORMAT_B8G8R8A8_UNORM,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Clear,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.PresentSrc,
            }, {
                format: VK_FORMAT_D32_SFLOAT,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Clear,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.DepthStencilAttachmentOptimal,
            }],
            subpasses: [{
                pipelineBindPoint: PipelineBindPoint.Graphics,
                colorAttachments: [{
                    attachment: 0,
                    layout: ImageLayout.ColorAttachmentOptimal
                }],
                depthStencilAttachments: [{
                    attachment: 1,
                    layout: ImageLayout.DepthStencilAttachmentOptimal
                }]
            }]
        };
        super(VulkanContext.device, renderPassCreateInfo);

        this.colorImageViews = colorImages.map!(
                im => createImageView(im, VK_FORMAT_B8G8R8A8_UNORM, ImageAspect.Color)).array;
        this.depthImage = createImage(window, VK_FORMAT_D32_SFLOAT);
        this.depthImageMemory = createMemory(depthImage, ImageLayout.DepthStencilAttachmentOptimal, ImageAspect.Depth);
        this.depthImageView = createImageView(depthImage, VK_FORMAT_D32_SFLOAT, ImageAspect.Depth);
        this.framebuffers = colorImageViews.map!(iv => createFramebuffer(window, iv, depthImageView)).array;
        this.commandBuffers = VCommandBuffer.allocate(QueueFamilyProperties.Flags.Graphics, CommandBufferLevel.Primary, cast(uint)framebuffers.length);
        foreach (cb; this.commandBuffers)
            cb.name = "standard renderpass";
        this.submitFence = VulkanContext.createFence("standard renderpass submission fence");
        RenderContext(window).pushPresentFence(submitFence);

        updateCommandBuffers();

        VulkanContext.pushResource(this);
    }

    private Image createImage(Window window, VkFormat format) {
        Image.CreateInfo imageInfo = {
            imageType: ImageType.Type2D,
            extent: {
                width: window.width,
                height: window.height,
                depth: 1
            },
            mipLevels: 1,
            arrayLayers: 1,
            format: format,
            tiling: ImageTiling.Optimal,
            initialLayout: ImageLayout.Undefined,
            usage: ImageUsage.DepthStencilAttachment,
            sharingMode: SharingMode.Exclusive,
            samples: SampleCount.Count1
        };
        auto result = new Image(VulkanContext.device, imageInfo);
        return result;
    }

    private DeviceMemory createMemory(Image image, ImageLayout layout, ImageAspect aspect) {
        with (VulkanContext) {
            auto result = image.allocateMemory(gpu, MemoryProperties.MemoryType.Flags.DeviceLocal);
            result.bindImage(image, 0);
            transitionImage(depthImage, ImageLayout.Undefined, layout, aspect);
            return result;
        }
    }

    private ImageView createImageView(Image image, VkFormat format, ImageAspect aspectMask) {
        ImageView.CreateInfo info = {
           image: image,
           viewType: ImageViewType.Type2D,
           format: format,
           subresourceRange: {
               aspectMask: aspectMask,
               baseMipLevel: 0,
               levelCount: 1,
               baseArrayLayer: 0,
               layerCount: 1,
           }
        };
        return new ImageView(VulkanContext.device, info);
    }

    private Framebuffer createFramebuffer(Window window, ImageView colorImage, ImageView depthImage) {
        Framebuffer.CreateInfo info = {
            renderPass: this,
            attachments: [colorImage, depthImage],
            width: window.width,
            height: window.height,
            layers: 1,
        };
        return new Framebuffer(VulkanContext.device, info);
    }

    private void transitionImage(Image image, ImageLayout oldLayout, ImageLayout newLayout, ImageAspect aspectMask) {
        auto commandBuffer = VCommandBuffer.allocate(QueueFamilyProperties.Flags.Graphics);
        scope (exit)
            commandBuffer.destroy();

        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            VkImageMemoryBarrier barrier = {
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: oldLayout,
                newLayout: newLayout,
                image: image.image,
                subresourceRange: {
                    aspectMask: aspectMask,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.Transfer, 0, [], [], [barrier]);
        }

        VulkanContext.graphicsQueue.submit(commandBuffer);
        VulkanContext.graphicsQueue.waitIdle();
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

    void submitRender() {
        submitFence.reset();
        auto currentImageIndex = RenderContext(window).getImageIndex();

        VulkanContext.graphicsQueue.submitWithFence(commandBuffers[currentImageIndex], submitFence);
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
}
