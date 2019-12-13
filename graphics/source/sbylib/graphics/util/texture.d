module sbylib.graphics.util.texture;

import sbylib.wrapper.vulkan;

interface Texture {
    ImageView imageView();
    Sampler sampler();
}
