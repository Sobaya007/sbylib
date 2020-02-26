module sbylib.graphics.core.shader;

import std;
import sbylib.wrapper.vulkan;
import sbylib.graphics.wrapper.device;

class ShaderUtil {
static:

    ShaderModule createModule(ShaderStage stage, string code) {
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
        return new ShaderModule(VDevice(), shaderCreateInfo);
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
}
