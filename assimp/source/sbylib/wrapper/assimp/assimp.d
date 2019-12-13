module sbylib.wrapper.assimp.assimp;

public import sbylib.wrapper.assimp.constants : DefaultLogStream;
import bindbc.assimp;

class Assimp {

static:

    private bool initialized = false;

    void initialize() {
        if (initialized) return;
        initialized = true;

        version(BindAssimp_Static) {}
        else {
            loadAssimp("libassimp.so.5");
        }
    }

    uint[3] getVersion() {
        return [aiGetVersionMajor(), aiGetVersionMinor(), aiGetVersionRevision()];
    }

    string getLegalString() {
        import std.conv : to;

        return aiGetLegalString().to!string;
    }

    uint getCompileFlags() {
        return aiGetCompileFlags();
    }

    auto getPredefinedLogStream(DefaultLogStream name) 
        in (name == DefaultLogStream.Stdout || name == DefaultLogStream.Stderr)
    {
        return aiGetPredefinedLogStream(name, null);
    }

    aiLogStream getPredefinedLogStream(string path) {
        import std.string : toStringz;

        return aiGetPredefinedLogStream(DefaultLogStream.File, path.toStringz);
    }

    void attachLogStream(aiLogStream stream) {
        aiAttachLogStream(&stream);
    }

    void detachLogStream(aiLogStream stream) {
        aiDetachLogStream(&stream);
    }

    void detachAllLogStreams() {
        aiDetachAllLogStreams();
    }

    bool verboseLogging(bool b) {
        aiEnableVerboseLogging(b);
        return b;
    }

    string getErrorString() {
        import std.conv : to;

        return aiGetErrorString().to!string;
    }

    bool isExtensionSupported(string str) {
        import std.string : toStringz;

        return cast(bool)aiIsExtensionSupported(str.toStringz);
    }
}
