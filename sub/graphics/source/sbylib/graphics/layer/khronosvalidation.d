module sbylib.graphics.layer.khronosvalidation;

import sbylib.graphics.layer.setting;

class KhronosValidationLayerSetting : LayerSetting {

    this() {
        super("khronos", "validation");
    }
    
    mixin Impl;
}
