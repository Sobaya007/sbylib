module sbylib.graphics.util.rendercontext;

import std;
import erupted;
import sbylib.event;
import sbylib.wrapper.glfw : Window;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.functions;
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

    private this(Window window) {
        with (VulkanContext) {
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

            Swapchain.CreateInfo swapchainCreateInfo = {
                surface: surface,
                minImageCount: surfaceCapabilities.minImageCount,
                imageFormat: surfaceFormat.format,
                imageColorSpace: surfaceFormat.colorSpace,
                imageExtent: surfaceCapabilities.currentExtent,
                imageArrayLayers: 1,
                imageUsage: ImageUsage.ColorAttachment,
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
        Fence.reset(presentFences);
        Queue.PresentInfo presentInfo = {
            swapchains: [swapchain],
            imageIndices: [currentImageIndex]
        };
        queue.present(presentInfo);
        currentImageIndex = acquireNextImageIndex(imageIndexAcquireFence);
    }

    public void pushPresentFence(Fence fence) {
        this.presentFences ~= fence;
    }

    public int getImageIndex() {
        if (currentImageIndex == -1) {
            return currentImageIndex = acquireNextImageIndex(imageIndexAcquireFence);
        }
        return currentImageIndex;
    }
}
