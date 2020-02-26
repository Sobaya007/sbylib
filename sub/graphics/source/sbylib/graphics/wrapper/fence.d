module sbylib.graphics.wrapper.fence;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.wrapper.device;
import sbylib.graphics.util.own;

class VFence {

    @own Fence fence;
    mixin ImplReleaseOwn;
    alias fence this;

    invariant(fence !is null);

    static VFence create(string name = null) {
        Fence.CreateInfo fenceCreatInfo;
        auto result = new Fence(VDevice(), fenceCreatInfo);
        if (name) result.name = name;
        return new VFence(result);
    }

    this(Fence fence) {
        this.fence = fence;
    }

    void wait(Duration timeout = 1.seconds) {
        Fence.wait([fence], true, timeout.total!"nsecs");
    }

    void reset() {
        Fence.reset([fence]);
    }
}
