module sbylib.graphics.material.standard.renderpass;

import std;
import sbylib.graphics.core.presenter;
import sbylib.graphics.util.own;
import sbylib.graphics.wrapper;

class StandardRenderPass : VRenderPass {

    enum ColorFormat = VK_FORMAT_B8G8R8A8_UNORM;
    enum DepthFormat = VK_FORMAT_D32_SFLOAT;

    @own {
        private {
            ImageView[] colorImageViews;
            VImage depthImage;
            ImageView depthImageView;
        }
    }
    mixin ImplReleaseOwn;

    mixin ImplOpCall;

    immutable RenderPass.CreateInfo c = {
        attachments: [{
            format: ColorFormat,
            samples: SampleCount.Count1,
            loadOp: AttachmentLoadOp.Clear,
            storeOp: AttachmentStoreOp.Store,
            initialLayout: ImageLayout.Undefined,
            finalLayout: ImageLayout.PresentSrc,
        }, {
            format: DepthFormat,
            samples: SampleCount.Count1,
            loadOp: AttachmentLoadOp.Clear,
            storeOp: AttachmentStoreOp.Store,
            initialLayout: ImageLayout.Undefined,
            finalLayout: ImageLayout.DepthStencilAttachmentOptimal,
        }],
        subpasses: [{
            pipelineBindPoint: PipelineBindPoint.Graphics,
            colorAttachments: [{
                attachment: 0,
                layout: ImageLayout.ColorAttachmentOptimal
            }],
            depthStencilAttachments: [{
                attachment: 1,
                layout: ImageLayout.DepthStencilAttachmentOptimal
            }]
        }]
    };
    mixin Info!c;

    private this(Window window) {
        super(window);

        foreach (im; Presenter(window).getSwapchainImages()) {
            this.colorImageViews ~= createImageView(im, ColorFormat, ImageAspect.Color);
        }

        this.depthImage = createImage(window.width, window.height);
        this.depthImageView = createImageView(depthImage.image, DepthFormat, ImageAspect.Depth);

        Framebuffer[] framebuffers;
        foreach (colorImageView; colorImageViews) {
            framebuffers ~= createFramebuffer(window.width, window.height, colorImageView, depthImageView);
        }
        registerFrameBuffers(framebuffers);
    }

    private VImage createImage(int width, int height) {
        Image.CreateInfo imageInfo = {
            imageType: ImageType.Type2D,
            extent: {
                width: width,
                height: height,
                depth: 1
            },
            mipLevels: 1,
            arrayLayers: 1,
            format: DepthFormat,
            tiling: ImageTiling.Optimal,
            initialLayout: ImageLayout.DepthStencilAttachmentOptimal,
            usage: ImageUsage.DepthStencilAttachment,
            sharingMode: SharingMode.Exclusive,
            samples: SampleCount.Count1
        };
        return new VImage(new Image(VDevice(), imageInfo), MemoryProperties.MemoryType.Flags.DeviceLocal);
    }

    private ImageView createImageView(Image image, VkFormat format, ImageAspect aspectMask) {
        ImageView.CreateInfo info = {
           image: image,
           viewType: ImageViewType.Type2D,
           format: format,
           subresourceRange: {
               aspectMask: aspectMask,
               baseMipLevel: 0,
               levelCount: 1,
               baseArrayLayer: 0,
               layerCount: 1,
           }
        };
        return new ImageView(VDevice(), info);
    }

    private Framebuffer createFramebuffer(int width, int height, ImageView colorImage, ImageView depthImage) {
        Framebuffer.CreateInfo info = {
            renderPass: this,
            attachments: [colorImage, depthImage],
            width: width,
            height: height,
            layers: 1,
        };
        return new Framebuffer(VDevice(), info);
    }
}
