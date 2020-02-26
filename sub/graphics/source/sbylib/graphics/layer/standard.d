module sbylib.graphics.layer.standard;

import sbylib.graphics.layer.setting;

class StandardValidationLayerSetting : LayerSetting {

    this() {
        super("lunarg", "standard_validation");
    }
    
    mixin Impl;
}
