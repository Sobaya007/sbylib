module sbylib.wrapper.glfw.constants;

import derelict.glfw3.glfw3;

enum DontCare = GLFW_DONT_CARE;

package enum Attribute {
    Focused = GLFW_FOCUSED,
    Iconified = GLFW_ICONIFIED,
    Maximized = GLFW_MAXIMIZED,
    Visible = GLFW_VISIBLE,
    Resizable = GLFW_RESIZABLE,
    Decorated = GLFW_DECORATED,
    Floating = GLFW_FLOATING,
    ClientAPI = GLFW_CLIENT_API,
    ContextVersionMajor = GLFW_CONTEXT_VERSION_MAJOR,
    ContextVersionMinor = GLFW_CONTEXT_VERSION_MINOR,
    ContextRevision = GLFW_CONTEXT_REVISION,
    OpenGLForwardCompat = GLFW_OPENGL_FORWARD_COMPAT,
    OpenGLDebugContext = GLFW_OPENGL_DEBUG_CONTEXT,
    OpenGLProfile = GLFW_OPENGL_PROFILE,
    ContextRobustness = GLFW_CONTEXT_ROBUSTNESS
}

enum ClientAPI {
    OpenGL = GLFW_OPENGL_API,
    OpenGLES = GLFW_OPENGL_ES_API,
    NoAPI = GLFW_NO_API
}

enum ContextCreationAPI {
    NativeAPI = GLFW_NATIVE_CONTEXT_API,
    EglAPI = GLFW_EGL_CONTEXT_API
}

enum OpenGLProfile {
    Core = GLFW_OPENGL_CORE_PROFILE,
    Compat = GLFW_OPENGL_COMPAT_PROFILE,
    Any = GLFW_OPENGL_ANY_PROFILE
}

enum ContextRobustness {
    LoseOnReset = GLFW_LOSE_CONTEXT_ON_RESET,
    NoResetNotification = GLFW_NO_RESET_NOTIFICATION,
    NoSupport = GLFW_NO_ROBUSTNESS
}

enum ContextReleaseBehavior {
    Any = GLFW_ANY_RELEASE_BEHAVIOR,
    Flush = GLFW_RELEASE_BEHAVIOR_FLUSH,
    None = GLFW_RELEASE_BEHAVIOR_NONE
}

package enum WindowHint {
    Resizable = GLFW_RESIZABLE,
    Visible = GLFW_VISIBLE,
    Decorated = GLFW_DECORATED,
    Focused = GLFW_FOCUSED,
    AutoIconify = GLFW_AUTO_ICONIFY,
    Floating = GLFW_FLOATING,
    Maximized = GLFW_MAXIMIZED,
    RedBits = GLFW_RED_BITS,
    GreenBits = GLFW_GREEN_BITS,
    BlueBits = GLFW_BLUE_BITS,
    AlphaBits = GLFW_ALPHA_BITS,
    DepthBits = GLFW_DEPTH_BITS,
    StencilBits = GLFW_STENCIL_BITS,
    AccumRedBits = GLFW_ACCUM_RED_BITS,
    AccumGreenBits = GLFW_ACCUM_GREEN_BITS,
    AccumBlueBits = GLFW_ACCUM_BLUE_BITS,
    AccumAlphaBits = GLFW_ACCUM_ALPHA_BITS,
    AuxBuffers = GLFW_AUX_BUFFERS,
    Stereo = GLFW_STEREO,
    Samples = GLFW_SAMPLES,
    SRGBCapable = GLFW_SRGB_CAPABLE,
    Doublebuffer = GLFW_DOUBLEBUFFER,
    RefreshRate = GLFW_REFRESH_RATE,
    ClientAPI = GLFW_CLIENT_API,
    ContextVersionMajor = GLFW_CONTEXT_VERSION_MAJOR,
    ContextVersionMinor = GLFW_CONTEXT_VERSION_MINOR,
    ContextRevision = GLFW_CONTEXT_REVISION,
    OpenGLForwardCompat = GLFW_OPENGL_FORWARD_COMPAT,
    OpenGLDebugContext = GLFW_OPENGL_DEBUG_CONTEXT,
    OpenGLProfile = GLFW_OPENGL_PROFILE,
    ContextRobustness = GLFW_CONTEXT_ROBUSTNESS,
    ContextReleaseBehavior = GLFW_CONTEXT_RELEASE_BEHAVIOR
}

enum MouseButton {
    Button1 = GLFW_MOUSE_BUTTON_1,
    Button2 = GLFW_MOUSE_BUTTON_2,
    Button3 = GLFW_MOUSE_BUTTON_3,
}

enum KeyButton {
    KeyA = GLFW_KEY_A,
    KeyB = GLFW_KEY_B,
    KeyC = GLFW_KEY_C,
    KeyD = GLFW_KEY_D,
    KeyE = GLFW_KEY_E,
    KeyF = GLFW_KEY_F,
    KeyG = GLFW_KEY_G,
    KeyH = GLFW_KEY_H,
    KeyI = GLFW_KEY_I,
    KeyJ = GLFW_KEY_J,
    KeyK = GLFW_KEY_K,
    KeyL = GLFW_KEY_L,
    KeyM = GLFW_KEY_M,
    KeyN = GLFW_KEY_N,
    KeyO = GLFW_KEY_O,
    KeyP = GLFW_KEY_P,
    KeyQ = GLFW_KEY_Q,
    KeyR = GLFW_KEY_R,
    KeyS = GLFW_KEY_S,
    KeyT = GLFW_KEY_T,
    KeyU = GLFW_KEY_U,
    KeyV = GLFW_KEY_V,
    KeyW = GLFW_KEY_W,
    KeyX = GLFW_KEY_X,
    KeyY = GLFW_KEY_Y,
    KeyZ = GLFW_KEY_Z,

    Key0 = GLFW_KEY_0,
    Key1 = GLFW_KEY_1,
    Key2 = GLFW_KEY_2,
    Key3 = GLFW_KEY_3,
    Key4 = GLFW_KEY_4,
    Key5 = GLFW_KEY_5,
    Key6 = GLFW_KEY_6,
    Key7 = GLFW_KEY_7,
    Key8 = GLFW_KEY_8,
    Key9 = GLFW_KEY_9,

    Left = GLFW_KEY_LEFT,
    Right = GLFW_KEY_RIGHT,
    Up = GLFW_KEY_UP,
    Down = GLFW_KEY_DOWN,

    Comma = GLFW_KEY_COMMA,               /* , */
    Minus = GLFW_KEY_MINUS,               /* - */
    Period = GLFW_KEY_PERIOD,             /* . */
    Slash = GLFW_KEY_SLASH,               /* / */
    Semicolon = GLFW_KEY_SEMICOLON,       /* ; */
    LeftBracket = GLFW_KEY_RIGHT_BRACKET, /* [ */
    RightBracket = GLFW_KEY_BACKSLASH,    /* ] */
    AtMark = GLFW_KEY_LEFT_BRACKET,       /* @ */
    Hat = GLFW_KEY_EQUAL,                 /* ^ */
    BackSlash1 = -125,                    /* \ | */ // scancode: 125
    BackSlash2 = -115,                    /* \ _ */ // scancode: 115

    Space = GLFW_KEY_SPACE,
    Enter = GLFW_KEY_ENTER,
    Escape = GLFW_KEY_ESCAPE,
    LeftShift = GLFW_KEY_LEFT_SHIFT,
    RightShift = GLFW_KEY_RIGHT_SHIFT,
    BackSpace = GLFW_KEY_BACKSPACE,
    Delete = GLFW_KEY_DELETE,
    LeftControl = GLFW_KEY_LEFT_CONTROL,
    RightControl = GLFW_KEY_RIGHT_CONTROL,
    Tab = GLFW_KEY_TAB,
    Insert = GLFW_KEY_INSERT,
    Unknown = GLFW_KEY_UNKNOWN
}

enum ButtonState {
    Press = GLFW_PRESS,
    Release = GLFW_RELEASE,
    Repeat = GLFW_REPEAT
}

enum JoystickState {
    Press = GLFW_PRESS,
    Release = GLFW_RELEASE
}

package enum InputMode {
    Cursor = GLFW_CURSOR,
    StickyKeys = GLFW_STICKY_KEYS,
    StickyMouseButtons = GLFW_STICKY_MOUSE_BUTTONS
}

enum CursorMode {
    Normal = GLFW_CURSOR_NORMAL,
    Hidden = GLFW_CURSOR_HIDDEN,
    Disabled = GLFW_CURSOR_DISABLED
}

enum CursorShape {
    Arrow = GLFW_ARROW_CURSOR,
    IBeam = GLFW_IBEAM_CURSOR,
    CrossHair = GLFW_CROSSHAIR_CURSOR,
    Hand = GLFW_HAND_CURSOR,
    HResize = GLFW_HRESIZE_CURSOR,
    VResize = GLFW_VRESIZE_CURSOR
}

enum ScreenEvent {
    Connected = GLFW_CONNECTED,
    Disconnected = GLFW_DISCONNECTED
}

enum JoyStickEvent {
    Connected = GLFW_CONNECTED,
    Disconnected = GLFW_DISCONNECTED
}

enum ErrorCode {
    NotInitialized = GLFW_NOT_INITIALIZED,
    NoCurrentContext = GLFW_NO_CURRENT_CONTEXT,
    InvalidEnum = GLFW_INVALID_ENUM,
    InvalidValue = GLFW_INVALID_VALUE,
    OutOfMemory = GLFW_OUT_OF_MEMORY,
    ApiUnavailable = GLFW_API_UNAVAILABLE,
    VersionUnavailable = GLFW_VERSION_UNAVAILABLE,
    PlatformError = GLFW_PLATFORM_ERROR,
    FormatUnavailable = GLFW_FORMAT_UNAVAILABLE,
    NoWindowContext = GLFW_NO_WINDOW_CONTEXT
}

enum ModKeyButton {
    Shift = GLFW_MOD_SHIFT,
    Control = GLFW_MOD_CONTROL,
    Alt = GLFW_MOD_ALT,
    Super = GLFW_MOD_SUPER
}
