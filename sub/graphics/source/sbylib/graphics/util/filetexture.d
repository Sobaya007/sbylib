module sbylib.graphics.util.filetexture;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.wrapper.freeimage : FIImage = Image;
import sbylib.graphics.core.vulkancontext;
import sbylib.graphics.util.own;
import sbylib.graphics.wrapper.buffer;
import sbylib.graphics.wrapper.commandbuffer;
import sbylib.graphics.wrapper.texture;
import sbylib.graphics.wrapper.image;

class FileTexture : Texture {

    private {
        @own {
            VImage image;
            ImageView _imageView;
            Sampler _sampler;
        }
        uint _width, _height;
    }

    mixin ImplReleaseOwn;

    this(string fileName) {
        auto texture = FIImage.load(fileName).to32bit();
        scope (exit) texture.destroy();

        this._width = texture.width;
        this._height = texture.height;

        auto stagingBuffer = new VBuffer!ubyte(texture.dataArray, BufferUsage.TransferSrc);
        scope (exit) stagingBuffer.destroy();

        this.image = new VImage(createImage(texture.width, texture.height), MemoryProperties.MemoryType.Flags.DeviceLocal);
        this._imageView = createImageView(image.image);

        this._sampler = createSampler();

        transferData(stagingBuffer.buffer, image.image);
    }

    private Buffer createStageBuffer(size_t size) {
        Buffer.CreateInfo bufferInfo = {
            usage: BufferUsage.TransferSrc,
            size: size,
            sharingMode: SharingMode.Exclusive,
        };
        return new Buffer(VulkanContext.device, bufferInfo);
    }

    private Image createImage(int width, int height) {
        Image.CreateInfo imageInfo = {
            imageType: ImageType.Type2D,
            extent: {
                width: width,
                height: height,
                depth: 1
            },
            mipLevels: 1,
            arrayLayers: 1,
            format: VK_FORMAT_R8G8B8A8_UNORM,
            tiling: ImageTiling.Optimal,
            initialLayout: ImageLayout.Undefined,
            usage: ImageUsage.TransferDst | ImageUsage.Sampled,
            sharingMode: SharingMode.Exclusive,
            samples: SampleCount.Count1
        };
        return new Image(VulkanContext.device, imageInfo);
    }

    private ImageView createImageView(Image image) {
        ImageView.CreateInfo imageViewInfo = {
            image: image,
            viewType: ImageViewType.Type2D,
            format: VK_FORMAT_R8G8B8A8_UNORM,
            subresourceRange: {
                aspectMask: ImageAspect.Color,
                baseMipLevel: 0,
                levelCount: 1,
                baseArrayLayer: 0,
                layerCount: 1
            },
            components: {
                r: ComponentSwizzle.B,
                g: ComponentSwizzle.G,
                b: ComponentSwizzle.R,
                a: ComponentSwizzle.A,
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

    private void transferData(Buffer src, Image dst) {
        auto commandBuffer = VCommandBuffer.allocate(QueueFamilyProperties.Flags.Graphics);
        scope (exit)
            commandBuffer.destroy();

        with (commandBuffer(CommandBuffer.BeginInfo.Flags.OneTimeSubmit)) {
            VkImageMemoryBarrier barrier = {
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: ImageLayout.Undefined,
                newLayout: ImageLayout.TransferDstOptimal,
                image: dst.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.Transfer, 0, null, null, [barrier]);

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
                imageOffset: {
                    x: 0,
                    y: 0,
                    z: 0,
                },
                imageExtent: {
                    width: width,
                    height: height,
                    depth: 1
                }
            };
            cmdCopyBufferToImage(src, dst, ImageLayout.TransferDstOptimal, [bufferImageCopy]);

            VkImageMemoryBarrier barrier2 = {
                oldLayout: ImageLayout.TransferDstOptimal,
                newLayout: ImageLayout.ShaderReadOnlyOptimal,
                image: dst.image,
                subresourceRange: {
                    aspectMask: ImageAspect.Color,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            cmdPipelineBarrier(PipelineStage.Transfer, PipelineStage.FragmentShader, 0, null, null, [barrier2]);
        
        }

        auto fence = VulkanContext.graphicsQueue.submitWithFence(commandBuffer);
        fence.wait();
        fence.destroy();
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
}
