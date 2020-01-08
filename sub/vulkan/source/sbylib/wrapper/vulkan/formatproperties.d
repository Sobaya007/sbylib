module sbylib.wrapper.vulkan.formatproperties;

import std;
import erupted;
import sbylib.wrapper.vulkan.util;

struct FormatProperties {

    struct Feature {
        VkFormatFeatureFlags flags;

        bool supports(Flags flag) const {
            return cast(bool)(this.flags & flag);
        }
    }

    @vkProp() {
        VkFormatFeatureFlags    linearTilingFeatures;
        VkFormatFeatureFlags    optimalTilingFeatures;
        VkFormatFeatureFlags    bufferFeatures;
    }

    mixin VkFrom!(VkFormatProperties);

    enum Flags {
        SampledImage = VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT,
        StorageImage = VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT,
        StorageImageAtomic = VK_FORMAT_FEATURE_STORAGE_IMAGE_ATOMIC_BIT,
        UniformTexelBuffer = VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT,
        StorageTexelBuffer = VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT,
        StorageTexelBufferAtomic = VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_ATOMIC_BIT,
        VertexBuffer = VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT,
        ColorAttachment = VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT,
        ColorAttachmentBlend = VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT,
        DepthStencilAttachment = VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT,
        BlitSrc = VK_FORMAT_FEATURE_BLIT_SRC_BIT,
        BlitDst = VK_FORMAT_FEATURE_BLIT_DST_BIT,
        SampledImageFilterLinear = VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT,
        TransferSrc = VK_FORMAT_FEATURE_TRANSFER_SRC_BIT,
        TransferDst = VK_FORMAT_FEATURE_TRANSFER_DST_BIT,
        MidpointChromaSamples = VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT,
        YCBCRConversionLinearFilter = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT,
        YCBCRConversionSeparateReconstructionFilter = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_BIT,
        SampledImageYCBCRConversionChromaReconstructionExplicit = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_BIT,
        SampledImageYCBCRConversionChromaReconstructionExplicitForceable = VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_BIT,
        Disjoint = VK_FORMAT_FEATURE_DISJOINT_BIT,
        CositedChromaSamples = VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT,
        SampedImageFilterCubic = VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG,
        SampledImageFilterMinMax = VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_MINMAX_BIT_EXT,
        FragmentDensityMap = VK_FORMAT_FEATURE_FRAGMENT_DENSITY_MAP_BIT_EXT,
    }

    Feature linearTiling() {
        return Feature(linearTilingFeatures);
    }

    Feature optimalTiling() {
        return Feature(optimalTilingFeatures);
    }

    Feature buffer() {
        return Feature(bufferFeatures);
    }
}
