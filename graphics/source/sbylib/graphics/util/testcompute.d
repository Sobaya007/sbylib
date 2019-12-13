module sbylib.util.testcompute;

import std;
import erupted;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;
import sbylib.math;

import sbylib.graphics.util.buffer;
import sbylib.graphics.util.uniformreference;
import sbylib.graphics.util.compute;
import sbylib.graphics.util.computecontext;
import sbylib.graphics.util.pipelineutil;
import sbylib.graphics.util.own;
import sbylib.graphics.util.vulkancontext;

class TestCompute {
    mixin Compute;
    mixin ImplReleaseOwn;
    
    align(16) struct Data {
        align(16) vec3 a;
        align(16) vec3 b;
        align(4) float c;
    }

    struct Input {
        int len;
        Data[256] data;
    }

    struct Output {
        int len;
        Data[256] data;
    }

    @type(DescriptorType.StorageBuffer) {
        @binding(0) mixin UseBuffer!(Input, "input");
        @binding(1) mixin UseBuffer!(Output, "output");
    }

    this() {
        initialize(q{
            #version 450

            layout(local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

            layout (std140) struct Data {
                vec3 a;
                vec3 b;
                float c;
            };
            layout (binding=0) readonly buffer Input {
                int len;
                Data data[];
            } inputData;
            layout (binding=1) writeonly buffer Output {
                int len;
                Data data[];
            } outputData;
             
            void main() {
                outputData.data[gl_GlobalInvocationID.x] = inputData.data[gl_GlobalInvocationID.x];
            }
        });
        initialize!"input"(Input.sizeof, BufferUsage.StorageBuffer);
        initialize!"output"(Output.sizeof, BufferUsage.StorageBuffer);
        initializeDescriptorSet(VulkanContext.device, descriptorPool, descriptorSetLayout);

        record(256/16, 1, 1);
    }
}
