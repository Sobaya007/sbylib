module sbylib.graphics.layer.core;

import sbylib.graphics.layer.setting;

class CoreValidationLayerSetting : LayerSetting {

    this() {
        super("lunarg", "core_validation");
    }
    
    mixin Impl;
}
