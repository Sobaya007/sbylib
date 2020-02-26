module sbylib.graphics.util.commandbuffer;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;
import erupted : VkCommandBuffer;

class VCommandBuffer {

    private static CommandPool[QueueFamilyProperties.Flags] pools;

    private static CommandPool pool(QueueFamilyProperties.Flags flags) {
        if (auto p = flags in pools) return *p;
        with (VulkanContext) {
            auto queueFamilyIndex = findQueueFamilyIndex(flags);
            CommandPool.CreateInfo commandPoolCreateInfo = {
                flags: CommandPool.CreateInfo.Flags.ResetCommandBuffer
                     | CommandPool.CreateInfo.Flags.Protected,
                queueFamilyIndex: queueFamilyIndex
            };
            auto pool = new CommandPool(device, commandPoolCreateInfo);
            pushResource(pool);
            return pools[flags] = pool;
        }
    }

    static VCommandBuffer[] allocate(QueueFamilyProperties.Flags flags, CommandBufferLevel level, int count) {
        CommandBuffer.AllocateInfo commandbufferAllocInfo = {
            commandPool: pool(flags),
            level: level,
            commandBufferCount: count,
        };
        return CommandBuffer.allocate(VulkanContext.device, commandbufferAllocInfo).map!(c => new VCommandBuffer(c)).array;
    }

    static VCommandBuffer allocate(QueueFamilyProperties.Flags flags, CommandBufferLevel level = CommandBufferLevel.Primary) {
        return allocate(flags, level, 1)[0];
    }

    @own CommandBuffer commandBuffer;
    mixin ImplReleaseOwn;
    alias commandBuffer this;

    private this(CommandBuffer commandBuffer) {
        this.commandBuffer = commandBuffer;
    }

    void begin() {
        CommandBuffer.BeginInfo info;
        commandBuffer.begin(info);
    }

    void begin(CommandBuffer.BeginInfo.Flags flags) {
        CommandBuffer.BeginInfo info = {
            flags: flags
        };
        commandBuffer.begin(info);
    }

    auto opCall(Args...)(Args args) {
        this.begin(args);

        struct S {
            VCommandBuffer cb;
            alias cb this;

            ~this() {
                cb.end();
            }
        }
        return S(this);
    }
}
