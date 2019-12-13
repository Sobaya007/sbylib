module sbylib.graphics.util.uniformreference;

import std;
import sbylib.wrapper.vulkan;

struct UniformReference(UniformType) {
    private DeviceMemory memory;
    private UniformType[] _data;

    this(DeviceMemory memory) {
        this.memory = memory;
        this._data = (cast(UniformType*)memory.map(0, UniformType.sizeof, 0))[0..1];
    }

    ~this() {
        memory.unmap();
    }

    static foreach (mem; __traits(allMembers, UniformType)) {
        static if (!isCallable!(__traits(getMember, UniformType, mem))) {
            mixin(q{
                auto ref ${mem} () {
                    return _data[0].${mem};
                }
            }.replace("${mem}", mem));
        }
    }
}
