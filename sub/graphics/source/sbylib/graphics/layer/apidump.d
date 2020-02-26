module sbylib.graphics.layer.apidump;

import sbylib.graphics.layer.setting;

class ApiDumpLayerSetting : LayerSetting {

    this() {
        super("lunarg", "api_dump");
    }

    @setting {
        bool detailed = true;
        string file;
        bool no_addr;
        bool flush;
    }
    
    mixin Impl;
}
