module sbylib.wrapper.assimp.constants;

import bindbc.assimp.types;

enum ImporterFlag {
    SupportTextFlavour = aiImporterFlags.SupportTextFlavour,
    SupportBinaryFlavour = aiImporterFlags.SupportBinaryFlavour,
    SupportCompressedFlavour = aiImporterFlags.SupportCompressedFlavour,
    LimitedSupport = aiImporterFlags.LimitedSupport,
    Experimental = aiImporterFlags.Experimental,
}

enum PostProcessFlag {
    None = 0,
    CalcTangentSpace = aiPostProcessSteps.CalcTangentSpace,
    JoinIdenticalVertices = aiPostProcessSteps.JoinIdenticalVertices,
    MakeLeftHanded = aiPostProcessSteps.MakeLeftHanded,
    Triangulate = aiPostProcessSteps.Triangulate,
    RemoveComponent = aiPostProcessSteps.RemoveComponent,
    GenNormals = aiPostProcessSteps.GenNormals,
    GenSmoothNormals = aiPostProcessSteps.GenSmoothNormals,
    SplitLargeMeshes = aiPostProcessSteps.SplitLargeMeshes,
    PreTransformVertices = aiPostProcessSteps.PreTransformVertices,
    LimitBoneWeights = aiPostProcessSteps.LimitBoneWeights,
    ValidateDataStructure = aiPostProcessSteps.ValidateDataStructure,
    ImproveCacheLocality = aiPostProcessSteps.ImproveCacheLocality,
    RemoveRedundantMaterials = aiPostProcessSteps.RemoveRedundantMaterials,
    FixInFacingNormals = aiPostProcessSteps.FixInfacingNormals,
    SortByPType = aiPostProcessSteps.SortByPType,
    FindDegenerates = aiPostProcessSteps.FindDegenerates,
    FindInvalidData = aiPostProcessSteps.FindInvalidData,
    GenUVCoords = aiPostProcessSteps.GenUVCoords,
    TransformUVCoords = aiPostProcessSteps.TransformUVCoords,
    FindInstances = aiPostProcessSteps.FindInstances,
    OptimizeMeshes = aiPostProcessSteps.OptimizeMeshes,
    OptimizeGraph = aiPostProcessSteps.OptimizeGraph,
    FlipUVs = aiPostProcessSteps.FlipUVs,
    FlipWindingOrder = aiPostProcessSteps.FlipWindingOrder,
    SplitByBoneCount = aiPostProcessSteps.SplitByBoneCount,
    Debone = aiPostProcessSteps.Debone,
    ConvertToLeftHanded = aiPostProcessSteps.ConvertToLeftHanded,
    TargetRealtime_Fast = aiPostProcessStepsPreset.TargetRealtime_Fast,
    TargetRealtime_Quality = aiPostProcessStepsPreset.TargetRealtime_Quality,
    TargetRealtime_MaxQuality = aiPostProcessStepsPreset.TargetRealtime_MaxQuality
}

enum DefaultLogStream {
    File = aiDefaultLogStream.FILE,
    Stdout = aiDefaultLogStream.STDOUT,
    Stderr = aiDefaultLogStream.STDERR,
    Debugger = aiDefaultLogStream.DEBUGGER,
}

enum MetaDataType {
    Bool = aiMetadataType.BOOL,
    Int = aiMetadataType.INT32,
    Ulong = aiMetadataType.UINT64,
    Float = aiMetadataType.FLOAT,
    String = aiMetadataType.STRING,
    Vec3 = aiMetadataType.VECTOR3D,
}

enum PrimitiveType {
    Point = aiPrimitiveType.POINT,
    Line = aiPrimitiveType.LINE,
    Triangle = aiPrimitiveType.TRIANGLE,
    Polygon = aiPrimitiveType.POLYGON,
}

enum PropertyTypeInfo {
    Float = aiPropertyTypeInfo.Float,
    String = aiPropertyTypeInfo.String,
    Integer = aiPropertyTypeInfo.Integer,
    Buffer = aiPropertyTypeInfo.Buffer,
}

enum AnimBehaviour {
    Default = aiAnimBehaviour.DEFAULT,
    Constant = aiAnimBehaviour.CONSTANT,
    Linear = aiAnimBehaviour.LINEAR,
    Repeat = aiAnimBehaviour.REPEAT,
}

enum LightSourceType {
    Undefined = aiLightSourceType.UNDEFINED,
    Diredctional = aiLightSourceType.DIRECTIONAL,
    Point = aiLightSourceType.POINT,
    Spot = aiLightSourceType.SPOT,
    Ambient = aiLightSourceType.AMBIENT,
    Area = aiLightSourceType.AREA,
}
