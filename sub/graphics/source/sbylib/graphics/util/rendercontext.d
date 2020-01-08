module sbylib.graphics.util.rendercontext;

import std;
import erupted;
import sbylib.event;
import sbylib.wrapper.glfw : Window;
import sbylib.wrapper.freeimage : FIImage = Image, FIImageType = ImageType;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.functions;
import sbylib.graphics.util.image;
import sbylib.graphics.util.vulkancontext;

class RenderContext {

    static {
        private typeof(this)[Window] inst;

        auto opCall(Window window) {
            if (window !in inst) {
                auto r = inst[window] = new typeof(this)(window);
                VulkanContext.pushReleaseCallback({
                    r.destroy();
                    inst.remove(window);
                });
                return r;
            }
            return inst[window];
        }

        Queue queue;
        CommandPool commandPool;

        mixin ImplResourceStack;

        package void initialize() {
            with (VulkanContext) {
                this.queue = device.getQueue(graphicsQueueFamilyIndex, 0);
                this.commandPool = pushResource(createCommandPool(graphicsQueueFamilyIndex));
            }

            this.commandPool.name = "CommandPool of RenderContext";
        }

        package void deinitialize() {
            destroyStack();
        }

        CommandBuffer[] createCommandBuffer(CommandBufferLevel level, int commandBufferCount) {
            CommandBuffer.AllocateInfo commandbufferAllocInfo = {
                commandPool: commandPool,
                level: level,
                commandBufferCount: commandBufferCount,
            };
            return CommandBuffer.allocate(VulkanContext.device, commandbufferAllocInfo);
        }
    }

    Surface surface;
    Swapchain swapchain;
    ImageView[] imageViews;
    private Fence imageIndexAcquireFence;
    private int currentImageIndex;
    private Fence[] presentFences;
    private Window win;
    private size_t width, height;
    private VkFormat swapchainFormat;

    private this(Window window) {
        with (VulkanContext) {
            this.win = window;
            this.surface = window.createSurface(instance);
            this.swapchain = createSwapchain(surface);
            this.imageIndexAcquireFence = createFence("image index acquire fence");
            this.presentFences = [imageIndexAcquireFence];
            this.currentImageIndex = -1;
        }
        when(Frame(91)).then({
            RenderContext(window).present();
        });
    }

    ~this() {
        if (currentImageIndex != -1) {
            Fence.wait([imageIndexAcquireFence], true, ulong.max);
        }
        this.swapchain.destroy();
        this.surface.destroy();
        this.imageIndexAcquireFence.destroy();
    }

private:

    Swapchain createSwapchain(Surface surface) {
        import erupted : VK_FORMAT_B8G8R8A8_UNORM;

        with (VulkanContext) {
            enforce(gpu.getSurfaceSupport(surface));
            const surfaceCapabilities = gpu.getSurfaceCapabilities(surface);

            const surfaceFormats = gpu.getSurfaceFormats(surface);
            const surfaceFormat = surfaceFormats.find!(f => f.format == VK_FORMAT_B8G8R8A8_UNORM).front;
            this.swapchainFormat = surfaceFormat.format;

            Swapchain.CreateInfo swapchainCreateInfo = {
                surface: surface,
                minImageCount: surfaceCapabilities.minImageCount,
                imageFormat: surfaceFormat.format,
                imageColorSpace: surfaceFormat.colorSpace,
                imageExtent: surfaceCapabilities.currentExtent,
                imageArrayLayers: 1,
                imageUsage: ImageUsage.ColorAttachment | ImageUsage.TransferSrc, // for screenshot
                imageSharingMode: SharingMode.Exclusive,
                compositeAlpha: CompositeAlpha.Opaque,
                preTransform: SurfaceTransform.Identity,
                presentMode: PresentMode.FIFO,
                clipped: true,
            };
            enforce(surfaceCapabilities.supports(swapchainCreateInfo.imageUsage));
            enforce(surfaceCapabilities.supports(swapchainCreateInfo.compositeAlpha));
            enforce(surfaceCapabilities.supports(swapchainCreateInfo.preTransform));
            enforce(gpu.getSurfacePresentModes(surface).canFind(swapchainCreateInfo.presentMode));

            return pushResource(new Swapchain(device, swapchainCreateInfo));
        }
    }

    public uint acquireNextImageIndex(Fence fence) 
        in (swapchain !is null)
    {
        return swapchain.acquireNextImageIndex(ulong.max, null, fence);
    }

    public void present() 
        in (currentImageIndex != -1)
    {
        Fence.wait(presentFences, true, ulong.max);
        Queue.PresentInfo presentInfo = {
            swapchains: [swapchain],
            imageIndices: [currentImageIndex]
        };
        queue.present(presentInfo);
        Fence.reset([imageIndexAcquireFence]);
        currentImageIndex = acquireNextImageIndex(imageIndexAcquireFence);
    }

    public void pushPresentFence(Fence fence) {
        this.presentFences ~= fence;
    }

    public int getImageIndex() {
        if (currentImageIndex == -1) {
            Fence.reset([imageIndexAcquireFence]);
            return currentImageIndex = acquireNextImageIndex(imageIndexAcquireFence);
        }
        return currentImageIndex;
    }

    public void screenShot(string filename) {
        with (VulkanContext) {
            auto width = win.width;
            auto height = win.height;
            auto dstFormat = VK_FORMAT_R8G8B8A8_UNORM;

            // Check if the device supports blitting from optimal images (the swapchain images are in optimal format)
            bool supportsBlit =
                   gpu.getFormatProperties(swapchainFormat).optimalTiling.supports(FormatProperties.Flags.BlitSrc)
                && gpu.getFormatProperties(dstFormat).linearTiling.supports(FormatProperties.Flags.BlitDst);

            // Source for the copy is the last rendered swapchain image
            auto srcImage = swapchain.getImages()[currentImageIndex];

            // Create the linear tiled destination image to copy to and to read the memory from
            // Note that vkCmdBlitImage (if supported) will also do format conversions if the swapchain color format would differ
            Image.CreateInfo imageCreateCI = {
                imageType: ImageType.Type2D,
                format: dstFormat,
                extent: {
                    width: width,
                    height: height,
                    depth: 1,
                },
                arrayLayers: 1,
                mipLevels: 1,
                initialLayout: ImageLayout.Undefined,
                samples: SampleCount.Count1,
                tiling: ImageTiling.Linear,
                usage: ImageUsage.TransferDst,
            };
            // Create the image
            auto dstImage = new VImage(new Image(device, imageCreateCI), 
                  MemoryProperties.MemoryType.Flags.HostVisible
                | MemoryProperties.MemoryType.Flags.HostCoherent);
            scope (exit) dstImage.destroy();

            // Do the actual blit from the swapchain image to our host visible destination image
            auto copyCmd = createCommandBuffer(CommandBufferLevel.Primary, 1).front;
            scope (exit) copyCmd.destroy();

            copyCmd.begin(CommandBuffer.BeginInfo.Flags.OneTimeSubmit);

            // Transition destination image to transfer destination layout
            VkImageMemoryBarrier barrier0 = {
                srcAccessMask: 0,
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.TransferDstOptimal,
                image: dstImage.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            copyCmd.cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.Transfer, 0, null, null, [barrier0]);

            // Transition swapchain image from present to transfer source layout
            VkImageMemoryBarrier barrier1 = {
                srcAccessMask: AccessFlags.MemoryRead,
                dstAccessMask: AccessFlags.TransferRead,
                oldLayout: ImageLayout.PresentSrc,
                newLayout: ImageLayout.TransferSrcOptimal,
                image: srcImage.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            copyCmd.cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.Transfer, 0, null, null, [barrier1]);

            // If source and destination support blit we'll blit as this also does automatic format conversion (e.g. from BGR to RGB)
            if (supportsBlit) {
                // Define the region to blit (we will blit the whole swapchain image)
                VkImageBlit imageBlitRegion = {
                    srcSubresource: {
                        aspectMask: ImageAspect.Color,
                        layerCount: 1,
                    },
                    dstSubresource: {
                        aspectMask: ImageAspect.Color,
                        layerCount: 1,
                    },
                    srcOffsets: [{}, {
                        x: width,
                        y: height,
                        z: 1,
                    }],
                    dstOffsets: [{}, {
                        x: width,
                        y: height,
                        z: 1,
                    }],
                };

                // Issue the blit command
                copyCmd.cmdBlitImage(
                    srcImage, ImageLayout.TransferSrcOptimal,
                    dstImage.image, ImageLayout.TransferDstOptimal,
                    [imageBlitRegion], SamplerFilter.Nearest);
            } else {
                // Otherwise use image copy (requires us to manually flip components)
                VkImageCopy imageCopyRegion = {
                    srcSubresource: {
                        aspectMask: ImageAspect.Color,
                        layerCount: 1,
                    },
                    dstSubresource: {
                        aspectMask: ImageAspect.Color,
                        layerCount: 1,
                    },
                    extent: {
                        width: width,
                        height: height,
                        depth: 1,
                    }
                };

                // Issue the copy command
                copyCmd.cmdCopyImage(
                    srcImage, ImageLayout.TransferSrcOptimal,
                    dstImage.image, ImageLayout.TransferDstOptimal,
                    [imageCopyRegion]);
            }

            // Transition destination image to general layout, which is the required layout for mapping the image memory later on
            VkImageMemoryBarrier barrier2 = {
                srcAccessMask: AccessFlags.TransferWrite,
                dstAccessMask: AccessFlags.MemoryRead,
                oldLayout: ImageLayout.TransferDstOptimal,
                newLayout: ImageLayout.General,
                image: dstImage.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            copyCmd.cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.Transfer, 0, null, null, [barrier2]);

            // Transition back the swap chain image after the blit is done
            VkImageMemoryBarrier barrier3 = {
                srcAccessMask: AccessFlags.TransferRead,
                dstAccessMask: AccessFlags.MemoryRead,
                oldLayout: ImageLayout.TransferSrcOptimal,
                newLayout: ImageLayout.PresentSrc,
                image: srcImage.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            copyCmd.cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.Transfer, 0, null, null, [barrier3]);

            copyCmd.end();

            queue.submit(copyCmd);
            queue.waitIdle();

            // Get layout of the image (including row pitch)
            VkImageSubresource subResource = { 
                aspectMask: VK_IMAGE_ASPECT_COLOR_BIT,
                mipLevel: 0,
                arrayLayer: 0
            };
            auto subResourceLayout = dstImage.image.getSubresourceLayout(subResource);

            // Map image memory so we can start copying from it
            auto data = dstImage.memory.mapWhole(0, 0);
            data += subResourceLayout.offset;

            auto img = new FIImage(width, height, 32);
            img.dataArray[] = data[0..img.dataArray.length][];
            img.flipVertical();
            img.save(filename);

            // Clean up resources
            dstImage.memory.unmap();
        }
    }
}
