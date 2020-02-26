module sbylib.graphics.core.descriptor;

mixin template Descriptor() {
    /*
       UDAs
     */
    enum stages;
    enum vertex;
    struct binding { int binding; }
    struct stage { ShaderStage stage; }
    struct type { DescriptorType type; }
    enum uniform = type(DescriptorType.UniformBuffer);
    enum texture = type(DescriptorType.CombinedImageSampler);
    enum storageBuffer = type(DescriptorType.StorageBuffer);

    mixin template ShaderSource(ShaderStage stage, string code) {
        import std : to;
        import std.string : replace;
        import sbylib.graphics.core.shader : ShaderUtil;

        mixin(q{
            private @stages Pipeline.ShaderStageCreateInfo createShaderModule${stage}(Device device) {
                auto mod = ShaderUtil.createModule(device, stage, code);
                shaderModules ~= mod;

                Pipeline.ShaderStageCreateInfo result = {
                    stage: stage,
                    pName: "main",
                    _module: mod
                };
                return result;
            }
        }.replace("${stage}", stage.to!string));
    }

    mixin template MaxObjects(size_t n) {
        private enum maxObjects = n;
    }

    /*
       resources
     */
    protected @own {
        DescriptorSetLayout descriptorSetLayout;
        DescriptorPool descriptorPool;
        ShaderModule[] shaderModules;
    }
    mixin ImplReleaseOwn;

}

mixin template ImplDescriptor() {
    mixin template DefineInstanceMembers(Descriptor) {
        import sbylib.graphics.util.own : own;
        import sbylib.graphics.util.member : getMembersByUDA;
        import sbylib.graphics.wrapper.buffer : VBuffer;
        import sbylib.graphics.wrapper.texture : Texture;
        import std : format;

        static foreach (memberInfo; getMembersByUDA!(Descriptor, type)) {
            static assert(memberInfo.hasType);
            static assert(memberInfo.hasAttributes);
            static if (is(memberInfo.type : Texture)) {
                alias Type(alias m : memberInfo) = memberInfo.type;
            } else {
                alias Type(alias m : memberInfo) = VBuffer!(memberInfo.type);
            }
            @own @(memberInfo.attributes) mixin(format!q{%s %s;}(Type!(memberInfo).stringof, memberInfo.name));
        }

        private void initializeDefinedBuffers() {
            template getUsage(DescriptorType type) {
                static if (type == DescriptorType.UniformBuffer) {
                    enum getUsage = BufferUsage.UniformBuffer;
                } else static if (type == DescriptorType.StorageBuffer) {
                    enum getUsage = BufferUsage.StorageBuffer;
                }
            }
            static foreach (memberInfo; getMembersByUDA!(typeof(this), type)) {
                static if (isInstanceOf!(VBuffer, memberInfo.type)) {
                    memberInfo.member = new memberInfo.type([memberInfo.type.Type.init], getUsage!(memberInfo.getUDA!(type).type));
                }
            }
        }

        public DescriptorSet createDescriptorSet(Device device, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
            auto result = allocateDescriptorSet(device, descriptorPool, descriptorSetLayout);
            writeDescriptor(result);
            return result;
        }

        private DescriptorSet allocateDescriptorSet(Device device, DescriptorPool descriptorPool, DescriptorSetLayout descriptorSetLayout) {
            DescriptorSet.AllocateInfo descriptorSetAllocInfo = {
                descriptorPool: descriptorPool,
                setLayouts: [descriptorSetLayout]
            };
            return DescriptorSet.allocate(device, descriptorSetAllocInfo)[0];
        }

        private void writeDescriptor(DescriptorSet descriptorSet) {
            import std : isInstanceOf;
            enum N = getMembersByUDA!(typeof(this), type).length;
            static assert(N > 0);
            DescriptorSet.Write[N] writes;

            size_t i;
            static foreach (memberInfo; getMembersByUDA!(typeof(this), type)) {{
                static if (isInstanceOf!(VBuffer, memberInfo.type)) {
                    assert(memberInfo.member, memberInfo.name ~ " is not set.");
                    assert(memberInfo.member.buffer);
                    DescriptorSet.Write w = {
                        dstSet: descriptorSet,
                        dstBinding: memberInfo.getUDA!(binding).binding,
                        dstArrayElement: 0,
                        descriptorType: memberInfo.getUDA!(type).type,
                        bufferInfo: [{
                            buffer: memberInfo.member.buffer,
                            offset: 0,
                            range: memberInfo.type.Type.sizeof
                        }]
                    };
                    writes[i++] = w;
                } else static if (is(memberInfo.type : Texture)) {
                    assert(memberInfo.member, memberInfo.name.stringof ~ " is not set.");
                    assert(memberInfo.member.sampler);
                    assert(memberInfo.member.imageView);
                    DescriptorSet.Write w = {
                        dstSet: descriptorSet,
                        dstBinding: memberInfo.getUDA!(binding).binding,
                        dstArrayElement: 0,
                        descriptorType: memberInfo.getUDA!(type).type,
                        imageInfo: [{
                            sampler: memberInfo.member.sampler,
                            imageView: memberInfo.member.imageView,
                            imageLayout: ImageLayout.ShaderReadOnlyOptimal
                        }]
                    };
                    writes[i++] = w;
                }
            }}
            assert(i == N);
            DescriptorSet.Copy[0] copies;
            descriptorSet.update(writes, copies);
        }
    }

    /*
       Implementation
     */

    private void initializeDescriptor(Device device) {
        this.descriptorSetLayout = createDescriptorSetLayout(device);
        this.descriptorPool = createDescriptorPool(device);
    }

    private DescriptorSetLayout createDescriptorSetLayout(Device device) {
        import sbylib.graphics.util.member : getMembers;

        DescriptorSetLayout.CreateInfo createInfo;

        static foreach (memberInfo; getMembers!(typeof(this))) {
            static foreach (binding; memberInfo.getUDAs!(binding)) {
                static foreach (type; memberInfo.getUDAs!(type)) {
                    static foreach (stage; memberInfo.getUDAs!(stage)) {{
                        DescriptorSetLayout.CreateInfo.Binding b = {
                            binding: binding.binding,
                            descriptorType: type.type,
                            descriptorCount: 1,
                            stageFlags: stage.stage
                        };
                        createInfo.bindings ~= b;
                    }}
                }
            }
        }

        return new DescriptorSetLayout(device, createInfo);
    }

    private DescriptorPool createDescriptorPool(Device device) {
        import sbylib.graphics.util.member : getMembersByUDA;

        int[DescriptorType] counts;
        static foreach (memberInfo; getMembersByUDA!(typeof(this), type)) {
            counts.require(memberInfo.getUDA!(type).type, 0)++;
        }
        DescriptorPool.CreateInfo createInfo = {
            maxSets: maxObjects
        };
        foreach (type, count; counts) {
            DescriptorPool.CreateInfo.DescriptorPoolSize size = {
                type: type,
                descriptorCount: count
            };
            createInfo.poolSizes ~= size;
        }
        assert(createInfo.poolSizes.length > 0);
        return new DescriptorPool(device, createInfo);
    }
}
