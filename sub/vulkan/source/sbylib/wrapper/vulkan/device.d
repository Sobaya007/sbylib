module sbylib.wrapper.vulkan.device;

import erupted;
import sbylib.wrapper.vulkan.buffer;
import sbylib.wrapper.vulkan.enums;
import sbylib.wrapper.vulkan.physicaldevice;
import sbylib.wrapper.vulkan.queue;
import sbylib.wrapper.vulkan.image;
import sbylib.wrapper.vulkan.util;

class Device {
    static struct QueueCreateInfo {
        @vkProp("pQueuePriorities", "queueCount") {
            const float[] queuePriorities;
        }
        @vkProp() {
            immutable uint queueFamilyIndex;
        }

        const mixin VkTo!(VkDeviceQueueCreateInfo);
    }

    static struct DeviceCreateInfo {
        @vkProp() {
            immutable VkDeviceCreateFlags flags;
            const(VkPhysicalDeviceFeatures)* pEnabledFeatures;
            void* pNext;
        }
        @vkProp("pQueueCreateInfos", "queueCreateInfoCount") {
            QueueCreateInfo[] queueCreateInfos;
        }
        @vkProp("ppEnabledLayerNames", "enabledLayerCount") {
            const string[] enabledLayerNames;
        }
        @vkProp("ppEnabledExtensionNames", "enabledExtensionCount") {
            const string[] enabledExtensionNames;
        }

        const mixin VkTo!(VkDeviceCreateInfo);
    }

    static struct MemoryRequirements {
        @vkProp() {
            VkDeviceSize    size;
            VkDeviceSize    alignment;
            uint32_t        memoryTypeBits;
        }

        mixin VkFrom!(VkMemoryRequirements);

        bool acceptable(size_t memoryTypeIndex) const {
            return (memoryTypeBits & (1 << memoryTypeIndex)) > 0;
        }
    }

    package VkDevice device;
    private PhysicalDevice gpu;

    // mixin ImplNameSetter!(this, device, DebugReportObjectType.Device);

    this(PhysicalDevice gpu, DeviceCreateInfo info) {
        import std.exception : enforce;

        this.gpu = gpu;

        VkDeviceCreateInfo deviceCreateInfo = info.vkTo();
        enforceVK(vkCreateDevice(gpu.physDevice, &deviceCreateInfo, null, &device));
        enforce(device != VK_NULL_HANDLE);

        loadDeviceLevelFunctions(device);
    }

    ~this() {
        vkDeviceWaitIdle(device);
        vkDestroyDevice(device, null);
    }

    Queue getQueue(uint queueFamilyIndex, uint queueIndex) {
        VkQueue queue;
        vkGetDeviceQueue(device, queueFamilyIndex, queueIndex, &queue);
        return new Queue(this, queue);
    }

    MemoryRequirements getBufferMemoryRequirements(Buffer buffer) {
        VkMemoryRequirements memreq;
        vkGetBufferMemoryRequirements(device, buffer.buffer, &memreq);
        return MemoryRequirements(memreq);
    }

    MemoryRequirements getImageMemoryRequirements(Image image) {
        VkMemoryRequirements memreq;
        vkGetImageMemoryRequirements(device, image.image, &memreq);
        return MemoryRequirements(memreq);
    }
}
