module sbylib.graphics.wrapper.image;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.wrapper.device;
import sbylib.graphics.util.own;

class VImage {

    private @own {
        Image _image;
        DeviceMemory _memory;
    }

    mixin ImplReleaseOwn;

    this(Image _image, MemoryProperties.MemoryType.Flags flag) {
        this._image = _image;
        this._memory = _image.allocateMemory(VDevice().gpu, flag);
    
        _memory.bindImage(_image, 0);
    }

    Image image() {
        return _image;
    }

    DeviceMemory memory() {
        return _memory;
    }
}
