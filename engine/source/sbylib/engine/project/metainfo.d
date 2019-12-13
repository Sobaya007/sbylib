module sbylib.engine.project.metainfo;

import std;
import dconfig;
import sbylib.engine.util;
import dconfig : config;

class MetaInfo {

    static opCall() {
        static MetaInfo instance;
        if (instance is null)
            instance = new MetaInfo;
        return instance;
    }

    string projectDirectory;
}
