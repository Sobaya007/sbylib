module sbylib.graphics.util.pipelineutil;

import std;
import erupted;
import sbylib.wrapper.vulkan;
import sbylib.math;
import sbylib.graphics.util.buffer;
import sbylib.graphics.util.rendercontext;

mixin template ImplPipelineUtil(DataSet) {

    private template getFormat(Type) {
        static if (is(Type == float)) {
            enum getFormat = VK_FORMAT_R32_SFLOAT;
        } else static if (is(Type == vec2)) {
            enum getFormat = VK_FORMAT_R32G32_SFLOAT;
        } else static if (is(Type == vec3)) {
            enum getFormat = VK_FORMAT_R32G32B32_SFLOAT;
        } else static if (is(Type == vec4)) {
            enum getFormat = VK_FORMAT_R32G32B32A32_SFLOAT;
        } else static if (is(Type == int)) {
            enum getFormat = VK_FORMAT_R32_SINT;
        } else static if (is(Type == ivec2)) {
            enum getFormat = VK_FORMAT_R32G32_SINT;
        } else static if (is(Type == ivec3)) {
            enum getFormat = VK_FORMAT_R32G32B32_SINT;
        } else static if (is(Type == ivec4)) {
            enum getFormat = VK_FORMAT_R32G32B32A32_SINT;
        } else {
            static assert(false, "Unsupported type: " ~ Type.stringof);
        }
    }

    private ShaderModule createStage(Device device, ShaderStage stage, string code) {
        import std : tempDir, buildPath, executeShell;
        import std.file : write, remove, read;

        const sourceFileName = tempDir.buildPath("test." ~ getStageName(stage));
        sourceFileName.write(code);
        scope (exit)
            sourceFileName.remove();

        const spvFileName = tempDir.buildPath("test.spv");
        const compileResult = executeShell("glslangValidator -e main -V " ~ sourceFileName ~ " -o " ~ spvFileName);
        assert(compileResult.status == 0, compileResult.output);
        scope (exit)
            spvFileName.remove();

        ShaderModule.CreateInfo shaderCreateInfo = {
            code: cast(ubyte[])read(spvFileName)
        };
        return new ShaderModule(device, shaderCreateInfo);
    }

    private string getStageName(ShaderStage stage) {
        switch (stage) {
            case ShaderStage.Vertex: return "vert";
            case ShaderStage.TessellationControl: return "tesc";
            case ShaderStage.TessellationEvaluation: return "tese";
            case ShaderStage.Geometry: return "geom";
            case ShaderStage.Fragment: return "frag";
            case ShaderStage.Compute: return "comp";
           default: assert(false);
        }
    }

    private void initialize(Device device, int maxObjects) {
        enum pred(alias m) = isAggregateType!(typeof(m));
        alias Symbols = Filter!(pred, getSymbolsByUDA!(DataSet, binding));
        enum N = Symbols.length;

        DescriptorSetLayout.CreateInfo.Binding[N] bindings;
        
        static foreach (i; 0..N) {{
            alias mem = Symbols[i];

            static if (is(typeof(mem) == VBuffer!(U), U)) {
                DescriptorSetLayout.CreateInfo.Binding b = {
                    binding: getUDAs!(mem, binding)[0].binding,
                    descriptorType: getUDAs!(mem, type)[0].type,
                    descriptorCount: 1,
                    stageFlags: getUDAs!(mem, stage)[0].stage
                };
                bindings[i] = b;
            } else static if (is(typeof(mem) == Texture)) {
                DescriptorSetLayout.CreateInfo.Binding b = {
                    binding: getUDAs!(mem, binding)[0].binding,
                    descriptorType: getUDAs!(mem, type)[0].type,
                    descriptorCount: 1,
                    stageFlags: getUDAs!(mem, stage)[0].stage
                };
                bindings[i] = b;
            } else {
                static assert(false);
            }
        }}

        DescriptorSetLayout.CreateInfo descriptorSetLayoutInfo = {
            bindings: bindings
        };
        this.descriptorSetLayout = new DescriptorSetLayout(device, descriptorSetLayoutInfo);

        PipelineLayout.CreateInfo pipelineLayoutCreateInfo = {
            setLayouts: [descriptorSetLayout]
        };
        this.pipelineLayout = new PipelineLayout(device, pipelineLayoutCreateInfo);

        DescriptorPool.CreateInfo.DescriptorPoolSize[] poolSizes = descriptorSetLayoutInfo.bindings.map!((binding) {
            DescriptorPool.CreateInfo.DescriptorPoolSize size = {
                type: binding.descriptorType,
                descriptorCount: maxObjects
            };
            return size;
        }).array;
        DescriptorPool.CreateInfo descriptorPoolInfo = {
            poolSizes: poolSizes,
            maxSets: maxObjects
        };
        this.descriptorPool = new DescriptorPool(device, descriptorPoolInfo);
    }
}

struct binding { int binding; }
struct stage { ShaderStage stage; }
struct type { DescriptorType type; }

mixin template DataSet() {
    import std : replace;

    static foreach (ShaderStage ss; EnumMembers!ShaderStage) {
        mixin (q{
            mixin template Use${ss}Uniform(UniformType) {
                mixin ImplUniform!(UniformType, ShaderStage.${ss});
            }
        }.replace("${ss}", ss.to!string));
    }

    protected mixin template ImplUniform(UniformType, ShaderStage ss) {
        import std.conv : to;
        import std.uni : toLower;
        import sbylib.graphics.util.uniformreference : UniformReference;

        mixin(q{
            private @own @type(DescriptorType.UniformBuffer) @stage(ss) VBuffer!UniformType ${name}UniformBuffer;

            protected void initialize${Name}Uniform() {
                this.${name}UniformBuffer = new VBuffer!UniformType([UniformType.init], BufferUsage.UniformBuffer);
            }

            UniformReference!(UniformType) ${name}Uniform() {
                return typeof(return)(${name}UniformBuffer.memory);
            }
        }
        .replace("${name}", ss.to!string[0].toLower ~ ss.to!dstring[1..$])
        .replace("${Name}", ss.to!string));
    }

    mixin template ImplDescriptorSet() {
        import sbylib.graphics.util.pipelineutil;
        
        package @own DescriptorSet descriptorSet;

        protected void initializeDescriptorSet(Device device, DescriptorPool pool, DescriptorSetLayout layout) 
            in (device)
            in (pool)
            in (layout)
        {
            DescriptorSet.AllocateInfo descriptorSetAllocInfo = {
                descriptorPool: pool,
                setLayouts: [layout]
            };
            this.descriptorSet = DescriptorSet.allocate(device, descriptorSetAllocInfo)[0];

            enum pred(alias m) = isAggregateType!(typeof(m));
            alias Symbols = Filter!(pred, getSymbolsByUDA!(typeof(this), binding));
            enum N = Symbols.length;

            DescriptorSet.Write[N] writes;
            static foreach (i; 0..N) {{
                alias mem = Symbols[i];

                assert(mem, mem.stringof ~ " is not set.");

                static if (is(typeof(mem) == VBuffer!(U), U)) {
                    assert(mem.buffer);
                    DescriptorSet.Write w = {
                        dstSet: descriptorSet,
                        dstBinding: getUDAs!(mem, binding)[0].binding,
                        dstArrayElement: 0,
                        descriptorType: getUDAs!(mem, type)[0].type,
                        bufferInfo: [{
                            buffer: mem.buffer,
                            offset: 0,
                            range: U.sizeof
                        }]
                    };
                    writes[i] = w;
                } else static if (is(typeof(mem) == Texture)) {
                    assert(mem.sampler);
                    assert(mem.imageView);
                    DescriptorSet.Write w = {
                        dstSet: descriptorSet,
                        dstBinding: getUDAs!(mem, binding)[0].binding,
                        dstArrayElement: 0,
                        descriptorType: getUDAs!(mem, type)[0].type,
                        imageInfo: [{
                            sampler: mem.sampler,
                            imageView: mem.imageView,
                            imageLayout: ImageLayout.ShaderReadOnlyOptimal
                        }]
                    };
                    writes[i] = w;
                } else {
                    static assert(false);
                }
            }}
            DescriptorSet.Copy[0] copies;
            descriptorSet.update(writes, copies);
        }
    }
}
