module sbylib.graphics.glyph.glyphtexture;

import std;
import erupted;
import sbylib.wrapper.freetype;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.buffer;
import sbylib.graphics.util.commandbuffer;
import sbylib.graphics.util.fence;
import sbylib.graphics.util.texture;
import sbylib.graphics.util.image;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;

class GlyphTexture : Texture {

    private {
        @own {
            VImage image;
            ImageView _imageView;
            Sampler _sampler;
            VCommandBuffer commandBuffer;
            VFence fence;
        }
        uint _width, _height;
    }

    mixin ImplReleaseOwn;

    this(uint _width, uint _height) {
        this._width = _width;
        this._height = _height;

        this.image = createImage(width, height);
        this._imageView = createImageView(image);

        this._sampler = createSampler();

        this.commandBuffer = VCommandBuffer.allocate(QueueFamilyProperties.Flags.Graphics);

        this.fence = VulkanContext.createFence("glyph texture fence");

        this.transition();
    }

    private VImage createImage(int width, int height) {
        with (VulkanContext) {
            Image.CreateInfo imageInfo = {
                imageType: ImageType.Type2D,
                extent: {
                    width: width,
                    height: height,
                    depth: 1
                },
                mipLevels: 1,
                arrayLayers: 1,
                format: VK_FORMAT_R8_UNORM,
                tiling: ImageTiling.Optimal,
                initialLayout: ImageLayout.Undefined,
                usage: ImageUsage.TransferSrc | ImageUsage.TransferDst | ImageUsage.Sampled,
                sharingMode: SharingMode.Exclusive,
                samples: SampleCount.Count1
            };
            return new VImage(new Image(device, imageInfo), MemoryProperties.MemoryType.Flags.DeviceLocal);
        }
    }

    private ImageView createImageView(VImage image) {
        ImageView.CreateInfo imageViewInfo = {
            image: image.image,
            viewType: ImageViewType.Type2D,
            format: VK_FORMAT_R8_UNORM,
            subresourceRange: {
                aspectMask: ImageAspect.Color,
                baseMipLevel: 0,
                levelCount: 1,
                baseArrayLayer: 0,
                layerCount: 1
            }
        };
        return new ImageView(VulkanContext.device, imageViewInfo);
    }

    private Sampler createSampler() {
        Sampler.CreateInfo samplerInfo = {
            magFilter: SamplerFilter.Linear,
            minFilter: SamplerFilter.Linear,
            addressModeU: SamplerAddressMode.Repeat,
            addressModeV: SamplerAddressMode.Repeat,
            addressModeW: SamplerAddressMode.Repeat,
            anisotropyEnable: false,
            maxAnisotropy: 1,
            borderColor: BorderColor.IntOpaqueBlack,
            unnormalizedCoordinates: false,
            compareEnable: false,
            compareOp: CompareOp.Always,
            mipmapMode: SamplerMipmapMode.Linear,
            mipLodBias: 0.0f,
            minLod: 0.0f,
            maxLod: 0.0f
        };
        return new Sampler(VulkanContext.device, samplerInfo);
    }

    private void transition() {
        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            VkImageMemoryBarrier barrier = {
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.ShaderReadOnlyOptimal,
                image: image.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            // wait at bottom of pipe until before command's stage comes to top of pipe (does not wait at all)
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.BottomOfPipe, 0, [], [], [barrier]);
        }

        VulkanContext.graphicsQueue.submitWithFence(commandBuffer, fence);
        fence.wait();
        fence.reset();
    }

    package void write(ubyte[] data, VkOffset3D offset, VkExtent3D extent) {
        auto stagingBuffer = new VBuffer!ubyte(data, BufferUsage.TransferSrc);
        scope (exit)
            stagingBuffer.destroy();

        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            /*
               Transit image layout from `Undefined` to `TransferDstOptimal`.
               After transit, accessability of image becomes `TransferWrite`.
               Target subrange is color part, mimap level 0..1 (only 0), and array layer 0..1 (only 0).
               This transition is done after waiting at top of pipe of before command (does not wait at all).
               This transition is finished by transfer stage of next command.
             */
            VkImageMemoryBarrier barrier = {
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.TransferDstOptimal,
                image: image.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.Transfer, 0, [], [], [barrier]);

            /*
               Copy data from staging buffer to image.
               `bufferOffset` is as it looks.
               `bufferRowLength` and `bufferImageHeight` can control the arrangement of the data. and if both are 0, that means data is tightly packed.
               `imageSubresource` is the same as above.
               `imageOffset` and `imageExtent` are also as they look.
               At this operation, image layout must be `TransferDstOptimal`
             */
            VkBufferImageCopy bufferImageCopy = {
                bufferOffset: 0,
                bufferRowLength: 0,
                bufferImageHeight: 0,
                imageSubresource: {
                    aspectMask: ImageAspect.Color,
                    mipLevel: 0,
                    baseArrayLayer: 0,
                    layerCount: 1,
                },
                imageOffset: offset,
                imageExtent: extent,
            };
            cmdCopyBufferToImage(stagingBuffer.buffer, image.image, ImageLayout.TransferDstOptimal, [bufferImageCopy]);

            VkImageMemoryBarrier barrier2 = {
                oldLayout: ImageLayout.TransferDstOptimal,
                newLayout: ImageLayout.ShaderReadOnlyOptimal,
                image: image.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.FragmentShader, 0, [], [], [barrier2]);
        }

        VulkanContext.graphicsQueue.submit(commandBuffer);
    }

    uint width() const {
        return _width;
    }

    uint height() const {
        return _height;
    }

    override ImageView imageView() {
        return _imageView;
    }

    override Sampler sampler() {
        return _sampler;
    }

    void resize(uint newWidth, uint newHeight) {
        auto oldImage = this.image;
        scope (exit)
            oldImage.destroy();

        auto oldImageView = this.imageView;
        scope (exit)
            oldImageView.destroy();

        auto newImage = createImage(newWidth, newHeight);
        auto newImageView = createImageView(newImage);

        copy(oldImage, newImage, width, height);

        this._width = newWidth;
        this._height = newHeight;
        this.image = newImage;
        this._imageView = newImageView;
    }

    private void copy(VImage oldImage, VImage newImage, uint oldWidth, uint oldHeight) {
        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            VkImageMemoryBarrier[2] barrier = [{
                dstAccessMask: AccessFlags.TransferRead,
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.TransferSrcOptimal,
                image: oldImage.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            }, {
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.TransferDstOptimal,
                image: newImage.image.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            }];
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.Transfer, 0, [], [], barrier);

            VkImageBlit region = {
                srcSubresource: {
                    aspectMask: ImageAspect.Color,
                    mipLevel: 0,
                    baseArrayLayer: 0,
                    layerCount: 1
                },
                srcOffsets: [{
                    x: 0,
                    y: 0,
                    z: 0
                }, {
                    x: oldWidth,
                    y: oldHeight,
                    z: 1
                }],
                dstSubresource: {
                    aspectMask: ImageAspect.Color,
                    mipLevel: 0,
                    baseArrayLayer: 0,
                    layerCount: 1
                },
                dstOffsets: [{
                    x: 0,
                    y: 0,
                    z: 0
                }, {
                    x: oldWidth,
                    y: oldHeight,
                    z: 1
                }],
            };
            cmdBlitImage(
                    oldImage.image, ImageLayout.TransferSrcOptimal,
                    newImage.image, ImageLayout.TransferDstOptimal,
                    [region], SamplerFilter.Nearest);
        }

        VulkanContext.graphicsQueue.submitWithFence(commandBuffer, fence);
        fence.wait();
        fence.reset();
    }
}
