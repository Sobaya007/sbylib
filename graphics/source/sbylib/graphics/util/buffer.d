module sbylib.graphics.util.buffer;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;

class VBuffer(T) {

    private {
        @own {
            Buffer _buffer;
            DeviceMemory _memory;
        }
        size_t size;
    }

    mixin ImplReleaseOwn;

    this(const T[] data, BufferUsage usage) {
        this(T.sizeof * data.length, usage, MemoryProperties.MemoryType.Flags.HostVisible);
        this.write(data);
    }

    this(size_t size, BufferUsage usage, MemoryProperties.MemoryType.Flags flag) {
        this.size = size;

        with (VulkanContext) {
            Buffer.CreateInfo bufferInfo = {
                usage: usage,
                size: size,
                sharingMode: SharingMode.Exclusive,
            };
            this._buffer = new Buffer(device, bufferInfo);
    
    
            DeviceMemory.AllocateInfo deviceMemoryAllocInfo = {
                allocationSize: device.getBufferMemoryRequirements(_buffer).size,
                memoryTypeIndex: cast(uint)VulkanContext.gpu.getMemoryProperties().memoryTypes
                    .countUntil!(p => p.supports(flag))
            };
            enforce(deviceMemoryAllocInfo.memoryTypeIndex != -1);
            this._memory = new DeviceMemory(device, deviceMemoryAllocInfo);
    
    
            _memory.bindBuffer(_buffer, 0);
        }
    }

    Buffer buffer() {
        return _buffer;
    }

    DeviceMemory memory() {
        return _memory;
    }

    auto map() {
        struct HostMemory {
            private DeviceMemory deviceMemory;
            T[] hostMemory;

            ~this() {
                deviceMemory.unmap();
            }
        }

        return HostMemory(this.memory, cast(T[])this.memory.map(0, this.size, 0));
    }

    void write(const T[] data) {
        auto hostMemory = memory.map(0, T.sizeof * data.length, 0);
        hostMemory[] = (cast(const ubyte[])data)[];
        memory.unmap();
    }
}
