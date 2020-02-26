module sbylib.graphics.layer.setting;

import std;

struct LayerSettings {
    LayerSetting[] settings;

    enum fileName = "vk_layer_settings.txt";

    void finalize() {
        import std.file : fremove = remove;
        if (fileName.exists)
            fremove(fileName);
    }

    string[] use() {
        writeToFile();
        return getNames();
    }

    private string[] getNames() {
        return settings.map!(s => s.getName()).array;
    }

    private void writeToFile() {
        foreach (setting; settings)
            setting.writeToFile(fileName);
    }
}

class LayerSetting {

    enum setting;

    protected string vendorName;
    protected string layerName;

    enum ReportFlag {
        info = "info",
        warn = "warn",
        perf = "perf",
        error = "error",
        debug_ = "debug"
    }

    enum DebugAction {
        Ignore = "VK_DBG_LAYER_ACTION_IGNORE",
        LogMessage = "VK_DBG_LAYER_ACTION_LOG_MSG",
        DebugOutput = "VK_DBG_LAYER_ACTION_DEBUG_OUTPUT",
    }

    @setting {
        ReportFlag[] report_flags;
        DebugAction debugAction;
        string log_filename;
    }

    this(string vendorName, string layerName) {
        this.vendorName = vendorName;
        this.layerName = layerName;
    }

    string getName() {
        return format!"VK_LAYER_%s_%s"(vendorName.toUpper, layerName);
    }

    abstract void writeToFile(string path);

    mixin template Impl() {
        override void writeToFile(string path) {
            import std : format, join;
            import std.file : fwrite = write;
            import sbylib.graphics.util.member : getMembersByUDA;

            string[] content;
            static foreach (memberInfo; getMembersByUDA!(typeof(this), setting)) {
                content ~= format!"%s_%s.%s = %s"(vendorName, layerName, memberInfo.name, write(memberInfo.member));
            }
            path.fwrite(content.join("\n"));
        }

        private string write(T : bool)(T value) {
            return value ? "TRUE" : "FALSE";
        }

        private string write(T : string)(T value) {
            return value;
        }

        private string write(T : E[], E)(T value) {
            import std : map, join;
            return value.map!(v => write(v)).join(",");
        }

        private string write(T)(T value) {
            import std : to;
            return value.to!string;
        }
    }
}
