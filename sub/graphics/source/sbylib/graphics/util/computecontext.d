module sbylib.graphics.util.computecontext;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.functions;
import sbylib.graphics.util.vulkancontext;

class ComputeContext {
static __gshared:

    package void deinitialize() {
        destroyStack();
    }

    mixin ImplResourceStack;
}
