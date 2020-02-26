module sbylib.graphics.wrapper.commandbuffer;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.wrapper.device;
import sbylib.graphics.util.own;
import erupted : VkCommandBuffer;

class VCommandBuffer {

    enum Type {
        Graphics = QueueFamilyProperties.Flags.Graphics,
        Compute = QueueFamilyProperties.Flags.Compute,
    }

    private static CommandPool[Type] pools;

    private static CommandPool pool(Type type) {
        if (auto p = type in pools) return *p;
        with (VDevice()) {
            auto queueFamilyIndex = findQueueFamilyIndex(type);
            CommandPool.CreateInfo commandPoolCreateInfo = {
                flags: CommandPool.CreateInfo.Flags.ResetCommandBuffer
                     | CommandPool.CreateInfo.Flags.Protected,
                queueFamilyIndex: queueFamilyIndex
            };
            auto pool = new CommandPool(device, commandPoolCreateInfo);
            pushResource(pool);
            return pools[type] = pool;
        }
    }

    static VCommandBuffer[] allocate(Type type, CommandBufferLevel level, int count) {
        CommandBuffer.AllocateInfo commandbufferAllocInfo = {
            commandPool: pool(type),
            level: level,
            commandBufferCount: count,
        };
        return CommandBuffer.allocate(VDevice(), commandbufferAllocInfo).map!(c => new VCommandBuffer(c)).array;
    }

    static VCommandBuffer allocate(Type type, CommandBufferLevel level = CommandBufferLevel.Primary) {
        return allocate(type, level, 1)[0];
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
