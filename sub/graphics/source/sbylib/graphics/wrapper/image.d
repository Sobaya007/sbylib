module sbylib.graphics.wrapper.image;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.graphics.wrapper.commandbuffer;
import sbylib.graphics.wrapper.device;
import sbylib.graphics.wrapper.queue;
import sbylib.graphics.util.own;

class VImage {

    private @own {
        Image _image;
        DeviceMemory _memory;
    }

    mixin ImplReleaseOwn;

    this(Image _image, MemoryProperties.MemoryType.Flags flag) {
        this._image = _image;
        this._memory = _image.allocateMemory(VDevice().gpu, flag);
    
        _memory.bindImage(_image, 0);
    }

    Image image() {
        return _image;
    }

    DeviceMemory memory() {
        return _memory;
    }

    void transit(ImageLayout oldLayout, ImageLayout newLayout, ImageAspect aspect) {
        auto commandBuffer = VCommandBuffer.allocate(VCommandBuffer.Type.Graphics);
        scope (exit)
            commandBuffer.destroy();

        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            VkImageMemoryBarrier barrier = {
                oldLayout: oldLayout,
                newLayout: newLayout,
                image: image.image,
                subresourceRange: {
                    aspectMask: aspect,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            
            // wait at bottom of pipe until before command's stage comes to top of pipe (does not wait at all)
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.BottomOfPipe, 0, [], [], [barrier]);
        }

        auto fence = VQueue(VQueue.Type.Graphics).submitWithFence(commandBuffer, "transit");
        fence.wait();
        fence.destroy();
    }
}
