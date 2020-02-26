module sbylib.graphics.util.fence;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;

class VFence {

    @own Fence fence;
    mixin ImplReleaseOwn;
    alias fence this;

    invariant(fence !is null);

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
