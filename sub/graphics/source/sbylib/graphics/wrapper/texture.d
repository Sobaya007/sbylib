module sbylib.graphics.wrapper.texture;

import sbylib.wrapper.vulkan;

interface Texture {
    ImageView imageView();
    Sampler sampler();
}
