module sbylib.engine.project.metainfo;

import std;
import sbylib.engine.util;

class MetaInfo {

    static opCall() {
        static MetaInfo instance;
        if (instance is null)
            instance = new MetaInfo;
        return instance;
    }

    string projectDirectory;
}
