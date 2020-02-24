module sbylib.graphics.util.computecontext;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.functions;
import sbylib.graphics.util.vulkancontext;

class ComputeContext {
static __gshared:
    Queue queue;
    CommandPool commandPool;

    package void initialize() {
        with (VulkanContext) {
            this.queue = device.getQueue(computeQueueFamilyIndex, 0);
            this.commandPool = createCommandPool(computeQueueFamilyIndex);
        }
        VulkanContext.pushReleaseCallback({
                deinitialize();
        });

        this.commandPool.name = "CommandPool of ComputeContext";
    }

    package void deinitialize() {
        commandPool.destroy();
        destroyStack();
    }

    mixin ImplResourceStack;

    CommandBuffer[] createCommandBuffer(CommandBufferLevel level, int commandBufferCount) {
        CommandBuffer.AllocateInfo commandbufferAllocInfo = {
            commandPool: commandPool,
            level: level,
            commandBufferCount: commandBufferCount,
        };
        return CommandBuffer.allocate(VulkanContext.device, commandbufferAllocInfo);
    }
}
