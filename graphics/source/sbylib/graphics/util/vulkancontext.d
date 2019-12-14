module sbylib.graphics.util.vulkancontext;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.wrapper.glfw : Window, GLFW;
import sbylib.graphics.util.rendercontext;
import sbylib.graphics.util.computecontext;
import sbylib.graphics.util.functions;

class VulkanContext {
static:
    Instance instance;
    PhysicalDevice gpu;
    Device device;
    Queue queue;
    CommandPool commandPool;

    uint graphicsQueueFamilyIndex;
    uint computeQueueFamilyIndex;

    mixin ImplResourceStack;

    void initialize(string appName, uint appVersion, Window window,
            VkPhysicalDeviceFeatures feature = VkPhysicalDeviceFeatures.init) {
        import erupted.vulkan_lib_loader : loadGlobalLevelFunctions;

        const globalFunctionLoaded = loadGlobalLevelFunctions();
        assert(globalFunctionLoaded);

        Instance.CreateInfo instanceCreateInfo = {
            applicationInfo: {
                applicationName: appName,
                applicationVersion: appVersion,
                engineName: "sbylib",
                engineVersion: VK_MAKE_VERSION(1,0,0),
                apiVersion : VK_API_VERSION_1_0
            },
            enabledLayerNames: [
                "VK_LAYER_LUNARG_standard_validation",
                "VK_LAYER_KHRONOS_validation",
            ],
            enabledExtensionNames: GLFW.getRequiredInstanceExtensions() ~ ["VK_EXT_debug_report"]
        };

        enforce(instanceCreateInfo.enabledLayerNames.all!(n =>
                    LayerProperties.getAvailableInstanceLayerProperties().canFind!(l => l.layerName == n)));

        this.instance = pushResource(new Instance(instanceCreateInfo));

        auto surface = window.createSurface(instance);
        scope (exit)
            surface.destroy();

        this.gpu = instance.findPhysicalDevice!((PhysicalDevice gpu) => gpu.getSurfaceSupport(surface));

        this.graphicsQueueFamilyIndex = gpu.findQueueFamilyIndex!(prop =>
                prop.supports(QueueFamilyProperties.Flags.Graphics));
        this.computeQueueFamilyIndex = gpu.findQueueFamilyIndex!(prop =>
                prop.supports(QueueFamilyProperties.Flags.Compute));
        this.device = pushResource(createDevice(feature));
        this.queue = device.getQueue(graphicsQueueFamilyIndex, 0);
        this.commandPool = pushResource(createCommandPool(graphicsQueueFamilyIndex));

        RenderContext.initialize();
        pushReleaseCallback({ RenderContext.deinitialize(); });

        ComputeContext.initialize();
        pushReleaseCallback({ ComputeContext.deinitialize(); });
    }

    void deinitialize() {
        destroyStack();
    }

    public Fence createFence(string name = null) {
        Fence.CreateInfo fenceCreatInfo;
        auto result = new Fence(device, fenceCreatInfo);
        if (name) result.name = name;
        return result;
    }

    private Device createDevice(VkPhysicalDeviceFeatures features) {
        Device.QueueCreateInfo[] queueCreateInfos = [{
            queuePriorities: [0.0f],
            queueFamilyIndex: graphicsQueueFamilyIndex,
        }];
        if (graphicsQueueFamilyIndex != computeQueueFamilyIndex) {
            Device.QueueCreateInfo computeQueueCreateInfo = {
                queuePriorities: [0.0f],
                queueFamilyIndex: computeQueueFamilyIndex,
            };
            queueCreateInfos ~= computeQueueCreateInfo;
        }
        Device.DeviceCreateInfo deviceCreateInfo = {
            queueCreateInfos: queueCreateInfos,
            enabledExtensionNames: ["VK_KHR_swapchain", "VK_EXT_debug_marker"],
            pEnabledFeatures: &features
        };
        return new Device(VulkanContext.gpu, deviceCreateInfo);
    }

    package CommandPool createCommandPool(uint queueFamilyIndex) {
        CommandPool.CreateInfo commandPoolCreateInfo = {
            flags: CommandPool.CreateInfo.Flags.ResetCommandBuffer
                 | CommandPool.CreateInfo.Flags.Protected,
            queueFamilyIndex: queueFamilyIndex
        };
        return new CommandPool(VulkanContext.device, commandPoolCreateInfo);
    }

}
