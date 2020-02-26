module sbylib.graphics.wrapper.queue;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.core.vulkancontext;
import sbylib.graphics.util.own;
import sbylib.graphics.wrapper.fence;

class VQueue {

    @own Queue queue;
    mixin ImplReleaseOwn;
    alias queue this;

    this(Queue queue) {
        this.queue = queue;
    }

    VFence submitWithFence(CommandBuffer commandBuffer, VFence fence) {
        Queue.SubmitInfo submitInfo = {
            commandBuffers: [commandBuffer]
        };
        queue.submit([submitInfo], fence ? fence.fence : null);
        return fence;
    }

    VFence submitWithFence(CommandBuffer commandBuffer) {
        auto fence = VulkanContext.createFence();
        return submitWithFence(commandBuffer, fence);
    }

    void submit(CommandBuffer commandBuffer) {
        submitWithFence(commandBuffer, null);
    }

}
