module sbylib.wrapper.vulkan.image;

import std;
import erupted;
import sbylib.wrapper.vulkan.device;
import sbylib.wrapper.vulkan.devicememory;
import sbylib.wrapper.vulkan.enums;
import sbylib.wrapper.vulkan.physicaldevice;
import sbylib.wrapper.vulkan.memoryproperties;
import sbylib.wrapper.vulkan.util;

class Image {
    static struct CreateInfo {
        @vkProp() {
            VkImageCreateFlags flags;
            ImageType imageType;
            VkFormat format;
            VkExtent3D extent;
            uint mipLevels;
            uint arrayLayers;
            SampleCount samples;
            ImageTiling tiling;
            ImageUsage usage;
            SharingMode sharingMode;
            ImageLayout initialLayout;
        }

        @vkProp("pQueueFamilyIndices", "queueFamilyIndexCount") {
            const uint[] queueFamilyIndices;
        }

        mixin VkTo!(VkImageCreateInfo);
    }

    private Device device;
    public VkImage image;
    private bool mustRelease;

    mixin ImplNameSetter!(device, image, DebugReportObjectType.Image);

    this(Device device, CreateInfo _info) {
        this.device = device;

        auto info = _info.vkTo();

        enforce(device !is null);
        enforce(device.device !is null);
        enforceVK(vkCreateImage(device.device, &info, null, &image));
        enforce(image != VK_NULL_HANDLE);
        this.mustRelease = true;
    }

    this(VkImage image) {
        this.image = image;
        enforce(image != VK_NULL_HANDLE);
        this.mustRelease = false;
    }

    ~this() {
        if (mustRelease)
            vkDestroyImage(device.device, image, null);
    }

    mixin VkTo!(VkImage);

    VkSubresourceLayout getSubresourceLayout(VkImageSubresource subResource) {
        VkSubresourceLayout subResourceLayout;
        vkGetImageSubresourceLayout(device.device, image, &subResource, &subResourceLayout);
        return subResourceLayout;
    }

    DeviceMemory allocateMemory(PhysicalDevice gpu, MemoryProperties.MemoryType.Flags memoryTypeFlag) {
        const requirements = device.getImageMemoryRequirements(this);
        DeviceMemory.AllocateInfo deviceMemoryAllocInfo = {
            allocationSize: requirements.size,
            memoryTypeIndex: cast(uint)gpu.getMemoryProperties().memoryTypes.enumerate
                .countUntil!(p => requirements.acceptable(p.index) && p.value.supports(memoryTypeFlag))
        };
        enforce(deviceMemoryAllocInfo.memoryTypeIndex != -1);
        return new DeviceMemory(device, deviceMemoryAllocInfo);
    }
}
