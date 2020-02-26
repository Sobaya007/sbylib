module sbylib.graphics.core.vulkancontext;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.wrapper.glfw : Window, GLFW;
import sbylib.graphics.layer;
import sbylib.graphics.util.functions;
import sbylib.graphics.wrapper.fence;
import sbylib.graphics.wrapper.queue;

class VulkanContext {
static:
    Instance instance;
    PhysicalDevice gpu;
    Device device;
    VQueue graphicsQueue, computeQueue;

    mixin ImplResourceStack;

    mixin Sealable!(VkPhysicalDeviceFeatures, "feature");
    LayerSettings layerSettings;

    void initialize(string appName, uint appVersion, Window window) {
        import erupted.vulkan_lib_loader : loadGlobalLevelFunctions;

        const globalFunctionLoaded = loadGlobalLevelFunctions();
        assert(globalFunctionLoaded);

        layerSettings.settings ~= new StandardValidationLayerSetting;
        layerSettings.settings ~= new KhronosValidationLayerSetting;
        pushReleaseCallback({ layerSettings.finalize(); });

        Instance.CreateInfo instanceCreateInfo = {
            applicationInfo: {
                applicationName: appName,
                applicationVersion: appVersion,
                engineName: "sbylib",
                engineVersion: VK_MAKE_VERSION(1,0,0),
                apiVersion : VK_API_VERSION_1_0
            },
            enabledLayerNames: layerSettings.use(),
            enabledExtensionNames: GLFW.getRequiredInstanceExtensions() ~ ["VK_EXT_debug_report"]
        };

        enforce(instanceCreateInfo.enabledLayerNames.all!(n =>
                    LayerProperties.getAvailableInstanceLayerProperties().canFind!(l => l.layerName == n)));

        this.instance = pushResource(new Instance(instanceCreateInfo));

        auto surface = window.createSurface(instance);
        scope (exit)
            surface.destroy();

        this.gpu = instance.findPhysicalDevice!((PhysicalDevice gpu) => gpu.getSurfaceSupport(surface));

        this.device = pushResource(createDevice(feature));
        this.graphicsQueue = pushResource(new VQueue(device.getQueue(findQueueFamilyIndex(QueueFamilyProperties.Flags.Graphics), 0)));
        this.computeQueue = pushResource(new VQueue(device.getQueue(findQueueFamilyIndex(QueueFamilyProperties.Flags.Compute), 0)));

        seal!(feature);
    }

    void deinitialize() {
        destroyStack();
    }

    public VFence createFence(string name = null) {
        Fence.CreateInfo fenceCreatInfo;
        auto result = new Fence(device, fenceCreatInfo);
        if (name) result.name = name;
        return new VFence(result);
    }

    public uint findQueueFamilyIndex(QueueFamilyProperties.Flags flags) {
        return gpu.findQueueFamilyIndex!(prop => prop.supports(flags));
    }

    private Device createDevice(VkPhysicalDeviceFeatures features) {
        auto graphicsQueueFamilyIndex = findQueueFamilyIndex(QueueFamilyProperties.Flags.Graphics);
        auto computeQueueFamilyIndex = findQueueFamilyIndex(QueueFamilyProperties.Flags.Compute);
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
}
