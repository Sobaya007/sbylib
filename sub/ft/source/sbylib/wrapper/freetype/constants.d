module sbylib.wrapper.freetype.constants;

import derelict.freetype.types;

enum FontType {
    Mono = FT_RENDER_MODE_MONO,
    AntiAlias = FT_RENDER_MODE_NORMAL
}

enum FontLoadType {
    Default = FT_LOAD_DEFAULT,
    NoScale = FT_LOAD_NO_SCALE,
    NoHinting = FT_LOAD_NO_HINTING,
    Render = FT_LOAD_RENDER,
    NoBitmap = FT_LOAD_NO_BITMAP,
    VerticalLayout = FT_LOAD_VERTICAL_LAYOUT,
    ForceAutohint = FT_LOAD_FORCE_AUTOHINT,
    CropBitmap = FT_LOAD_CROP_BITMAP,
    Pedantic = FT_LOAD_PEDANTIC,
    IgnoreGlobalAdvanceWidth = FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH,
    NoRecurse = FT_LOAD_NO_RECURSE,
    IgnoreTransform = FT_LOAD_IGNORE_TRANSFORM,
    Monochrome = FT_LOAD_MONOCHROME,
    LinearDesign = FT_LOAD_LINEAR_DESIGN,
    Color = FT_LOAD_COLOR,
    ComputeMetrics = FT_LOAD_COMPUTE_METRICS,
}
