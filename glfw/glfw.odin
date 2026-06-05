package myglfw

import "vendor:glfw"

MouseButton :: enum i32 {
    Button1             = glfw.MOUSE_BUTTON_1,
    Button2             = glfw.MOUSE_BUTTON_2,
    Button3             = glfw.MOUSE_BUTTON_3,
    Button4             = glfw.MOUSE_BUTTON_4,
    Button5             = glfw.MOUSE_BUTTON_5,
    Button6             = glfw.MOUSE_BUTTON_6,
    Button7             = glfw.MOUSE_BUTTON_7,
    Button8             = glfw.MOUSE_BUTTON_8,

    Left                = Button1,
    Right               = Button2,
    Middle              = Button3,

    MouseLeft           = Left,
    MouseRight          = Right,
    MouseMiddle         = Middle,
}

// https://www.glfw.org/docs/3.3/input_guide.html#input_key
KeyAction :: enum i32 {
    Press               = glfw.PRESS,
    Repeat              = glfw.REPEAT,
    Release             = glfw.RELEASE,
}

KeyActionToAction :: proc "c" (k : KeyAction) -> Action {
    if k == .Release do return .Release
    else             do return .Press
}

Action :: enum i32 {
    Press               = glfw.PRESS,
    Release             = glfw.RELEASE,
}

// https://www.glfw.org/docs/3.3/group__mods.html
Mods :: distinct bit_set[Mod; i32]
Mod :: enum i32 {
    Shift               = 1,
    Control             = 2,
    Alt                 = 3,
    Super               = 4,
    CapsLock            = 5,
    NumLock             = 6,
}

Scancode :: distinct i32

// https://www.glfw.org/docs/3.3/group__keys.html
Key :: enum i32 {
    Space               = glfw.KEY_SPACE,
    Apostrophe          = glfw.KEY_APOSTROPHE,
    Comma               = glfw.KEY_COMMA,
    Minus               = glfw.KEY_MINUS,
    Period              = glfw.KEY_PERIOD,
    Slash               = glfw.KEY_SLASH,

    Digit0              = glfw.KEY_0,
    Digit1              = glfw.KEY_1,
    Digit2              = glfw.KEY_2,
    Digit3              = glfw.KEY_3,
    Digit4              = glfw.KEY_4,
    Digit5              = glfw.KEY_5,
    Digit6              = glfw.KEY_6,
    Digit7              = glfw.KEY_7,
    Digit8              = glfw.KEY_8,
    Digit9              = glfw.KEY_9,

    Semicolon           = glfw.KEY_SEMICOLON,
    Equal               = glfw.KEY_EQUAL,

    LetterA             = glfw.KEY_A,
    LetterB             = glfw.KEY_B,
    LetterC             = glfw.KEY_C,
    LetterD             = glfw.KEY_D,
    LetterE             = glfw.KEY_E,
    LetterF             = glfw.KEY_F,
    LetterG             = glfw.KEY_G,
    LetterH             = glfw.KEY_H,
    LetterI             = glfw.KEY_I,
    LetterJ             = glfw.KEY_J,
    LetterK             = glfw.KEY_K,
    LetterL             = glfw.KEY_L,
    LetterM             = glfw.KEY_M,
    LetterN             = glfw.KEY_N,
    LetterO             = glfw.KEY_O,
    LetterP             = glfw.KEY_P,
    LetterQ             = glfw.KEY_Q,
    LetterR             = glfw.KEY_R,
    LetterS             = glfw.KEY_S,
    LetterT             = glfw.KEY_T,
    LetterU             = glfw.KEY_U,
    LetterV             = glfw.KEY_V,
    LetterW             = glfw.KEY_W,
    LetterX             = glfw.KEY_X,
    LetterY             = glfw.KEY_Y,
    LetterZ             = glfw.KEY_Z,

    LeftBracket         = glfw.KEY_LEFT_BRACKET,
    Backslash           = glfw.KEY_BACKSLASH,
    RightBracket        = glfw.KEY_RIGHT_BRACKET,
    GraveAccent         = glfw.KEY_GRAVE_ACCENT,

    World1              = glfw.KEY_WORLD_1,
    World2              = glfw.KEY_WORLD_2,

    Escape              = glfw.KEY_ESCAPE,
    Enter               = glfw.KEY_ENTER,
    Tab                 = glfw.KEY_TAB,
    Backspace           = glfw.KEY_BACKSPACE,
    Insert              = glfw.KEY_INSERT,
    Delete              = glfw.KEY_DELETE,

    Right               = glfw.KEY_RIGHT,
    Left                = glfw.KEY_LEFT,
    Down                = glfw.KEY_DOWN,
    Up                  = glfw.KEY_UP,

    PageUp              = glfw.KEY_PAGE_UP,
    PageDown            = glfw.KEY_PAGE_DOWN,
    Home                = glfw.KEY_HOME,
    End                 = glfw.KEY_END,
    CapsLock            = glfw.KEY_CAPS_LOCK,
    ScrollLock          = glfw.KEY_SCROLL_LOCK,
    NumLock             = glfw.KEY_NUM_LOCK,
    PrintScreen         = glfw.KEY_PRINT_SCREEN,
    Pause               = glfw.KEY_PAUSE,

    F1                  = glfw.KEY_F1,
    F2                  = glfw.KEY_F2,
    F3                  = glfw.KEY_F3,
    F4                  = glfw.KEY_F4,
    F5                  = glfw.KEY_F5,
    F6                  = glfw.KEY_F6,
    F7                  = glfw.KEY_F7,
    F8                  = glfw.KEY_F8,
    F9                  = glfw.KEY_F9,
    F10                 = glfw.KEY_F10,
    F11                 = glfw.KEY_F11,
    F12                 = glfw.KEY_F12,
    F13                 = glfw.KEY_F13,
    F14                 = glfw.KEY_F14,
    F15                 = glfw.KEY_F15,
    F16                 = glfw.KEY_F16,
    F17                 = glfw.KEY_F17,
    F18                 = glfw.KEY_F18,
    F19                 = glfw.KEY_F19,
    F20                 = glfw.KEY_F20,
    F21                 = glfw.KEY_F21,
    F22                 = glfw.KEY_F22,
    F23                 = glfw.KEY_F23,
    F24                 = glfw.KEY_F24,
    F25                 = glfw.KEY_F25,

    Keypad0             = glfw.KEY_KP_0,
    Keypad1             = glfw.KEY_KP_1,
    Keypad2             = glfw.KEY_KP_2,
    Keypad3             = glfw.KEY_KP_3,
    Keypad4             = glfw.KEY_KP_4,
    Keypad5             = glfw.KEY_KP_5,
    Keypad6             = glfw.KEY_KP_6,
    Keypad7             = glfw.KEY_KP_7,
    Keypad8             = glfw.KEY_KP_8,
    Keypad9             = glfw.KEY_KP_9,
    KeypadDecimal       = glfw.KEY_KP_DECIMAL,
    KeypadDivide        = glfw.KEY_KP_DIVIDE,
    KeypadMultiply      = glfw.KEY_KP_MULTIPLY,
    KeypadSubtract      = glfw.KEY_KP_SUBTRACT,
    KeypadAdd           = glfw.KEY_KP_ADD,
    KeypadEnter         = glfw.KEY_KP_ENTER,
    KeypadEqual         = glfw.KEY_KP_EQUAL,

    LeftShift           = glfw.KEY_LEFT_SHIFT,
    LeftControl         = glfw.KEY_LEFT_CONTROL,
    LeftAlt             = glfw.KEY_LEFT_ALT,
    LeftSuper           = glfw.KEY_LEFT_SUPER,
    RightShift          = glfw.KEY_RIGHT_SHIFT,
    RightControl        = glfw.KEY_RIGHT_CONTROL,
    RightAlt            = glfw.KEY_RIGHT_ALT,
    RightSuper          = glfw.KEY_RIGHT_SUPER,
    Menu                = glfw.KEY_MENU,

    Unknown             = glfw.KEY_UNKNOWN,
}

CursorInputMode :: enum i32 {
    Normal              = glfw.CURSOR_NORMAL,
    Hidden              = glfw.CURSOR_HIDDEN,
    Disabled            = glfw.CURSOR_DISABLED,
}

GetCursorPosf32 :: proc "c" (window : glfw.WindowHandle) -> [2]f32 {
    x, y := glfw.GetCursorPos(window)
    return { cast(f32)x, cast(f32)y }
}

GetWindowSize :: proc "c" (window : glfw.WindowHandle) -> [2]f32 {
    x, y := glfw.GetWindowSize(window)
    return { cast(f32)x, cast(f32)y }
}

MouseButtonProc :: proc "c" (window : glfw.WindowHandle, button : MouseButton, action : Action, mods : Mods)
SetMouseButtonCallback :: proc "c" (window : glfw.WindowHandle, cbfun : MouseButtonProc) -> MouseButtonProc {
    return cast(MouseButtonProc)glfw.SetMouseButtonCallback(window, cast(glfw.MouseButtonProc)cbfun)
}
