module sbylib.graphics.wrapper.image;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.core.vulkancontext;
import sbylib.graphics.util.own;

class VImage {

    private @own {
        Image _image;
        DeviceMemory _memory;
    }

    mixin ImplReleaseOwn;

    this(Image _image, MemoryProperties.MemoryType.Flags flag) {
        this._image = _image;
        this._memory = _image.allocateMemory(VulkanContext.gpu, flag);
    
        _memory.bindImage(_image, 0);
    }

    Image image() {
        return _image;
    }

    DeviceMemory memory() {
        return _memory;
    }
}