module sbylib.wrapper.glfw.windowbuilder;

import derelict.glfw3.glfw3;
import sbylib.wrapper.glfw.constants : WindowHint;
public import sbylib.wrapper.glfw.constants : ClientAPI, ContextRobustness,
       ContextReleaseBehavior, OpenGLProfile, DontCare;
public import sbylib.wrapper.glfw.screen : Screen;
public import sbylib.wrapper.glfw.window : Window;

/**
Window builder class.
This class cannot be instantiated.
*/
struct WindowBuilder {
    
    private int mWidth = 800, mHeight = 600;
    private string mTitle = "Window Title";

    static WindowBuilder opCall() {
        import sbylib.wrapper.glfw.glfw : GLFW;
        GLFW.initialize();
        WindowBuilder result;
        return result;
    }

    /**
    */
    Window buildWindow(Window share = null) {
        if (share is null)
            return new Window(mWidth, mHeight, mTitle);
        else
            return new Window(mWidth, mHeight, mTitle, share);
    }

    Window buildFullscreenWindow(Window share = null) {
        return buildFullscreenWindow(Screen.getPrimaryScreen(), share);
    }

    Window buildFullscreenWindow(Screen screen, Window share = null) {
        if (share is null)
            return new Window(mWidth, mHeight, mTitle, screen);
        else
            return new Window(mWidth, mHeight, mTitle, screen, share);
    }

    /**
    Set width of window to be created.

    Params:
        width = width of window in pixel

    Returns: given width
    */
    int width(int width) {
        mWidth = width;
        return width;
    }

    /**
    Set height of window to be created.

    Params:
        height = height of window in pixel

    Returns: given height
    */
    int height(int height) {
        mHeight = height;
        return height;
    }

    /**
    Set title of window to be created.

    Params:
        title = title of window

    Returns: given title
    */
    string title(string title) {
        mTitle = title;
        return title;
    }

    void defaultHints() {
        glfwDefaultWindowHints();
    }

    bool resizable(bool resizable) {
        setHint(WindowHint.Resizable, resizable);
        return resizable;
    }

    bool visible(bool visible) {
        setHint(WindowHint.Visible, visible);
        return visible;
    }

    bool decorated(bool decorated) {
        setHint(WindowHint.Decorated, decorated);
        return decorated;
    }

    bool focused(bool focused) {
        setHint(WindowHint.Focused, focused);
        return focused;
    }

    bool autoIconify(bool autoIconify) {
        setHint(WindowHint.AutoIconify, autoIconify);
        return autoIconify;
    }

    bool floating(bool floating) {
        setHint(WindowHint.Floating, floating);
        return floating;
    }

    bool maximized(bool maximized) {
        setHint(WindowHint.Maximized, maximized);
        return maximized;
    }

    int redBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.RedBits, bits);
        return bits;
    }

    int greenBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.GreenBits, bits);
        return bits;
    }

    int blueBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.BlueBits, bits);
        return bits;
    }

    int alphaBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.AlphaBits, bits);
        return bits;
    }

    int depthBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.DepthBits, bits);
        return bits;
    }

    int stencilBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.StencilBits, bits);
        return bits;
    }

    deprecated int accumRedBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.AccumRedBits, bits);
        return bits;
    }

    deprecated int accumGreenBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.AccumGreenBits, bits);
        return bits;
    }

    deprecated int accumBlueBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.AccumBlueBits, bits);
        return bits;
    }

    deprecated int accumAlphaBits(int bits) 
    in (0 <= bits || bits == DontCare)
    {
        setHint(WindowHint.AccumAlphaBits, bits);
        return bits;
    }

    int auxBuffers(int buffers) 
    in (0 <= buffers || buffers == DontCare)
    {
        setHint(WindowHint.AuxBuffers, buffers);
        return buffers;
    }

    int samples(int samples) 
    in (0 <= samples || samples == DontCare)
    {
        setHint(WindowHint.Samples, samples);
        return samples;
    }

    int refreshRate(int refreshRate) 
    in (0 <= refreshRate || refreshRate == DontCare)
    {
        setHint(WindowHint.RefreshRate, refreshRate);
        return refreshRate;
    }

    bool stereo(bool stereo) {
        setHint(WindowHint.Stereo, stereo);
        return stereo;
    }

    bool srgbCapable(bool srgbCapable) {
        setHint(WindowHint.SRGBCapable, srgbCapable);
        return srgbCapable;
    }

    bool doublebuffer(bool doublebuffer) {
        setHint(WindowHint.Doublebuffer, doublebuffer);
        return doublebuffer;
    }

    ClientAPI clientAPI(ClientAPI clientAPI) {
        setHint(WindowHint.ClientAPI, clientAPI);
        return clientAPI;
    }

    int contextVersionMajor(int major) {
        setHint(WindowHint.ContextVersionMajor, major);
        return major;
    }

    int contextVersionMinor(int minor) {
        setHint(WindowHint.ContextVersionMinor, minor);
        return minor;
    }

    int contextRevision(int revision) {
        setHint(WindowHint.ContextRevision, revision);
        return revision;
    }

    ContextRobustness contextRobustness(ContextRobustness contextRobustness) {
        setHint(WindowHint.ContextRobustness, contextRobustness);
        return contextRobustness;
    }

    ContextReleaseBehavior contextReleaseBehavior(ContextReleaseBehavior contextReleaseBehavior) { 
        setHint(WindowHint.ContextReleaseBehavior, contextReleaseBehavior);
        return contextReleaseBehavior;
    }

    bool forwardCompatible(bool compatible) {
        setHint(WindowHint.OpenGLForwardCompat, compatible);
        return compatible;
    }

    bool hasDebugContext(bool hasDebugContext) {
        setHint(WindowHint.OpenGLDebugContext, hasDebugContext);
        return hasDebugContext;
    }

    OpenGLProfile profile(OpenGLProfile profile) {
        setHint(WindowHint.OpenGLProfile, profile);
        return profile;
    }

    private static void setHint(WindowHint hint, bool b) {
        glfwWindowHint(hint, b ? GLFW_TRUE : GLFW_FALSE);
    }

    private static void setHint(WindowHint hint, int value) {
        glfwWindowHint(hint, value);
    }
}

unittest {
    with (WindowBuilder()) {
        width = 300;
        height = 300;
        title = "poyo";
        visible = false;

        auto window = buildWindow();
        scope (exit) window.destroy();

        assert(window.width == 300);
        assert(window.height == 300);
        assert(window.title == "poyo");
        assert(window.visible == false);
    }
}
