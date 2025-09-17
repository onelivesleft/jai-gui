// @TODO

// [ ] Make an example.jai!
// [ ] Windows flickering; warm hystersis?
// [ ] Window flags are funky.
// [ ] Window flag: CAN_FOCUS?

// [ ] skin module parameter
// [.] Windows!
//  [.] Moving / Resizing.
//   [ ] Keep on screen?
//   [ ] Min/Max sizes.
//  [ ] Active window, warm window
// [.] text_box input.  rename text_input and text_box?  Maybe just have one call, with a flag to specify multiline (will still be two widgets behind the scenes).

// [ ] Fix initial rendering when HAS_OS_DPI_SCALING is not set.
// [ ] .REVERSE flag for scrollbars?
// [ ] Should we allow the user to force two widgets to have the same identity? (Return on-screen keyboard unite parts)
// [ ] radio buttons
// [ ] dropdown
// [ ] fx blend colors
// [ ] text_input/_box merge? name?
// [ ] text_input/_box take pointer to string+buffer instead of initial_text
// [.] Move widget timestamps to skin + widget .ANIMATING flag

#load "widgets/widget.jai";
#load "widgets/window.jai";
#load "widgets/window_decoration.jai";
#load "widgets/application_window_decoration.jai";

#load "widgets/button.jai";
#load "widgets/checkbox.jai";
#load "widgets/data_table.jai";
#load "widgets/icon.jai";
#load "widgets/input_box.jai";
#load "widgets/input_line.jai";
#load "widgets/label.jai";
#load "widgets/scrollable_panel.jai";
#load "widgets/scrollbar.jai";

Widget_Types :: Type.[
    Custom_Widget, Window, Window_Decoration, Application_Window_Decoration, Button, Checkbox, Data_Table, Icon, Input_Box, Input_Line, Label, Scrollable_Panel, Scrollbar
];

#run { assert(enum_names(type_of(Widget.type)).count == Widget_Types.count); }

widget_allocator_pool: Flat_Pool;
widget_allocator: Allocator;

warm_widget:  *Widget;    // use is_warm(widget) - state widget needs to be in before it can become hot, typically this means the mouse is hovering over it. *
hot_widget:   *Widget;    // use is_hot(widget) - state widget is in when user is engaging with it with the mouse.
focussed_widget: *Widget;    // use has_focus(widget) - widget is single focus of application, is receiving keyboard input.
// * We can add a mouseless mode where you can select widgets with the keyboard, by cycling with tab for instance.

clicked_widget:  *Widget;    // use was_clicked(widget).  Lasts a single frame, when mouse is clicked on hot_widget.
released_widget:  *Widget;   // use was_released(widget).  Lasts a single frame, when mouse is released on hot_widget.
changed_widget:  *Widget;    // use was_changed(widget).  Lasts a single frame, a widget with a value which changed, e.g. a scrollbar moving.
scrollwheel_widget: *Widget; // At end of frame use_scrollwheel is called on this widget.  Call block_scrollwheel during a frame to stop it (i.e. if you have used the scrollwheel input for something)

Frame_Time :: float64;

frame: struct {
    index := 1;
    time: Frame_Time;
    dt: float;
    no_sleep: bool;
}

application: struct {
    os_window: Window_Creation.Window_Type;
    flags: Application_Window_Flags;
    style: u32;
    hidden_for_startup := true;
    last_set_opacity : u8 = 255;
}

Application_Window_Flags :: enum_flags {
    DEFAULT :: HAS_OS_DPI_SCALING|HAS_OS_DECORATIONS|HAS_SYSTEM_MENU|HAS_TITLE_BAR|HAS_MAXIMIZE|HAS_MINIMIZE|CAN_RESIZE;

    HAS_OS_DPI_SCALING :: 1 << 0;
    HAS_OS_DECORATIONS :: 1 << 1;
    HAS_SYSTEM_MENU :: 1 << 3;
    HAS_TITLE_BAR :: 1 << 4;
    HAS_MAXIMIZE :: 1 << 5 | HAS_SYSTEM_MENU; // Requires system menu to work
    HAS_MINIMIZE :: 1 << 6 | HAS_SYSTEM_MENU; // Requires system menu to work
    CAN_RESIZE :: 1 << 7;

    START_MAXIMIZED :: 1 << 8;
    START_MINIMIZED :: 1 << 9;

    // Default is to open on the monitor the mouse is currently in.
    OPEN_ON_PRIMARY_MONITOR :: 1 << 10;
    _OPEN_ON_MONITOR_SHIFT :: 11;
    OPEN_ON_MONITOR_0 :: 1 << (_OPEN_ON_MONITOR_SHIFT + 0);
    OPEN_ON_MONITOR_1 :: 1 << (_OPEN_ON_MONITOR_SHIFT + 1);
    OPEN_ON_MONITOR_2 :: OPEN_ON_MONITOR_1 | OPEN_ON_MONITOR_0;
    OPEN_ON_MONITOR_3 :: 1 << (_OPEN_ON_MONITOR_SHIFT + 2);
    OPEN_ON_MONITOR_4 :: OPEN_ON_MONITOR_3 | OPEN_ON_MONITOR_0;
    OPEN_ON_MONITOR_5 :: OPEN_ON_MONITOR_3 | OPEN_ON_MONITOR_1;
    OPEN_ON_MONITOR_6 :: OPEN_ON_MONITOR_3 | OPEN_ON_MONITOR_2 | OPEN_ON_MONITOR_1;
    _OPEN_ON_MONITOR_MASK :: OPEN_ON_MONITOR_6;

    // next :: 1 << 14;
}


gui_create_application_window :: (window_title: string, window_width: int, window_height: int, flags := Application_Window_Flags.DEFAULT, window_x := -1, window_y := -1, opacity := 1.0) -> *Panel, *Window_Creation.Window_Type {
    assert(widget_allocator.proc == null, "You should only call gui_create_window once!");

    #if OS == .WINDOWS {
        timeBeginPeriod(1);
        user32   :: #system_library "user32";
        SetThreadDpiAwarenessContext :: (awareness: DPI_AWARENESS_CONTEXT) -> BOOL #foreign user32;
        if !(flags & .HAS_OS_DPI_SCALING)
            SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE);

        // The following would tell windows that we don't look at the system DPI, and so windows should automatically scale
        // for us.  However, that's the default behaviour, so...
        //    user32   :: #system_library "user32";
        //    SetThreadDpiAwarenessContext :: (awareness: DPI_AWARENESS_CONTEXT) -> BOOL #foreign user32;
        //    SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE);  // DPI_AWARENESS_CONTEXT_SYSTEM_AWARE if you want to handle DPI
    }

    widget_allocator.proc = flat_pool_allocator_proc;
    widget_allocator.data = *widget_allocator_pool;

    if !keyboard  keyboard = cast(*Keyboard) *Input.input_button_states;

    application.flags = flags;
    init_pointers();
    init_skin();
    allocate_text_edit(1024);

    // We will open in center of monitor.  By default we'll use the monitor the mouse pointer is in, but this can be changed using the flags parameter.
    // A MonitorInfo flag will tell us which is the primary monitor;
    Desired_Monitor :: struct {
        desired_index := -1;
        current_index := -1;
        found_monitor: HMONITOR;
        found_rect: RECT;
    }

    desired_monitor: Desired_Monitor;

    #if OS == .WINDOWS {
        if flags & (.OPEN_ON_PRIMARY_MONITOR|._OPEN_ON_MONITOR_MASK) {
            desired_monitor.desired_index = cast(int) ifx flags & ._OPEN_ON_MONITOR_MASK
                                                      then ((flags & ._OPEN_ON_MONITOR_MASK) >> flags._OPEN_ON_MONITOR_SHIFT) - 1
                                                      else -1;

            find_desired_monitor :: (hMonitor: HMONITOR, hdcMonitor: HDC, lprcMonitor: *RECT, dwData: LPARAM) -> BOOL #c_call {
                using desired_monitor := cast(*Desired_Monitor) dwData;
                current_index += 1;

                monitor_info := MONITORINFO.{cbSize = size_of(MONITORINFO)};
                MONITORINFOF_PRIMARY :: 0x00000001;
                if !GetMonitorInfoW(hMonitor, *monitor_info)  return 1;  // Continue enumerating

                if desired_index == -1 && monitor_info.dwFlags & MONITORINFOF_PRIMARY
                || desired_index >= 0 && current_index >= desired_index {
                    found_monitor = hMonitor;
                    found_rect = monitor_info.rcMonitor;
                    return 0; // Stop enumerating
                }

                return 1; // Continue enumerating
            }

            EnumDisplayMonitors(null, null, find_desired_monitor, xx *desired_monitor);
        }

        if !desired_monitor.found_monitor {
            mouse_position: POINT;
            if GetCursorPos(*mouse_position) {
                desired_monitor.found_monitor = MonitorFromPoint(mouse_position, MONITOR_DEFAULTTONEAREST);
                monitor_info := MONITORINFO.{cbSize = size_of(MONITORINFO)};
                if GetMonitorInfoW(desired_monitor.found_monitor, *monitor_info) {
                    desired_monitor.found_rect = monitor_info.rcMonitor;
                }
            }
        }

        if desired_monitor.found_monitor {
            screen := desired_monitor.found_rect;
            if window_x == -1 { // unset, so center
                window_x = screen.left + (screen.right - screen.left - window_width) / 2;
                window_y = screen.top + (screen.bottom - screen.top - window_height) / 2;
            }
            else {
                window_x += screen.left;
                window_y += screen.top;
                if window_x + window_width > screen.right  window_x = screen.right - window_width;
                if window_y + window_height > screen.bottom  window_y = screen.bottom - window_height;
            }
        }

        application.style = 0;
        if flags & .HAS_TITLE_BAR    application.style |= WS_CAPTION;
        if flags & .HAS_SYSTEM_MENU  application.style |= WS_SYSMENU;
        if flags & .HAS_MAXIMIZE     application.style |= WS_MAXIMIZEBOX;
        if flags & .HAS_MINIMIZE     application.style |= WS_MINIMIZEBOX;
        if flags * .START_MAXIMIZED  application.style |= WS_MAXIMIZE;
        if flags * .START_MINIMIZED  application.style |= WS_MINIMIZE;

        if flags & .CAN_RESIZE       application.style |= WS_THICKFRAME;
        else                         application.style |= WS_BORDER;

        application.os_window = Window_Creation.create_window(window_width, window_height, window_title, window_x, window_y, application.style);
        Input.window_remove_all_decorations = !(flags & .HAS_OS_DECORATIONS);
    }
    else {
        application.os_window = Window_Creation.create_window(window_width, window_height, window_title, window_x, window_y);
    }

    gui_application_window_set_opacity(opacity);

    Simp.set_render_target(application.os_window);
    register_application_window_size(window_width, window_height);

    array_reset(*placement_spacing);
    array_add(*placement_spacing, .{0, 0});

    array_reset(*placement_panel);

    return *application_panel, *application.os_window;
}

gui_begin_frame :: () -> should_quit: bool {
    // We hide the application window for a couple of frames, so everything looks good when it's shown
    if application.hidden_for_startup && frame.index > 1 {
        application.hidden_for_startup = false;
        width := cast(s32) application_panel.calculated_rect.w;
        height := cast(s32) application_panel.calculated_rect.h;

        user32 :: #system_library "user32";
        ShowWindow :: (hwnd: *void, show: s32) #foreign user32;
        ShowWindow(application.os_window, 1);
        //SetWindowLongW(application.os_window, GWL_STYLE, cast(s32) application_window_style);
        SetWindowPos(application.os_window, null, -1, -1, width, height, SWP_NOZORDER|SWP_NOMOVE|SWP_NOACTIVATE|SWP_FRAMECHANGED);
    }

    // First, clean up the previous frame.

    pointer_end_frame();

    if mouse.left_button_held {
        if mouse.left_button_start && hot_widget != focussed_widget && focussed_widget
            remove_focus(focussed_widget);
    }
    else if hot_widget {
        widget_lost_hot_time(hot_widget, frame.time);
        hot_widget = null;
    }

    if next_warm_widget {
        if warm_widget != next_warm_widget
            set_warm_widget(next_warm_widget, true);
    }
    else if warm_widget {
        set_warm_widget(warm_widget, false);
    }

    if next_warm_window {
        if warm_window != next_warm_window
            set_warm_window(next_warm_window, true);
    }
    else if warm_window {
        set_warm_window(warm_window, false);
    }

    if scrollwheel_widget  use_scrollwheel(scrollwheel_widget);
    scrollwheel_widget = next_scrollwheel_widget;

    if tooltip_widget && tooltip_widget != prev_tooltip_widget
        became_tooltip_widget_time = frame.time;
    prev_tooltip_widget = tooltip_widget;
    if tooltip_widget && tooltip_widget.tooltip && frame.time - became_tooltip_widget_time > theme.tooltip_delay
        draw_tooltip(tooltip_widget);

    Simp.swap_buffers(application.os_window);

    if !frame.no_sleep
    && hot_widget_frame_index != frame.index
    && warm_widget_frame_index != frame.index
    && warm_window_frame_index != frame.index
    && !clicked_widget && !released_widget && !changed_widget {
        // Nothing immediate happened so sleep a little
        dt := seconds_since_init() - frame.time;
        ms := clamp(10 - cast(s32)(dt * 1000), 1, 10);
        sleep_milliseconds(ms);
    }

    reset_temporary_storage();

    // Now that previous frame is cleaned up, start this one!

    frame.index += 1;
    prev_frame_time = frame.time;
    frame.time = seconds_since_init();
    frame.dt = cast(float)(frame.time - prev_frame_time);
    frame.no_sleep = false;

    tooltip_widget = null;
    clicked_widget = null;
    released_widget = null;
    changed_widget = null;
    next_warm_widget = null;
    next_warm_window = null;
    next_scrollwheel_widget = null;

    Input.window_region_override = application_window_decoration_override;
    application_window_decoration_override = .NONE;
    #if BACKGROUND_DRAGS_OS_WINDOW {
        if !warm_widget && !hot_widget
            Input.window_region_override = .TITLE_BAR;
    }

    maybe_calculate_rect(*application_panel);

    Input.update_window_events();

    for Input.get_window_resizes() {
        Simp.update_window(it.window);

        if it.window == application.os_window
            register_application_window_size(it.width, it.height);
    }

    characters_typed_this_frame.data = characters_typed_this_frame_buffer.data;
    characters_typed_this_frame.count = 0;

    for event: Input.events_this_frame {
        if event.type == .QUIT  should_quit = true;

        if event.type == {
            case .TEXT_INPUT;
                utf8_string := "";
                utf8_string.data = characters_typed_this_frame.data + characters_typed_this_frame.count;
                character_utf32_to_utf8(event.utf32, *utf8_string);
                characters_typed_this_frame.count += utf8_string.count;

            case .DRAG_AND_DROP_FILES;
            //for dropped_files free(it);
            //array_reset(*dropped_files);
            //for event.files array_add(*dropped_files, copy_string(it));
        }
    }

    combine_keys :: (combined_key: *Key_State, left_key: Key_State, right_key: Key_State) {
        combined_key.* = .NONE;
        if left_key {
            if right_key {
                combined_key.* = .HELD;
                if left_key & right_key & .HELD
                    combined_key.* |= .HELD;
                if left_key & right_key & .END
                    combined_key.* |= .END;
            }
            else {
                combined_key.* = left_key;
            }
        }
        else if right_key {
            combined_key.* = right_key;
        }
        combined_key.* |= left_key & .REPEAT | right_key & .REPEAT;
    }

    combine_keys(*keyboard.shift, keyboard.left_shift, keyboard.right_shift);
    combine_keys(*keyboard.control, keyboard.left_control, keyboard.right_control);
    combine_keys(*keyboard.alt, keyboard.left_alt, keyboard.right_alt);

    Simp.update_window(application.os_window);
    clear_window();

    prev_x := mouse.x;
    prev_y := mouse.y;
    mouse_x, mouse_y := Window_Creation.get_mouse_pointer_position(application.os_window, false);
    mouse.x = xx mouse_x;
    mouse.y = xx mouse_y;
    mouse.dx = mouse.x - prev_x;
    mouse.dy = mouse.y - prev_y;

    mouse.left_button_start = xx (button_state(.MOUSE_BUTTON_LEFT) & .START);
    mouse.left_button_held = xx (button_state(.MOUSE_BUTTON_LEFT) & .HELD);
    mouse.left_button_end   = xx (button_state(.MOUSE_BUTTON_LEFT) & .END);

    mouse.middle_button_start = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .START);
    mouse.middle_button_held = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .HELD);
    mouse.middle_button_end   = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .END);

    mouse.right_button_start = xx (button_state(.MOUSE_BUTTON_RIGHT) & .START);
    mouse.right_button_held = xx (button_state(.MOUSE_BUTTON_RIGHT) & .HELD);
    mouse.right_button_end   = xx (button_state(.MOUSE_BUTTON_RIGHT) & .END);


    mouse.scrollwheel = Input.mouse_delta_z / mouse.scrollwheel_resolution;
    mouse.scrollwheel_fraction += (Input.mouse_delta_z % mouse.scrollwheel_resolution) / cast(float)mouse.scrollwheel_resolution;
    if mouse.scrollwheel_fraction <= -1.0 {
        mouse.scrollwheel -= 1;
        mouse.scrollwheel_fraction += 1.0;
    }
    else if mouse.scrollwheel_fraction >= 1.0 {
        mouse.scrollwheel += 1;
        mouse.scrollwheel_fraction -= 1.0;
    }

    return should_quit;
}

gui_application_window_set_opacity :: (opacity: float, min_opacity := 0.1) {
    // WARNING! If you set the opacity too low you will make it very hard for the user to interact with your program!
    // Leave the min_opacity alone unless you really mean it.

    #if OS == .WINDOWS {
        clamped := clamp(opacity, min_opacity, 1.0);
        a := cast(u8) clamp(clamped * 256, 0, 255);
        if application.last_set_opacity == a
            return;

        if a < 255 {
            if application.last_set_opacity == 255 {
                extended_style := GetWindowLongW(application.os_window, GWL_EXSTYLE);
                extended_style |= WS_EX_LAYERED;
                SetWindowLongW(application.os_window, GWL_EXSTYLE, extended_style);
            }
            LWA_ALPHA :: 2;
            user32 :: #system_library "user32";
            SetLayeredWindowAttributes :: (hwnd: *void, crKey: u32, bAlpha: u8, dwFlags: u32) -> bool #foreign user32;
            SetLayeredWindowAttributes(application.os_window, 0, a, LWA_ALPHA);
        }
        else { // We must have been translucent to get here, so just remove the style that enables opacity.
            extended_style := GetWindowLongW(application.os_window, GWL_EXSTYLE);
            extended_style &= ~cast(s32)WS_EX_LAYERED;
            SetWindowLongW(application.os_window, GWL_EXSTYLE, extended_style);
        }

        application.last_set_opacity = a;
    }
}

gui_draw_windows :: () {
    bring_to_front_window: *Window;

    for key: window_order {
        window, was_added := find_or_add(*window_data, key);
        assert(!was_added, "Didn't find the window in the window_data table, but it should be there!");

        if window.flags & .SHOW && window.is_open {
            currently_drawing_window = window;
            update_widget(window);

            border := draw_window(.BACKGROUND);
            maybe_calculate_rect(border);
            window.border_rect = border.calculated_rect;

            {
                calculate_virtual_panel(window);
                with_panel(window.virtual_panel);
                with_scissor(window.calculated_rect, window.flags);

                reset_drawn_widget_bounds();
                window.draw_proc(window);
                window.drawn_bounds = drawn_widget_bounds;
            }

            update_window(window);
            draw_window(.FOREGROUND);

            if draw_debug_widget_frames  draw_outline(border, .{1.0, 1.0, 0.0, 1.0});

            if clicked_window == window  bring_to_front_window = clicked_window;
        }
        window.flags |= ~.SHOW;
    }

    if bring_to_front_window  bring_to_front(bring_to_front_window);

    if currently_dragging_window && !mouse.left_button_held
        currently_dragging_window = null;

    if currently_dragging_window
        update_window_drag(currently_dragging_window);

    currently_drawing_window = null;

    // If mouse was clicked on the background (i.e. no window) then set window focus to nothing.
    if mouse.left_button_start && hot_widget_frame_index != frame.index && focussed_window
        focus_window(null);

    if !next_warm_window && warm_window
        request_window_warmth(null);
}

gui_has_mouse :: () -> bool {
    return warm_widget || hot_widget;
}

gui_has_keyboard :: () -> bool {
    return focussed_widget != null;
}

gui_no_sleep_this_frame :: () {
    frame.no_sleep = true;
}

gui_debug_panel :: (panel: *Panel) {
    log :: (position: *Panel, format_string: string, args: .. Any) {
        label(position, tprint(format_string, .. args), flags=.FIXED);
    }

    log(at_top(panel, 20), "Warm Widget:     %  %", warm_widget, ifx warm_widget then warm_widget.*);
    log(at(.COPY_DOWN),    "Hot Widget:      %", hot_widget);
    log(at(.COPY_DOWN),    "Warm Window:     %", warm_window);
    log(at(.COPY_DOWN),    "Focussed Window: %", focussed_window);
}

gui_debug_widget_frames :: (on: bool) {
    draw_debug_widget_frames = on;
}

mouse: struct {
    x, y: float;
    #place x;
    position: Vector2;

    dx, dy: float;
    #place dx;
    delta: Vector2;

    left_button_start, left_button_end, left_button_held: bool;
    middle_button_start, middle_button_end, middle_button_held: bool;
    right_button_start, right_button_end, right_button_held: bool;
    scrollwheel: int;             // normalized, will typically be -1, +1 or 0
    scrollwheel_fraction: float;  // on devices with high-precision wheels this can be (-1.0, +1.0)
                                  // (though you can typically ignore it as it will automaticaly accumulate
                                  //  into scrollwheel)
    scrollwheel_resolution :: 120;
}

keyboard: *Keyboard;
Key_Code :: Input.Key_Code;
Key_State :: Input.Key_Current_State;

#scope_file

characters_typed_this_frame_buffer: [1024] u8;
characters_typed_this_frame := "";

#scope_export

// Generated from #insert below when absent - if you want to regenerate it, delete it, then paste it back from added_strings.
Keyboard :: struct {
    keys: [256] Key_State;

    #place keys;
    unknown: Key_State;
    __pad1: [7] Key_State;
    backspace: Key_State;
    tab: Key_State;
    linefeed: Key_State;
    __pad2: [1] Key_State;
    clear: Key_State;
    enter: Key_State;
    __pad3: [2] Key_State;
    shift: Key_State;
    control: Key_State;
    alt: Key_State;
    __pad4: [1] Key_State;
    capslock: Key_State;
    kana: Key_State;
    ime_on: Key_State;
    junja: Key_State;
    final: Key_State;
    hanja: Key_State;
    ime_off: Key_State;
    escape: Key_State;
    convert: Key_State;
    nonconvert: Key_State;
    accept: Key_State;
    modechange: Key_State;
    space: Key_State;
    prior: Key_State;
    next: Key_State;
    hash: Key_State;
    __pad5: [3] Key_State;
    quote: Key_State;
    __pad6: [1] Key_State;
    select: Key_State;
    print: Key_State;
    equals: Key_State;
    comma: Key_State;
    minus: Key_State;
    period: Key_State;
    slash: Key_State;
    _0: Key_State;
    _1: Key_State;
    _2: Key_State;
    _3: Key_State;
    _4: Key_State;
    _5: Key_State;
    _6: Key_State;
    _7: Key_State;
    _8: Key_State;
    _9: Key_State;
    colon: Key_State;
    semicolon: Key_State;
    less_than: Key_State;
    something: Key_State;
    greater_than: Key_State;
    question_mark: Key_State;
    at: Key_State;
    a: Key_State;
    b: Key_State;
    c: Key_State;
    d: Key_State;
    e: Key_State;
    f: Key_State;
    g: Key_State;
    h: Key_State;
    i: Key_State;
    j: Key_State;
    k: Key_State;
    l: Key_State;
    m: Key_State;
    n: Key_State;
    o: Key_State;
    p: Key_State;
    q: Key_State;
    r: Key_State;
    s: Key_State;
    t: Key_State;
    u: Key_State;
    v: Key_State;
    w: Key_State;
    x: Key_State;
    y: Key_State;
    z: Key_State;
    left_bracket: Key_State;
    backslash: Key_State;
    right_bracket: Key_State;
    __pad7: [1] Key_State;
    sleep: Key_State;
    backquote: Key_State;
    __pad8: [9] Key_State;
    multiply: Key_State;
    add: Key_State;
    separator: Key_State;
    subtract: Key_State;
    decimal: Key_State;
    divide: Key_State;
    __pad9: [15] Key_State;
    delete: Key_State;
    up: Key_State;
    down: Key_State;
    left: Key_State;
    right: Key_State;
    pageup: Key_State;
    pagedown: Key_State;
    home: Key_State;
    end: Key_State;
    insert: Key_State;
    pause: Key_State;
    scrolllock: Key_State;
    __pad10: [4] Key_State;
    f1: Key_State;
    f2: Key_State;
    f3: Key_State;
    f4: Key_State;
    f5: Key_State;
    f6: Key_State;
    f7: Key_State;
    f8: Key_State;
    f9: Key_State;
    f10: Key_State;
    f11: Key_State;
    f12: Key_State;
    f13: Key_State;
    f14: Key_State;
    f15: Key_State;
    f16: Key_State;
    __pad11: [1] Key_State;
    left_shift: Key_State;
    right_shift: Key_State;
    left_control: Key_State;
    right_control: Key_State;
    left_alt: Key_State;
    right_alt: Key_State;
    browser_back: Key_State;
    numpad_0: Key_State;
    numpad_1: Key_State;
    numpad_2: Key_State;
    numpad_3: Key_State;
    numpad_4: Key_State;
    numpad_5: Key_State;
    numpad_6: Key_State;
    numpad_7: Key_State;
    numpad_8: Key_State;
    numpad_9: Key_State;
    numpad_multiply: Key_State;
    numpad_divide: Key_State;
    numpad_plus: Key_State;
    numpad_minus: Key_State;
    numpad_period: Key_State;
    numpad_enter: Key_State;
    launch_app2: Key_State;
    __pad12: [2] Key_State;
    oem_1: Key_State;
    oem_plus: Key_State;
    oem_comma: Key_State;
    oem_minus: Key_State;
    oem_period: Key_State;
    oem_2: Key_State;
    oem_3: Key_State;
    __pad13: [26] Key_State;
    oem_4: Key_State;
    oem_5: Key_State;
    oem_6: Key_State;
    oem_7: Key_State;
    oem_8: Key_State;
    __pad14: [2] Key_State;
    oem_102: Key_State;
    __pad15: [2] Key_State;
    processkey: Key_State;
    __pad16: [1] Key_State;
    packet: Key_State;
    mouse_button_left: Key_State;
    mouse_button_middle: Key_State;
    mouse_button_right: Key_State;
    mouse_button_x1: Key_State;
    mouse_button_x2: Key_State;
    printscreen: Key_State;
    application: Key_State;
    __pad17: [7] Key_State;
    attn: Key_State;
    crsel: Key_State;
    exsel: Key_State;
    ereof: Key_State;
    play: Key_State;
    zoom: Key_State;
    noname: Key_State;
    pa1: Key_State;
    oem_clear: Key_State;

    any_typing_this_frame :: () -> bool {
        return characters_typed_this_frame.count > 0;
    }

    eat_typed_this_frame :: () -> string {
        s := characters_typed_this_frame;
        characters_typed_this_frame.count = 0;
        return s;
    }
}

#assert cast(*void)*keyboard.oem_clear - cast(*void)*keyboard.keys == cast(int) Key_Code.OEM_CLEAR;

#if !#exists(Keyboard) #insert -> string {
    builder: String_Builder;
    append(*builder, #string __jai
Keyboard :: struct {
    keys: [256] Key_State;

    #place keys;
    __jai);

    names := enum_names(Key_Code);
    values := enum_values_as_s64(Key_Code);
    previous_value := -1;
    pad_count := 0;
    for 0 .. names.count - 1 {
        value := values[it];
        name := copy_string(names[it]);
        for 0 .. name.count - 1  name[it] = to_lower(name[it]);
        if value > previous_value + 1 {
            pad_count += 1;
            print_to_builder(*builder, #string __jai
    __pad%: [%] Key_State;
            __jai, pad_count, value - previous_value - 1);
        }
        print_to_builder(*builder, #string __jai
    %: Key_State;
        __jai, name);
        previous_value = value;
    }
    append(*builder, #string __jai

    any_typing_this_frame :: () -> bool {
        return characters_typed_this_frame.count > 0;
    }

    eat_typed_this_frame :: () -> string {
        s := characters_typed_this_frame;
        characters_typed_this_frame.count = 0;
        return s;
    }
}
    __jai);
    return builder_to_string(*builder);
}


was_clicked :: inline (key_state: Key_State, ignore_repeat := false) -> bool {
    if ignore_repeat   return cast(bool) key_state & .START && !(key_state & .REPEAT);
    else               return cast(bool) key_state & .START;
}

was_released :: inline (key_state: Key_State) -> bool {
    return cast(bool) key_state & .END;
}

Flags :: enum_flags u64 {
    NONE    :: 0;

    // Masked out to get text align.
    LEFT   :: 1; // @Window title bar
    RIGHT  :: 2;
    CENTER :: 3;

    // Masked out to get font style.
    SANS            :: 4; // @Window
    SERIF           :: 8;
    FIXED           :: 12;
    SANS_ALTERNATE  :: 16;
    SERIF_ALTERNATE :: 20;
    FIXED_ALTERNATE :: 24;
    ICON            :: 28;

    // Masked out to get theme index (set none of these for default theme).
    THEME_A :: 32; // @Window
    THEME_B :: 64;
    THEME_C :: 96;

    ALTERNATE :: 128;      // Alternate style
    ICON_ON_RIGHT :: 128;  // For button
    NO_WRAP :: 128;        // Text box

    // Scrollbar
    SMOOTH :: 1 << 8;
    REVERSE_SCROLLWHEEL;  // Inverts scrollwheel direction

    // Flags
    LOCKED;   // @Window
    INTERACTS;  // Overrides LOCKED (a widget is only locked if LOCKED & !INTERACTS)
    READ_ONLY;
    OVERFLOW;   // Don't scissor // @Window
    CROP;       // Do scissor even if OVERFLOW is set
    FIT;
    IMMEDIATE;  // Update value immediately, rather than when user completes action
    USE_SCROLLWHEEL; // @Window

    // Window
    SHOW;                  // Reset every frame, set when user calls show_window.
    HAS_BEEN_SHOWN;
    INITIALLY_CLOSED;
    BORDER;
    CAN_MOVE;
    CAN_RESIZE;
    SCROLLBARS;

    // Window_Decoration and Application_Window_Decoration
    RESIZE_N :: 1 << 26;
    RESIZE_E :: 1 << 27;
    RESIZE_S :: 1 << 28;
    RESIZE_W :: 1 << 29;
    RESIZE_NE :: RESIZE_N|RESIZE_E;
    RESIZE_NW :: RESIZE_N|RESIZE_W;
    RESIZE_SE :: RESIZE_S|RESIZE_E;
    RESIZE_SW :: RESIZE_S|RESIZE_W;
    RESIZE :: RESIZE_SE;
    MOVE :: RESIZE_N|RESIZE_E|RESIZE_S|RESIZE_W;
    TITLE_BAR :: 1 << 30;
    CLOSE;
    SCROLLBAR_HORIZONTAL;
    SCROLLBAR_VERTICAL;
    MAXIMIZE;
    MINIMIZE;
}

is_locked :: inline (flags: Flags) -> bool { return (flags & .LOCKED) && !(flags & .INTERACTS); }
is_locked :: inline (widget: Widget) -> bool { return is_locked(widget.flags); }

should_scissor :: inline (flags: Flags) -> bool { return !(flags & .OVERFLOW) || (flags & .CROP); }
should_scissor :: inline (widget: *Widget) -> bool { return should_scissor(widget.flags); }


fit_width :: (rect: Rect, flags: Flags) -> float {
    return ifx flags & .FIT then rect.w else 0;
}


text_align_mask : u64 : 0b11;

Text_Alignment :: enum u8 {
    DEFAULT :: 0;
    LEFT    :: 1;
    RIGHT   :: 2;
    CENTER  :: 3;
}

text_alignment_from_flags :: (flags: Flags, default_text_alignment: Text_Alignment) -> Text_Alignment {
    text_align : Text_Alignment = xx (text_align_mask & xx flags);
    if text_align  return text_align;
    else           return default_text_alignment;
}

left_align :: #bake_arguments text_alignment_from_flags(default_text_alignment=.LEFT);
center_align :: #bake_arguments text_alignment_from_flags(default_text_alignment=.CENTER);
right_align :: #bake_arguments text_alignment_from_flags(default_text_alignment=.RIGHT);


font_style_mask : u64 : 0b11100;

Font_Style :: enum u8 {
    DEFAULT         :: 0;
    SANS            :: 1;
    SERIF           :: 2;
    FIXED           :: 3;
    SANS_ALTERNATE  :: 4;
    SERIF_ALTERNATE :: 5;
    FIXED_ALTERNATE :: 6;
    ICON            :: 7;
}

flags_from_font_style :: (font_style: Font_Style) -> Flags {
    return xx font_style << 2;
}

font_style_from_flags :: (flags: Flags, default_font_style: Font_Style) -> Font_Style {
    font_style : Font_Style = xx ((font_style_mask & xx flags) >> 2);
    if font_style  return font_style;
    else           return default_font_style;
}

sans_font ::  #bake_arguments font_style_from_flags(default_font_style=.SANS);
serif_font :: #bake_arguments font_style_from_flags(default_font_style=.SERIF);
fixed_font :: #bake_arguments font_style_from_flags(default_font_style=.FIXED);
sans_alternate_font ::  #bake_arguments font_style_from_flags(default_font_style=.SANS_ALTERNATE);
serif_alternate_font :: #bake_arguments font_style_from_flags(default_font_style=.SERIF_ALTERNATE);
fixed_alternate_font :: #bake_arguments font_style_from_flags(default_font_style=.FIXED_ALTERNATE);
icon_font :: #bake_arguments font_style_from_flags(default_font_style=.ICON);

theme_index_mask : u64 : 0b1100000;

theme_index :: (flags: Flags) -> int {
    return xx (theme_index_mask & xx flags) >> 5;
}

get_theme :: (widget: *Widget) -> Theme {
    return ifx is_locked(widget.flags) then locked_theme else themes[theme_index(widget.flags)];
}

window_decoration_inherit_mask :: text_align_mask | font_style_mask | theme_index_mask;

prev_frame_time: float64;
next_warm_widget: *Widget;
next_warm_window: *Window;
next_scrollwheel_widget: *Widget;
tooltip_widget: *Widget;
prev_tooltip_widget: *Widget;
became_tooltip_widget_time: float64;
hot_widget_frame_index: int;
warm_widget_frame_index: int;
warm_window_frame_index: int;
application_window_decoration_override : type_of(Input.window_region_override) = .NONE;

is_warm :: inline (widget: *Widget) -> bool {
    return widget == warm_widget;
}

is_hot :: inline (widget: *Widget) -> bool {
    return widget == hot_widget;
}

has_focus :: inline (widget: *Widget) -> bool {
    return widget == focussed_widget;
}

was_clicked :: inline (widget: *Widget) -> bool {
    return widget == clicked_widget;
}

was_released :: inline (widget: *Widget) -> bool {
    return widget == released_widget;
}

was_changed :: inline (widget: *Widget) -> bool {
    return widget == changed_widget;
}

request_warmth :: (widget: *Widget) {
    // warm_widget will be set at end of frame, to the last thing that called this.
    next_warm_widget = widget;
    request_window_warmth(currently_drawing_window);
}

request_window_warmth :: (window: *Window) {
    next_warm_window = window;
}

request_scrollwheel :: (widget: *Widget) {
    // scrollwheel_widget will be set at end of frame, to the last thing that called this.
    next_scrollwheel_widget = widget;
}

set_warm_widget :: (widget: *Widget, become_warm: bool) {
    if become_warm {
        if warm_widget && warm_widget != widget
            widget_lost_warm_time(warm_widget, frame.time);
        warm_widget = widget;
        widget_became_warm_time(widget, frame.time);
        warm_widget_frame_index = frame.index;
    }
    else if warm_widget == widget {
        widget_lost_warm_time(widget, frame.time);
        warm_widget = null;
        warm_widget_frame_index = frame.index;
    }
}

set_warm_window :: (window: *Window, become_warm: bool) {
    if become_warm {
        if warm_window && warm_window != window
            window_lost_warm_time(warm_window, frame.time);
        warm_window = window;
        window_became_warm_time(window, frame.time);
        warm_window_frame_index = frame.index;
    }
    else if warm_window == window {
        window_lost_warm_time(window, frame.time);
        warm_window = null;
        warm_window_frame_index = frame.index;
    }
}

set_hot :: (widget: *Widget, hot: bool) {
    if hot {
        if focussed_widget && focussed_widget != widget
            focus(focussed_widget);
        if hot_widget && hot_widget != widget
            widget_lost_hot_time(hot_widget, frame.time);
        hot_widget = widget;
        widget_became_hot_time(hot_widget, frame.time);
        hot_widget_frame_index = frame.index;
    }
    else if hot_widget == widget {
        widget_lost_hot_time(hot_widget, frame.time);
        hot_widget = null;
    }
}

Focus_Change :: enum {
    NONE; UNDETERMINED; CONFIRMED; CANCELLED;
}

focus :: (widget: *$T/Widget) {
    if focussed_widget && focussed_widget != widget
        remove_focus(focussed_widget);
    focussed_widget = widget;
    widget_became_focussed_time(focussed_widget, frame.time);
}

remove_focus :: (widget: *$T/Widget, reason := Focus_Change.UNDETERMINED) {
    if focussed_widget != widget  return;
    widget_lost_focus_time(focussed_widget, frame.time);
    if focussed_widget.type == {
        case .INPUT_LINE; lost_focus(cast(*Input_Line) widget, reason);
    }
    focussed_widget = null;
}

focus_window :: (window: *Window) {
    if focussed_window && focussed_window != window
        remove_window_focus(focussed_window);
    focussed_window = window;
    window_became_focussed_time(focussed_window, frame.time);
}

remove_window_focus :: (window: *Window, reason := Focus_Change.UNDETERMINED) {
    if focussed_window != window  return;
    window_lost_focus_time(focussed_window, frame.time);
    focussed_window = null;
}

set_clicked :: (widget: *Widget) {
    clicked_widget = widget;
    clicked_window = currently_drawing_window;
    focussed_window = currently_drawing_window;
    widget_was_clicked_time(widget, frame.time);
}

set_released :: (widget: *Widget) {
    released_widget = widget;
    widget_was_released_time(widget, frame.time);
}

set_changed :: (widget: *Widget) {
    changed_widget = widget;
    widget_was_changed_time(widget, frame.time);
}

warm_hot_else :: (widget: *Widget, warm: $U, hot: U, default: U) -> U {
    return ifx is_warm(widget) then warm
      else ifx is_hot(widget) then hot
      else default;
}

hot_warm_else :: (widget: *Widget, hot: $U, warm: U, default: U) -> U {
    return ifx is_hot(widget) then hot
      else ifx is_warm(widget) then warm
      else default;
}


calculate_rect :: (panel: *Panel) -> Rect {
    if !panel.parent  return panel.calculated_rect;
    assert(panel.parent != panel);

    parent_rect := ifx panel.parent.calculated_rect_frame_index < frame.index
                   then calculate_rect(panel.parent)
                   else panel.parent.calculated_rect;

    panel.calculated_rect = resolve_rect(parent_rect, panel.desired_box);
    panel.calculated_rect_frame_index = frame.index;

    return panel.calculated_rect;
}

drawn_widget_bounds: Rect;

reset_drawn_widget_bounds :: () {
    drawn_widget_bounds = .{0, 0, 0, 0};
}

calculate_drawn_widget_bounds :: (r: Rect) {
    if drawn_widget_bounds.w == 0
        drawn_widget_bounds = r;
    else
        drawn_widget_bounds = bound(drawn_widget_bounds, r);
}

add_bottom_right_margin_to_drawn_widget_bounds :: (spacing: Placement_Spacing) {
    drawn_widget_bounds.w += spacing.horizontal;
    drawn_widget_bounds.h += spacing.vertical;
}

add_bottom_right_margin_to_drawn_widget_bounds :: (horizontal: int, vertical: int) {
    drawn_widget_bounds.w += horizontal;
    drawn_widget_bounds.h += vertical;
}

add_margin_to_drawn_widget_bounds :: (spacing: int) {
    drawn_widget_bounds.x -= 1 * spacing;
    drawn_widget_bounds.y -= 1 * spacing;
    drawn_widget_bounds.w += 2 * spacing;
    drawn_widget_bounds.h += 2 * spacing;
}

#scope_module


should_quit := false;
draw_debug_widget_frames := false;

// Because some positioning operations create sibling panels, they require everything they work
// on to have a parent.  The root panel has no parent; therefor, we have a separate application panel
// which is the top panel that the user sees; it's parent is the root panel, which it fills.
root_panel: Panel;
application_panel := Panel.{*root_panel, BOX_FILLED, .{}, 0};

register_application_window_size :: (new_width: int, new_height: int) {
    old_width := root_panel.desired_box.brx.abs;
    old_height := root_panel.desired_box.bry.abs;
    if new_width == old_width && new_height == old_height
        return;

    root_panel.parent = null;
    root_panel.desired_box = box(0, 0, new_width, new_height);
    root_panel.calculated_rect = .{ 0, 0, xx new_width, xx new_height };
    application_window_resize(new_width, new_height, old_width, old_height);
}

next :: (index: *int, $reserve := 1) -> Code #expand {
    literal := cast(*Code_Literal) compiler_get_nodes(#code 1);
    literal._s64 = index.*;
    index.* += reserve;
    return compiler_get_code(literal);
}

resolve_ord :: (pos: float, size: float, ord: Ord) -> float {
    return pos + ord.rel * size + ord.abs;
}

resolve_rect :: (rect: Rect, _box: Box) -> Rect {
    x := resolve_ord(rect.x, rect.w, _box.tl.x);
    y := resolve_ord(rect.y, rect.h, _box.tl.y);
    w := resolve_ord(rect.x, rect.w, _box.br.x) - x;
    h := resolve_ord(rect.y, rect.h, _box.br.y) - y;
    return .{ x, y, w, h };
}

get_rect :: (panel: *Panel) -> Rect {
    if panel.calculated_rect_frame_index == frame.index
        return panel.calculated_rect;
    else
        return calculate_rect(panel);
}

maybe_calculate_rect :: (panel: *Panel) {
    if panel.calculated_rect_frame_index != frame.index
        panel.calculated_rect = calculate_rect(panel);
}


button_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
}

upper :: (s: string) -> string {
    result := copy_string(s);
    for i: 0 .. result.count - 1  result[i] = to_upper(result[i]);
    return result;
}

lower :: (s: string) -> string {
    result := copy_string(s);
    for i: 0 .. result.count - 1  result[i] = to_lower(result[i]);
    return result;
}

get_note_value :: (notes: [] string, id: string, default_value: $T) -> T
#modify {
    info := cast(*Type_Info) T;
    return info.type == .INTEGER || info.type == .FLOAT || info.type == .BOOL || info.type == .STRING || T == Ord, "Invalid note value type";
}
{
    for notes {
        found, it_id, it_value := split_from_left(it, "(");
        if it_id != id  continue;
        if !found  break;

        assert(ends_with(it_value, ")"));
        it_value.count -= 1;

        #insert -> string {
            if T == Ord  return #string __jai
                o, ok := parse_ord(it_value);
                return ifx ok then o else default_value;
            __jai;
            info := cast(*Type_Info) T;
            if info.type == .INTEGER  return #string __jai
                i, ok := jai_string.parse_int(*it_value);
                return ifx ok then i else default_value;
            __jai;

            if info.type == .FLOAT  return #string __jai
                f, ok := jai_string.parse_float(*it_value);
                return ifx ok then f else default_value;
            __jai;

            if info.type == .BOOL  return #string __jai
                b, ok := jai_string.parse_bool(*it_value);
                return ifx ok then b else default_value;
            __jai;

            return #string __jai
                return ifx (it_value.count >= 2) && (it_value[0] == #char "\"") && (it_value[it_value.count - 1] == #char "\"")
                    then replace(string.{it_value.count - 2, it_value.data + 1}, "_", " ")
                    else replace(it_value, "_", " ");
            __jai;
        }
    }
    return default_value;
}

get_note :: (notes: [] string, id: string) -> bool {
    for notes  if it == id  return true;
    return false;
}

trailing_utf8_bytes :: u8.[
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5,
];

is_struct_or_pointer_to_struct :: (T: Type) -> bool, *Type_Info_Struct {
    info := cast(*Type_Info) T;

    if info.type == .POINTER
        info = (cast(*Type_Info_Pointer)info).pointer_to;

    if info.type == .STRUCT
        return true, cast(*Type_Info_Struct) info;
    else
        return false, null;
}

lerp :: (a: int, b: int, t: float) -> int {
    return a + cast(int)(cast(float)(b - a) * t);
}


text_edit : struct {
    currently_editting: *Widget;
    bytes: [] u8;
    allocated_count: int;
    cursor: int;
    select_anchor: int;
    cursor_x: float;
    before_cursor: string;
    after_cursor: string;
    lines: [] string;

    #place bytes;
    as_string : string = ---;
}

allocate_text_edit :: (size: int) {
    using text_edit;
    if size <= allocated_count  return;

    new_bytes := NewArray(size + 1024, u8);  // allocate extra space so we likely don't have to reallocate again soon
    bytes_count := bytes.count;
    if allocated_count {
        if bytes.count
            memcpy(new_bytes.data, bytes.data, bytes.count);
        free(bytes.data);
    }
    bytes = new_bytes;
    allocated_count = bytes.count;
    bytes.count = bytes_count;
}

update_text_edit :: () {
    using text_edit;
    before_cursor.data = bytes.data;
    before_cursor.count = cursor;
    after_cursor.data = bytes.data + cursor;
    after_cursor.count = bytes.count - cursor;
}

set_text_edit :: (widget: *Widget, s: string, cursor_position := 0x7fffffff) {
    using text_edit;
    currently_editting = widget;
    bytes.count = 0; // we don't need to preserve the buffer as we're setting it from scratch.
    allocate_text_edit(s.count);
    if s  memcpy(bytes.data, s.data, s.count);
    bytes.count = s.count;
    text_edit_set_cursor(cursor_position, false);
}

insert_text_edit :: (s: string) {
    if !s  return;
    using text_edit;

    has_selection, start, end := text_edit_selection();
    if has_selection
        remove_text_edit(start, end);

    allocate_text_edit(bytes.count + s.count);
    if cursor < bytes.count
        memcpy(bytes.data + cursor + s.count, bytes.data + cursor, bytes.count - cursor);
    memcpy(bytes.data + cursor, s.data, s.count);
    bytes.count += s.count;
    if select_anchor >= cursor  select_anchor += s.count;
    cursor += s.count;
    if currently_editting.flags & .IMMEDIATE
        set_changed(currently_editting);
    update_text_edit();
}

remove_text_edit :: (from: int, to: int) {
    if from >= to  return;
    using text_edit;

    if to < bytes.count
        memcpy(bytes.data + from, bytes.data + to, bytes.count - to);
    bytes.count -= (to - from);
    if cursor > from {
        if cursor <= to  cursor = from;
        else             cursor -= (to - from);
    }
    if select_anchor > from {
        if select_anchor <= to  select_anchor = from;
        else                    select_anchor -= (to - from);
    }
    if currently_editting.flags & .IMMEDIATE
        set_changed(currently_editting);
    update_text_edit();
}

text_edit_set_cursor :: (cursor_position: int, selecting: bool) {
    using text_edit;
    cursor = clamp(cursor_position, 0, bytes.count);
    if !selecting  select_anchor = cursor;
    update_text_edit();
}

text_edit_set_selection :: (select_anchor_position: int, cursor_position: int) {
    using text_edit;
    cursor = clamp(cursor_position, 0, bytes.count);
    select_anchor = clamp(select_anchor_position, 0, bytes.count);
    update_text_edit();
}

text_edit_select_all :: () {
    text_edit_set_selection(0, text_edit.bytes.count);
}

text_edit_copy_selection :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection
        os_clipboard_set_text(string.{end - start, *bytes[start]});
}

text_edit_cut_selection :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        os_clipboard_set_text(string.{end - start, *bytes[start]});
        remove_text_edit(start, end);
    }
}

text_edit_paste :: () {
    insert_text_edit(os_clipboard_get_text());
}

character_utf32_to_utf8 :: (ch: u32, preallocated_string: *string) {  // preallocated_string must have at least 4 characters of allocated memory.
    UNI_MAX_LEGAL_UTF32  :: 0x0010FFFF;
    UNI_REPLACEMENT_CHAR :: 0x0000FFFD;
    firstByteMark : [7] u8 : .[ 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC ];

    count := 0;
    if ch < 0x80                        count = 1;
    else if ch < 0x800                  count = 2;
    else if ch < 0x10000                count = 3;
    else if ch <= UNI_MAX_LEGAL_UTF32   count = 4;
    else {
        count = 3;
        ch = UNI_REPLACEMENT_CHAR;
    }

    byteMask :: 0xBF;
    byteMark :: 0x80;

    preallocated_string.count = count;
    s := preallocated_string;

    if count == {
        case 4; s.data[3] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 3; s.data[2] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 2; s.data[1] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 1; s.data[0] = xx (ch | firstByteMark[count]);
    }
}

text_edit_selection :: () -> has_selection: bool, start: int, end: int {
    using text_edit;
    if select_anchor > cursor
        return cursor != select_anchor, cursor, select_anchor;
    else
        return cursor != select_anchor, select_anchor, cursor;
}

text_edit_move_cursor :: (count: int, selecting: bool) {
    using text_edit;
    if count < 0 {
        for outer: 1 .. -count {
            while true {
                if cursor == 0  break outer;
                cursor -= 1;
                if 192 & bytes[cursor] != 128  break outer;
            }
        }
    }
    else if cursor < bytes.count {
        for outer: 1 .. count {
            cursor += 1 + trailing_utf8_bytes[bytes[cursor]];
            if cursor >= bytes.count {
                cursor = bytes.count;
                break outer;
            }
        }
    }
    if !selecting  select_anchor = cursor;
    update_text_edit();
}

text_edit_backspace :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        remove_text_edit(start, end);
    }
    else {
        if cursor == 0  return;
        start_cursor := cursor;
        text_edit_move_cursor(-1, false);
        remove_text_edit(cursor, start_cursor);
    }
}

text_edit_delete :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        remove_text_edit(start, end);
    }
    else {
        if cursor >= bytes.count  return;
        start_cursor := cursor;
        text_edit_move_cursor(+1, false);
        remove_text_edit(start_cursor, cursor);
    }
}

text_edit_handle_keyboard_input :: (read_only: bool) -> Focus_Change {
    if keyboard.any_typing_this_frame() {
        text := keyboard.eat_typed_this_frame();
        if !read_only  insert_text_edit(text);
    }

    if was_clicked(keyboard.escape)     return .CANCELLED;
    if was_clicked(keyboard.enter)      return .CONFIRMED;
    if was_clicked(keyboard.tab)        return .UNDETERMINED;

    if was_clicked(keyboard.left)       text_edit_move_cursor(-1, xx keyboard.shift);
    if was_clicked(keyboard.right)      text_edit_move_cursor(+1, xx keyboard.shift);
    if was_clicked(keyboard.home)       text_edit_set_cursor(0, xx keyboard.shift);
    if was_clicked(keyboard.end)        text_edit_set_cursor(text_edit.bytes.count, xx keyboard.shift);
    if !read_only && was_clicked(keyboard.backspace)  text_edit_backspace();
    if !read_only && was_clicked(keyboard.delete)     text_edit_delete();

    if keyboard.control {
        if was_clicked(keyboard.a)  text_edit_select_all();
        if was_clicked(keyboard.c)  text_edit_copy_selection();
        if was_clicked(keyboard.v)  text_edit_paste();
        if was_clicked(keyboard.x) {
            if read_only  text_edit_copy_selection();
            else          text_edit_cut_selection();
        }
    }

    return .NONE;
}


Pointer_Image :: enum u16 {
    NORMAL    :: 0;  // Normal arrow for pointing at stuff, or whatever.
    PRESSABLE :: 1;
    LOCKED    :: 2;  // No action can currently be performed.

    DRAGGING_HORIZONTAL   :: 3;
    DRAGGING_VERTICAL     :: 4;
    DRAGGING_FREE         :: 5;

    DRAGGING_NW_SE        :: 6;
    DRAGGING_NE_SW        :: 7;
}

pointer_image_count :: #run cast(Pointer_Image) (enum_highest_value(Pointer_Image) + 1);
current_pointer_image: Pointer_Image;

set_pointer_image :: (image: Pointer_Image) {
    if image >= 0 && image <= pointer_image_count
        current_pointer_image = image;
    else
        log_error("Invalid pointer index %\n", image);
}

set_pointer_image :: (drag_flags: Drag_Flags) {
    if drag_flags == .NONE  return;

    if drag_flags == .MOVE {
        set_pointer_image(.DRAGGING_FREE);
        return;
    }

    if drag_flags ==.RESIZE_NW || drag_flags == .RESIZE_SE {
        set_pointer_image(.DRAGGING_NW_SE);
        return;
    }

    if drag_flags ==.RESIZE_NE || drag_flags == .RESIZE_SW {
        set_pointer_image(.DRAGGING_NE_SW);
        return;
    }

    if drag_flags & (.RESIZE_E | .RESIZE_W) {
        set_pointer_image(.DRAGGING_HORIZONTAL);
        return;
    }

    if drag_flags & (.RESIZE_N | .RESIZE_S) {
        set_pointer_image(.DRAGGING_VERTICAL);
        return;
    }
}

#if OS == .WINDOWS {

    pointers: [pointer_image_count] HCURSOR;

    init_pointers :: () {
        pointers[Pointer_Image.NORMAL]              = LoadCursorW(null, IDC_ARROW);
        pointers[Pointer_Image.PRESSABLE]           = LoadCursorW(null, IDC_HAND);
        pointers[Pointer_Image.LOCKED]              = LoadCursorW(null, IDC_NO);
        pointers[Pointer_Image.DRAGGING_HORIZONTAL] = LoadCursorW(null, IDC_SIZEWE);
        pointers[Pointer_Image.DRAGGING_VERTICAL]   = LoadCursorW(null, IDC_SIZENS);
        pointers[Pointer_Image.DRAGGING_FREE]       = LoadCursorW(null, IDC_SIZEALL);
        pointers[Pointer_Image.DRAGGING_NW_SE]      = LoadCursorW(null, IDC_SIZENWSE);
        pointers[Pointer_Image.DRAGGING_NE_SW]      = LoadCursorW(null, IDC_SIZENESW);
    }

    pointer_end_frame :: () {
        //user32 :: #system_library "user32";
        //GetCursor :: () -> HCURSOR #foreign user32;
        //current_cursor := GetCursor();
        //if current_cursor == pointers[Pointer_Image.NORMAL]
        if Input.mouse_in_client_area_of_os_window
            SetCursor(pointers[current_pointer_image]);
        current_pointer_image = .NORMAL;
    }

} else #if OS == .MACOS {

    #import "Objective_C/AppKit";
    pointers: [pointer_image_count] *NSCursor;

    init_pointers :: () {
        pointers[Pointer_Image.NORMAL]              = NSCursor.arrowCursor();
        pointers[Pointer_Image.PRESSABLE]           = NSCursor.pointingHandCursor();
        pointers[Pointer_Image.LOCKED]              = NSCursor.operationNotAllowedCursor();
        pointers[Pointer_Image.DRAGGING_HORIZONTAL] = NSCursor.resizeLeftRightCursor();
        pointers[Pointer_Image.DRAGGING_VERTICAL]   = NSCursor.resizeUpDownCursor();
        pointers[Pointer_Image.DRAGGING_FREE]       = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
        pointers[Pointer_Image.DRAGGING_NW_SE]      = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
        pointers[Pointer_Image.DRAGGING_NE_SW]      = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
    }

    pointer_end_frame :: () {
        NSCursor.set(pointers[current_pointer_image]);
        current_pointer_image = .NORMAL;
    }

} else {

    init_pointers :: () {
        // @Incomplete: Implement this.
    }

    pointer_end_frame :: () {
        // @Incomplete: Implement this.
        current_pointer_image = .NORMAL;
    }

}
