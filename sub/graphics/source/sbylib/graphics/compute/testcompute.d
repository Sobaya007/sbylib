module sbylib.graphics.compute.testcompute;

import sbylib.graphics.compute.compute;

class TestCompute : Compute {

    mixin ShaderSource!(ShaderStage.Compute, q{
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

    @storageBuffer @stage(ShaderStage.Compute) {
        @binding(0) Input input;
        @binding(1) Output output;
    }

    mixin MaxObjects!(1);
    mixin Instance;
}
