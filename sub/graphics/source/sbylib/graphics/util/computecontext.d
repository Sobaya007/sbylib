module sbylib.graphics.util.computecontext;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.vulkancontext;

class ComputeContext {
static __gshared:
    Queue queue;
    CommandPool commandPool;
    private void delegate()[] deconstructionStack;

    package void initialize() {
        with (VulkanContext) {
            this.queue = device.getQueue(computeQueueFamilyIndex, 0);
            this.commandPool = createCommandPool(computeQueueFamilyIndex);
        }

        this.commandPool.name = "CommandPool of ComputeContext";
    }

    package void deinitialize() {
        commandPool.destroy();
        while (deconstructionStack.empty is false) {
            deconstructionStack.back()();
            deconstructionStack.popBack();
        }
    }

private:

    Device createDevice(uint queueFamilyIndex, VkPhysicalDeviceFeatures features) {
        Device.DeviceCreateInfo deviceCreateInfo = {
            queueCreateInfos: [{
                queuePriorities: [0.0f],
                queueFamilyIndex: queueFamilyIndex,
            }],
            pEnabledFeatures: &features
        };
        return pushResource(new Device(VulkanContext.gpu, deviceCreateInfo));
    }

    public CommandBuffer[] createCommandBuffer(CommandBufferLevel level, int commandBufferCount) {
        CommandBuffer.AllocateInfo commandbufferAllocInfo = {
            commandPool: commandPool,
            level: level,
            commandBufferCount: commandBufferCount,
        };
        return CommandBuffer.allocate(VulkanContext.device, commandbufferAllocInfo);
    }

    public T pushResource(T)(T t) {
        deconstructionStack ~= { t.destroy(); };
        return t;
    }
}
