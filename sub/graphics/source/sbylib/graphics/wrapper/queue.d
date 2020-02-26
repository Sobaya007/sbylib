module sbylib.graphics.wrapper.queue;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.wrapper.device;
import sbylib.graphics.wrapper.fence;

class VQueue {

    @own Queue queue;
    mixin ImplReleaseOwn;
    alias queue this;

    enum Type {
        Graphics = QueueFamilyProperties.Flags.Graphics,
        Compute = QueueFamilyProperties.Flags.Compute,
    }

    private static VQueue[Type] queues;

    static VQueue opCall(Type type) {
        if (auto q = type in queues) return *q;
        with (VDevice()) {
            auto queueFamilyIndex = findQueueFamilyIndex(type);
            auto queue = new VQueue(device.getQueue(queueFamilyIndex, 0));
            pushResource(queue);
            return queues[type] = queue;
        }
    }

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

    VFence submitWithFence(CommandBuffer commandBuffer, string name = null) {
        auto fence = VFence.create(name);
        return submitWithFence(commandBuffer, fence);
    }

    void submit(CommandBuffer commandBuffer) {
        submitWithFence(commandBuffer, cast(VFence)null);
    }

}
