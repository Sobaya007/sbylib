module sbylib.graphics.material.gbuffer.renderpass;

import std;
import erupted;
import sbylib.wrapper.glfw : Window;
import sbylib.wrapper.vulkan;
import sbylib.graphics.material.standard.renderpass;
import sbylib.graphics.util.rendercontext;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;
import sbylib.graphics.util.texture;

class GBufferRenderPass : RenderPass {

    private Window window;

    class FramebufferAttachment {
        @own {
            Image image;
            DeviceMemory memory;
            ImageView view;
            Sampler sampler;
            VkFormat format;
            Texture texture;
        }
        mixin ImplReleaseOwn;

        this(Image image, DeviceMemory memory, ImageView view, Sampler sampler, VkFormat format, Texture texture) {
            this.image = image;
            this.memory = memory;
            this.view = view;
            this.sampler = sampler;
            this.format = format;
            this.texture = texture;
        }
    }

    @own {
        public {
            FramebufferAttachment position, normal, albedo;
            Framebuffer framebuffer;
            CommandBuffer[3] pretransitionCommandBuffer;
            CommandBuffer renderCommandBuffer;
            Fence submitFence;
        }
    }

    private void delegate(CommandBuffer)[] renderList;

    mixin ImplReleaseOwn;

    private static typeof(this)[Window] instance;

    static opCall(Window window) {
        if (window !in instance) {
            with (RenderContext(window)) {
                instance[window] = new typeof(this)(window);
                RenderContext(window).pushReleaseCallback({ GBufferRenderPass.deinitialize(window); });
            }
        }
        return instance[window];
    }

    private static void deinitialize(Window window) {
        assert(window in instance, "this window is not registered one.");
        instance[window].destroy();
        instance.remove(window);
    }

    this(Window window) {
        this.window = window;

        this.position = createAttachment(
                VK_FORMAT_R32G32B32A32_SFLOAT, ImageUsage.ColorAttachment | ImageUsage.Sampled, 
                ImageLayout.ShaderReadOnlyOptimal, ImageAspect.Color);

        this.normal = createAttachment(
                VK_FORMAT_R32G32B32A32_SFLOAT, ImageUsage.ColorAttachment | ImageUsage.Sampled, 
                ImageLayout.ShaderReadOnlyOptimal, ImageAspect.Color);

        this.albedo = createAttachment(
                VK_FORMAT_B8G8R8A8_UNORM, ImageUsage.ColorAttachment | ImageUsage.Sampled, 
                ImageLayout.ShaderReadOnlyOptimal, ImageAspect.Color);

        RenderPass.CreateInfo renderPassCreateInfo = {
            attachments: [{
                format: position.format,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Clear,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.ShaderReadOnlyOptimal,
            }, {
                format: normal.format,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Clear,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.ShaderReadOnlyOptimal,
            }, {
                format: albedo.format,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Clear,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.ShaderReadOnlyOptimal,
            }, {
                format: VK_FORMAT_D32_SFLOAT,
                samples: SampleCount.Count1,
                loadOp: AttachmentLoadOp.Load,
                storeOp: AttachmentStoreOp.Store,
                initialLayout: ImageLayout.Undefined,
                finalLayout: ImageLayout.DepthStencilAttachmentOptimal,
            }],
            subpasses: [{
                pipelineBindPoint: PipelineBindPoint.Graphics,
                colorAttachments: [{
                    attachment: 0,
                    layout: ImageLayout.ColorAttachmentOptimal
                }, {
                    attachment: 1,
                    layout: ImageLayout.ColorAttachmentOptimal
                }, {
                    attachment: 2,
                    layout: ImageLayout.ColorAttachmentOptimal
                }],
                depthStencilAttachments: [{
                    attachment: 3,
                    layout: ImageLayout.DepthStencilAttachmentOptimal
                }]
            }],
            dependencies: [{
                srcSubpass: VK_SUBPASS_EXTERNAL,
                dstSubpass: 0,
                srcStageMask: PipelineStage.FragmentShader,
                dstStageMask: PipelineStage.ColorAttachmentOutput,
                srcAccessMask: AccessFlags.ShaderRead,
                dstAccessMask: AccessFlags.ColorAttachmentWrite,
                dependencyFlags: DependencyFlags.ByRegion
            }, {
                srcSubpass: 0,
                dstSubpass: VK_SUBPASS_EXTERNAL,
                srcStageMask: PipelineStage.FragmentShader,
                dstStageMask: PipelineStage.ColorAttachmentOutput,
                srcAccessMask: AccessFlags.ShaderRead,
                dstAccessMask: AccessFlags.ColorAttachmentWrite,
                dependencyFlags: DependencyFlags.ByRegion
            }]
        };
        super(VulkanContext.device, renderPassCreateInfo);

        Framebuffer.CreateInfo framebufferCreateInfo = {
            renderPass: this,
            attachments: [
                position.view,
                normal.view,
                albedo.view,
                StandardRenderPass(window).depthImageView,
            ],
            width: window.width,
            height: window.height,
            layers: 1,
        };
        this.framebuffer = new Framebuffer(VulkanContext.device, framebufferCreateInfo);

        auto cbs = RenderContext.createCommandBuffer(CommandBufferLevel.Primary, 4);
        this.pretransitionCommandBuffer = cbs[0..3];
        this.renderCommandBuffer = cbs[3];
        this.pretransitionCommandBuffer[0].name = "GBuffer pretransitionCommandBuffer";
        this.pretransitionCommandBuffer[1].name = "GBuffer pretransitionCommandBuffer";
        this.pretransitionCommandBuffer[2].name = "GBuffer pretransitionCommandBuffer";
        this.renderCommandBuffer.name = "GBuffer renderCommandBuffer";
        this.submitFence = VulkanContext.createFence("standard renderpass submission fence");
        RenderContext(window).pushPresentFence(submitFence);
        updateCommandBuffer();
    }

    private FramebufferAttachment createAttachment(VkFormat format, ImageUsage usage,
            ImageLayout layout, ImageAspect aspect) {
        auto image = createImage(window, format, usage);
        auto memory = createMemory(image, layout, aspect);
        auto view = createImageView(image, format, aspect);
        auto _sampler = createSampler();

        class T : Texture {
            override ImageView imageView() {
                return view;
            }

            override Sampler sampler() {
                return _sampler;
            }

            ~this() {
                _sampler.destroy();
            }
        }
        
        return new FramebufferAttachment(image, memory, view, _sampler, format, new T);
    }

    private Image createImage(Window window, VkFormat format, ImageUsage usage) {
        Image.CreateInfo imageInfo = {
            imageType: ImageType.Type2D,
            extent: {
                width: window.width,
                height: window.height,
                depth: 1
            },
            mipLevels: 1,
            arrayLayers: 1,
            format: format,
            tiling: ImageTiling.Optimal,
            initialLayout: ImageLayout.Undefined,
            usage: usage,
            sharingMode: SharingMode.Exclusive,
            samples: SampleCount.Count1
        };
        auto result = new Image(VulkanContext.device, imageInfo);
        return result;
    }

    private DeviceMemory createMemory(Image image, ImageLayout layout, ImageAspect aspect) {
        with (VulkanContext) {
            auto result = image.allocateMemory(gpu, MemoryProperties.MemoryType.Flags.DeviceLocal);
            result.bindImage(image, 0);
            transitionImage(image, ImageLayout.Undefined, layout, aspect);
            return result;
        }
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
        return new ImageView(VulkanContext.device, info);
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

    private Framebuffer createFramebuffer(Window window, ImageView colorImage, ImageView depthImage) {
        Framebuffer.CreateInfo info = {
            renderPass: this,
            attachments: [colorImage, depthImage],
            width: window.width,
            height: window.height,
            layers: 1,
        };
        return new Framebuffer(VulkanContext.device, info);
    }

    private void transitionImage(Image image, ImageLayout oldLayout, ImageLayout newLayout, ImageAspect aspectMask) {
        with (RenderContext) {
            CommandBuffer.AllocateInfo commandbufferAllocInfo = {
                commandPool: commandPool,
                level: CommandBufferLevel.Primary,
                commandBufferCount: 1,
            };
            auto commandBuffer = CommandBuffer.allocate(VulkanContext.device, commandbufferAllocInfo)[0];
            scope (exit)
                commandBuffer.destroy();

            CommandBuffer.BeginInfo beginInfo = {
                flags: CommandBuffer.BeginInfo.Flags.OneTimeSubmit
            };
            commandBuffer.begin(beginInfo);

            VkImageMemoryBarrier barrier = {
                dstAccessMask: AccessFlags.TransferWrite,
                oldLayout: oldLayout,
                newLayout: newLayout,
                image: image.image,
                subresourceRange: {
                    aspectMask: aspectMask,
                    baseMipLevel: 0,
                    levelCount: 1,
                    baseArrayLayer: 0,
                    layerCount: 1
                }
            };
            commandBuffer.cmdPipelineBarrier(PipelineStage.TopOfPipe, PipelineStage.Transfer, 0, null, null, [barrier]);
            commandBuffer.end();

            Queue.SubmitInfo submitInfo = {
                commandBuffers: [commandBuffer]
            };
            queue.submit([submitInfo], null);
            queue.waitIdle();
        }
    }

    private void updateCommandBuffer() {
        CommandBuffer.BeginInfo beginInfo;
        renderCommandBuffer.begin(beginInfo);

        foreach (ref s; [position, normal, albedo]) {
             VkImageMemoryBarrier barrier = {
                 oldLayout: ImageLayout.ShaderReadOnlyOptimal,
                 newLayout: ImageLayout.ColorAttachmentOptimal,
                 image: s.image.image,
                 subresourceRange: {
                     aspectMask: ImageAspect.Color,
                     baseMipLevel: 0,
                     levelCount: 1,
                     baseArrayLayer: 0,
                     layerCount: 1
                 }
             };
             renderCommandBuffer.cmdPipelineBarrier(PipelineStage.BottomOfPipe, PipelineStage.TopOfPipe, 0, null, null, [barrier]);
        }

        CommandBuffer.RenderPassBeginInfo renderPassBeginInfo = {
            renderPass: this,
            framebuffer: framebuffer,
            renderArea: { 
                extent: VkExtent2D(window.width, window.height) 
            },
            clearValues: [{
                color: {
                    float32: [0.0f, 0.0f, 0.0f, 1.0f]
                },
            }, {
                color: {
                    float32: [0.0f, 0.0f, 0.0f, 1.0f]
                },
            }, {
                color: {
                    float32: [0.0f, 0.0f, 0.0f, 0.0f]
                },
            }, {
                depthStencil: {
                    depth: 1.0f
                }
            }]
        };
        renderCommandBuffer.cmdBeginRenderPass(renderPassBeginInfo, SubpassContents.Inline);

        this.renderList.each!(r => r(renderCommandBuffer));

        renderCommandBuffer.cmdEndRenderPass();

        renderCommandBuffer.end();
    }

    void submitRender() {
        with (RenderContext(window)) {
            Queue.SubmitInfo submitInfo = {
                commandBuffers: [renderCommandBuffer]
            };
            queue.submit([submitInfo], submitFence);
        }
    }

    auto register(void delegate(CommandBuffer) render) {
        this.renderList ~= render;
        updateCommandBuffer();
        return { unregister(render); };
    }

    void unregister(void delegate(CommandBuffer) render) {
        this.renderList = this.renderList.remove!(r => r == render);
        updateCommandBuffer();
    }
}
