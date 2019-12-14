module sbylib.graphics.util.image;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.util.rendercontext;
import sbylib.graphics.util.vulkancontext;

class VImage {

    private @own {
        Image _image;
        DeviceMemory _memory;
    }

    mixin ImplReleaseOwn;

    this(Image _image, MemoryProperties.MemoryType.Flags flag) {
        this._image = _image;

        DeviceMemory.AllocateInfo deviceMemoryAllocInfo = {
            allocationSize: VulkanContext.device.getImageMemoryRequirements(_image).size,
            memoryTypeIndex: cast(uint)VulkanContext.gpu.getMemoryProperties().memoryTypes
                .countUntil!(p => p.supports(flag))
        };
        enforce(deviceMemoryAllocInfo.memoryTypeIndex != -1);
        this._memory = new DeviceMemory(VulkanContext.device, deviceMemoryAllocInfo);
    
    
        _memory.bindImage(_image, 0);
    }

    Image image() {
        return _image;
    }

    DeviceMemory memory() {
        return _memory;
    }
}
