// Input handler routines, platform-independent.

// This is copied from the Focus version of Input:  https://github.com/focus-editor/focus

/*
  KNOWN PROBLEM: On Windows, keys will be erroneously considered held-down if you press them, alt-tab, then release.
  They'll get un-stuck if you press them again. To be fixed.
 */

#if OS == .WINDOWS {
    #load "windows.jai";
} else #if OS == .LINUX {
    #load "linux.jai";
} else #if OS == .MACOS {
    #load "macos.jai";
}

Event_Type :: enum u32 {  // If we set this to u8, our packing will stop matching C's.
    UNINITIALIZED :: 0;
    KEYBOARD    :: 1;
    TEXT_INPUT  :: 2;
    WINDOW      :: 3;
    MOUSE_WHEEL :: 4;
    QUIT        :: 5;
    DRAG_AND_DROP_FILES :: 6;
}

Key_Current_State :: enum_flags u8 {
    NONE  :: 0x0;
    HELD  :: 0x1;
    START :: 0x4;
    END   :: 0x8;
    REPEAT :: 0x10;
}

// We reserve 32 buttons for each gamepad.
GAMEPAD_BUTTON_COUNT :: 32;

Key_Code :: enum u8 {
    UNKNOWN :: 0x0;

    BACKSPACE :: 0x8;
    TAB :: 0x9;
    LINEFEED :: 0xa;
    CLEAR :: 0xc;
    ENTER :: 0xd;
    SHIFT :: 0x10;
    CONTROL :: 0x11;
    ALT :: 0x12;
    CAPITAL :: 0x14;
    KANA :: 0x15;
    IME_ON :: 0x16;
    JUNJA :: 0x17;
    FINAL :: 0x18;
    HANJA :: 0x19;
    IME_OFF :: 0x1a;
    ESCAPE :: 0x1b;
    CONVERT :: 0x1c;
    NONCONVERT :: 0x1d;
    ACCEPT :: 0x1e;
    MODECHANGE :: 0x1f;
    SPACE :: 0x20;
    PRIOR :: 0x21;
    NEXT :: 0x22;
    HASH :: 0x23;
    QUOTE :: 0x27;
    SELECT :: 0x29;
    PRINT :: 0x2a;
    EQUALS :: 0x2b;
    COMMA :: 0x2c;
    MINUS :: 0x2d;
    PERIOD :: 0x2e;
    SLASH :: 0x2f;
    _0 :: 0x30;
    _1 :: 0x31;
    _2 :: 0x32;
    _3 :: 0x33;
    _4 :: 0x34;
    _5 :: 0x35;
    _6 :: 0x36;
    _7 :: 0x37;
    _8 :: 0x38;
    _9 :: 0x39;
    COLON :: 0x3a;
    SEMICOLON :: 0x3b;
    LESS_THAN :: 0x3c;
    SOMETHING :: 0x3d;
    GREATER_THAN :: 0x3e;
    QUESTION_MARK :: 0x3f;
    AT :: 0x40;
    A :: 0x41;
    B :: 0x42;
    C :: 0x43;
    D :: 0x44;
    E :: 0x45;
    F :: 0x46;
    G :: 0x47;
    H :: 0x48;
    I :: 0x49;
    J :: 0x4a;
    K :: 0x4b;
    L :: 0x4c;
    M :: 0x4d;
    N :: 0x4e;
    O :: 0x4f;
    P :: 0x50;
    Q :: 0x51;
    R :: 0x52;
    S :: 0x53;
    T :: 0x54;
    U :: 0x55;
    V :: 0x56;
    W :: 0x57;
    X :: 0x58;
    Y :: 0x59;
    Z :: 0x5a;
    LEFT_BRACKET :: 0x5b;
    BACKSLASH :: 0x5c;
    RIGHT_BRACKET :: 0x5d;
    SLEEP :: 0x5f;
    BACKQUOTE :: 0x60;
    MULTIPLY :: 0x6a;
    ADD :: 0x6b;
    SEPARATOR :: 0x6c;
    SUBTRACT :: 0x6d;
    DECIMAL :: 0x6e;
    DIVIDE :: 0x6f;
    DELETE :: 0x7f;
    UP :: 0x80;
    DOWN :: 0x81;
    LEFT :: 0x82;
    RIGHT :: 0x83;
    PAGEUP :: 0x84;
    PAGEDOWN :: 0x85;
    HOME :: 0x86;
    END :: 0x87;
    INSERT :: 0x88;
    PAUSE :: 0x89;
    SCROLLLOCK :: 0x8a;
    F1 :: 0x8f;
    F2 :: 0x90;
    F3 :: 0x91;
    F4 :: 0x92;
    F5 :: 0x93;
    F6 :: 0x94;
    F7 :: 0x95;
    F8 :: 0x96;
    F9 :: 0x97;
    F10 :: 0x98;
    F11 :: 0x99;
    F12 :: 0x9a;
    F13 :: 0x9b;
    F14 :: 0x9c;
    F15 :: 0x9d;
    F16 :: 0x9e;
    LEFT_SHIFT :: 0xa0;
    RIGHT_SHIFT :: 0xa1;
    LEFT_CONTROL :: 0xa2;
    RIGHT_CONTROL :: 0xa3;
    LEFT_ALT :: 0xa4;
    RIGHT_ALT :: 0xa5;
    BROWSER_BACK :: 0xa6;
    NUMPAD_0 :: 0xa7;
    NUMPAD_1 :: 0xa8;
    NUMPAD_2 :: 0xa9;
    NUMPAD_3 :: 0xaa;
    NUMPAD_4 :: 0xab;
    NUMPAD_5 :: 0xac;
    NUMPAD_6 :: 0xad;
    NUMPAD_7 :: 0xae;
    NUMPAD_8 :: 0xaf;
    NUMPAD_9 :: 0xb0;
    NUMPAD_MULTIPLY :: 0xb1;
    NUMPAD_DIVIDE :: 0xb2;
    NUMPAD_PLUS :: 0xb3;
    NUMPAD_MINUS :: 0xb4;
    NUMPAD_PERIOD :: 0xb5;
    NUMPAD_ENTER :: 0xb6;
    LAUNCH_APP2 :: 0xb7;
    OEM_1 :: 0xba;
    OEM_PLUS :: 0xbb;
    OEM_COMMA :: 0xbc;
    OEM_MINUS :: 0xbd;
    OEM_PERIOD :: 0xbe;
    OEM_2 :: 0xbf;
    OEM_3 :: 0xc0;
    OEM_4 :: 0xdb;
    OEM_5 :: 0xdc;
    OEM_6 :: 0xdd;
    OEM_7 :: 0xde;
    OEM_8 :: 0xdf;
    OEM_102 :: 0xe2;
    PROCESSKEY :: 0xe5;
    PACKET :: 0xe7;
    MOUSE_BUTTON_LEFT :: 0xe8;
    MOUSE_BUTTON_MIDDLE :: 0xe9;
    MOUSE_BUTTON_RIGHT :: 0xea;
    MOUSE_BUTTON_X1 :: 0xeb;
    MOUSE_BUTTON_X2 :: 0xec;
    PRINTSCREEN :: 0xed;
    ATTN :: 0xf6;
    CRSEL :: 0xf7;
    EXSEL :: 0xf8;
    EREOF :: 0xf9;
    PLAY :: 0xfa;
    ZOOM :: 0xfb;
    NONAME :: 0xfc;
    PA1 :: 0xfd;
    OEM_CLEAR :: 0xfe;


    // WARNING!
    //
    // We make an array whose size is controlled
    // by the last enum value in this array, so if you make
    // really big values to match Unicode code points, our
    // memory usage will become quite sorry.
    //
    //                               -jblow, 19 March 2017
    //
}

// Modifier_Flags used to use #place, but I rewrote it to use a union
// instead .... it is not necessarily clearer though! So I am switching
// it back for now...

Event :: struct {
    Modifier_Flags :: union {
        // Eventually we'd like the *_pressed modifiers to be 1 bit each,
        // but still be nameable as booleans. But for now they're 1 byte each.
        // You can compare them as a u32 using the 'packed' member.

        struct {
            // @@ This is confusing. Below key_pressed means the key was just pressed, here _pressed means the key is held down.
            shift_pressed    := false;
            ctrl_pressed     := false;
            alt_pressed      := false;
            cmd_meta_pressed := false; // Cmd on macOS, Meta on Linux
        }
        packed: u32 = 0;
    }

    type: Event_Type = Event_Type.UNINITIALIZED;

    // If keyboard event:
    key_pressed: u32;  // If not pressed, it's a key release.
    key_code: Key_Code = Key_Code.UNKNOWN;

    using modifier_flags: Modifier_Flags; // Only set for Event_Type.KEYBOARD.

    utf32: u32;  // If TEXT_INPUT.
    repeat := false;  // If KEYBOARD event.
    text_input_count: u16; // If KEYBOARD event that also generated TEXT_INPUT events, this will tell you how many TEXT_INPUT events after this KEYBOARD event were generated.

    typical_wheel_delta: s32;  // Used only for mouse events.
    wheel_delta: s32;          // Used only for mouse events.

    files: [..] string;  // Used only for drag and drop events. Both the array and its contents are heap-allocated, lives until events are reset for the next frame.
}

// Per-frame mouse deltas:
mouse_delta_x: int;
mouse_delta_y: int;
mouse_delta_z: int;

events_this_frame:   [..] Event;
input_button_states: [NUM_BUTTON_STATES] Key_Current_State;
left_shift_released_while_right_shift_held: bool;
right_shift_released_while_left_shift_held: bool;
input_application_has_focus := false;

NUM_BUTTON_STATES :: 256;// #run enum_highest_value(Key_Code) + 1;

Window_Resize_Record :: struct {
    window: Window_Type;
    width:  s32;
    height: s32;
}

Window_Move_Record :: struct {
    window: Window_Type;
    x: s32;
    y: s32;
}

get_window_resizes :: () -> [] Window_Resize_Record {
    // The return value here will stick around in memory until the next call
    // to get_window_resizes (from any thread. Actually this whole module does
    // not deal with threading, so don't do that!)

    if resizes_to_free  array_reset(*resizes_to_free);

    if !pending_resizes return .[];

    array_copy(*resizes_to_free, pending_resizes);
    this_allocation_is_not_a_leak(resizes_to_free.data);

    pending_resizes.count = 0;
    return resizes_to_free;
}

get_window_moves :: () -> [] Window_Move_Record {
    // See notes on get_window_resizes. This works the same way.
    if moves_to_free  array_reset(*moves_to_free);

    if !pending_moves return .[];

    array_copy(*moves_to_free, pending_moves);
    pending_moves.count = 0;
    return moves_to_free;
}

input_per_frame_event_and_flag_update :: () {
    // Called once per frame, probably.

    for events_this_frame {
        array_free(it.files);
    }
    array_reset(*events_this_frame);

    for * input_button_states {
        if it.* & .END || !input_application_has_focus then it.* = .NONE;
        else it.* &= ~(.START | .REPEAT);
    }

    mouse_delta_x = 0;
    mouse_delta_y = 0;
    mouse_delta_z = 0;
}

#scope_module

pending_moves:   [..] Window_Move_Record;
moves_to_free:   [..] Window_Move_Record;

pending_resizes: [..] Window_Resize_Record;
resizes_to_free: [..] Window_Resize_Record;

#import "Basic";
#import "Window_Type";

