module sbylib.graphics.wrapper.device;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.wrapper.glfw : Window, GLFW;
import sbylib.graphics.layer;
import sbylib.graphics.util.functions;
import sbylib.graphics.wrapper.fence;
import sbylib.graphics.wrapper.queue;

class VDevice {

    struct CreateInfo {
        VkPhysicalDeviceFeatures feature;
        LayerSettings layerSettings;
        string appName;
        uint appVersion;
    }

    Instance instance;
    PhysicalDevice gpu;
    Device device;
    alias device this;

    private LayerSettings layerSettings;

    mixin ImplResourceStack;

    static void initialize(CreateInfo info, Window window) {
        import erupted.vulkan_lib_loader : loadGlobalLevelFunctions;

        const globalFunctionLoaded = loadGlobalLevelFunctions();
        assert(globalFunctionLoaded);

        info.layerSettings.settings ~= new StandardValidationLayerSetting;
        info.layerSettings.settings ~= new KhronosValidationLayerSetting;
        scope (exit) info.layerSettings.finalize();

        Instance.CreateInfo instanceCreateInfo = {
            applicationInfo: {
                applicationName: info.appName,
                applicationVersion: info.appVersion,
                engineName: "sbylib",
                engineVersion: VK_MAKE_VERSION(1,0,0),
                apiVersion : VK_API_VERSION_1_0
            },
            enabledLayerNames: info.layerSettings.use(),
            enabledExtensionNames: GLFW.getRequiredInstanceExtensions() ~ ["VK_EXT_debug_report"]
        };

        enforce(instanceCreateInfo.enabledLayerNames.all!(n =>
                    LayerProperties.getAvailableInstanceLayerProperties().canFind!(l => l.layerName == n)));

        auto instance = new Instance(instanceCreateInfo);

        inst = new VDevice(instance, info.feature, window);
    }

    static void deinitialize() {
        inst.destroyStack();
    }

    private static typeof(this) inst;

    static typeof(this) opCall() {
        return inst;
    }

    private this(Instance instance, VkPhysicalDeviceFeatures feature, Window window) {
        this.instance = instance;

        auto surface = window.createSurface(instance);
        scope (exit)
            surface.destroy();

        this.gpu = instance.findPhysicalDevice!((PhysicalDevice gpu) => gpu.getSurfaceSupport(surface));

        this.device = createDevice(feature);

        pushResource(instance);
        pushResource(device);
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
        return new Device(gpu, deviceCreateInfo);
    }
}
