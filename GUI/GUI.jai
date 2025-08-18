// @TODO
// [ ] Investigate reworking positioning so it doesn't use pointers+macros
// [x] Simplify (click on down, checkbox live)
// [x] Click on down instead of up
// [.] Windows!
//  [x] skin draw_window
//  [x] Record bounds of widgets drawn in windows, to know how to size window interior.
//  [x] Detect widget clicked in window; raise window if so.
//  [.] Moving / Resizing.
//   [ ] Keep on screen?
//   [ ] Min/Max sizes.
//   [x] Mouse pointers
//  [x] What will be do about window gadgets?
//  [ ] Render window to its own buffer.
//  [x] Content scrolling / sizing.
// [ ] text_box input.  rename text_input and text_box?  Maybe just have one call, with a flag to specify multiline (will still be two widgets behind the scenes).
// [ ] Keyboard
//  [x] start/held/end for clicks/keypresses?
//  [x] Get Input to recognise most keys (e.g. left/right shift/ctrl/alt)
//  [ ] Remove Input.events from user layer

// [x] Fix scrollwheel erronously scrolling things below other things.
// [x] Remove was_clicked_time et al from Widgets; add hook to skin instead.
// [ ] radio buttons
// [ ] dropdown
// [ ] fx blend colors
// [ ] text_input/_box merge? name?
// [ ] text_input/_box take pointer to string+buffer instead of initial_text
// [.] Move widget timestamps to skin + widget .ANIMATING flag

#load "widgets/widget.jai";
#load "widgets/window.jai";
#load "widgets/window_decoration.jai";

#load "widgets/button.jai";
#load "widgets/checkbox.jai";
#load "widgets/data_table.jai";
#load "widgets/icon.jai";
#load "widgets/label.jai";
#load "widgets/scrollable_panel.jai";
#load "widgets/scrollbar.jai";
#load "widgets/text_box.jai";
#load "widgets/text_input.jai";

Widget_Types :: Type.[
    Custom_Widget, Window, Window_Decoration, Button, Checkbox, Data_Table, Icon, Label, Scrollable_Panel, Scrollbar, Text_Input, Text_Box
];
// @TODO Compile time check Widget_Types matches type enum in Widget

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

application_window : Window_Creation.Window_Type;

window_back_buffer : struct {
    fbo: GLuint;
    texture: GLuint;
    active := true;
}

gui_create_application_window :: (window_title: string, window_width: int, window_height: int, window_x := -1, window_y := -1) -> *Panel, *Window_Creation.Window_Type {
    assert(widget_allocator.proc == null, "You should only call gui_create_window once!");

    #if OS == .WINDOWS {
        using Windows :: #import "Windows";
        timeBeginPeriod(1);
        // The following would tell windows that we don't look at the system DPI, and so windows should automatically scale
        // for us.  However, that's the default behaviour, so...
        //  user32   :: #system_library "user32";
        //  SetThreadDpiAwarenessContext :: (awareness: DPI_AWARENESS_CONTEXT) -> BOOL #foreign user32;
        //  SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE);
    }

    widget_allocator.proc = flat_pool_allocator_proc;
    widget_allocator.data = *widget_allocator_pool;

    if !keyboard  keyboard = cast(*Keyboard) *Input.input_button_states;

    init_skin();

    allocate_text_edit(1024);

    set_application_window_size(window_width, window_height);

    #if OS == .WINDOWS {
        if window_x == -1 {
            using Windows :: #import "Windows";
            mouse_position: POINT;
            if GetCursorPos(*mouse_position) {
                monitor := MonitorFromPoint(mouse_position, MONITOR_DEFAULTTONEAREST);
                info := MONITORINFO.{cbSize = size_of(MONITORINFO)};
                if GetMonitorInfoW(monitor, *info) {
                    screen := info.rcMonitor;
                    window_x = screen.left + (screen.right - screen.left - window_width) / 2;
                    window_y = screen.top + (screen.bottom - screen.top - window_height) / 2;
                }
            }
        }
    }

    application_window = Window_Creation.create_window(window_width, window_height, window_title, window_x, window_y);

    Simp.set_render_target(application_window);

    setup_window_back_buffer :: () #expand {
        using window_back_buffer;
        glGenFramebuffers(1, *fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);

        glGenTextures(1, *texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx window_width, xx window_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);

        if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE {
            print("Error setting up window back buffer.\n");
            active = false;
            return;
        }
    }
    setup_window_back_buffer();

    array_reset(*placement_spacing);
    array_add(*placement_spacing, .{0, 0});

    array_reset(*placement_panel);

    return *application_panel, *application_window;
}

gui_begin_frame :: () -> should_quit: bool {

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
            set_warm(next_warm_widget, true);
    }
    else if warm_widget {
        set_warm(warm_widget, false);
    }

    if scrollwheel_widget  use_scrollwheel(scrollwheel_widget);
    scrollwheel_widget = next_scrollwheel_widget;

    if tooltip_widget && tooltip_widget != prev_tooltip_widget
        became_tooltip_widget_time = frame.time;
    prev_tooltip_widget = tooltip_widget;
    if tooltip_widget && tooltip_widget.tooltip && frame.time - became_tooltip_widget_time > theme.tooltip_delay
        draw_tooltip(tooltip_widget);

    Simp.swap_buffers(application_window);

    if !frame.no_sleep && hot_widget_frame_index != frame.index && warm_widget_frame_index != frame.index && !clicked_widget && !released_widget && !changed_widget {
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
    next_scrollwheel_widget = null;

    Input.update_window_events();

    for Input.get_window_resizes() {
        Simp.update_window(it.window);

        if it.window == application_window
            set_application_window_size(it.width, it.height);
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

    Simp.update_window(application_window);
    clear_window();

    mouse_x, mouse_y := Window_Creation.get_mouse_pointer_position(application_window, false);
    mouse.x = xx mouse_x;
    mouse.y = xx mouse_y;

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

gui_draw_windows :: () {
    bring_to_front_window: *Window;

    for key: window_order {
        window, was_added := find_or_add(*window_data, key);
        assert(!was_added, "Didn't find the window in the window_data table, but it should be there!");

        if window.flags & .SHOW && window.is_open {
            if window_back_buffer.active {
                glBindFramebuffer(GL_FRAMEBUFFER, window_back_buffer.fbo);
                glClearColor(0, 0, 0, 0);
                glClear(GL_COLOR_BUFFER_BIT);
            }

            currently_drawing_window = window;
            update_widget(window);
            draw_window(.BACKGROUND);

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

            if window_back_buffer.active {
                glBindFramebuffer(GL_READ_FRAMEBUFFER, window_back_buffer.fbo);
                glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0); // Default framebuffer
                width : float = xx application_panel.calculated_rect.w;
                height : float = xx application_panel.calculated_rect.h;
                glEnable(GL_BLEND);
                gl_vec4 :: (rect: Rect) -> Vector4 {
                    return .{rect.x, application_panel.calculated_rect.h - rect.y - rect.h, rect.x + rect.w, application_panel.calculated_rect.h - rect.y};
                }

                get_quad :: (r: Rect, snap_coordinates := false) -> (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) {
                    using v4 := gl_vec4(r);
                    p0 := Vector2.{x, y};
                    p1 := Vector2.{z, y};
                    p2 := Vector2.{z, w};
                    p3 := Vector2.{x, w};

                    if snap_coordinates {
                        p0.x = floor(p0.x + .5);
                        p0.y = floor(p0.y + .5);
                        p1.x = floor(p1.x + .5);
                        p1.y = floor(p1.y + .5);
                        p2.x = floor(p2.x + .5);
                        p2.y = floor(p2.y + .5);
                        p3.x = floor(p3.x + .5);
                        p3.y = floor(p3.y + .5);
                    }

                    return p0, p1, p2, p3;
                }

                p0, p1, p2, p3 := get_quad(.{0, 0, width, height});
                Simp.immediate_set_shader(*Simp.shader_sprite_left_handed);
                Simp.set_projection();

                glBindTexture(GL_TEXTURE_2D, window_back_buffer.texture);
                Simp.immediate_quad(p0, p1, p2, p3, .{1,1,1,0.5});
                Simp.immediate_flush();
            }

            if clicked_window == window  bring_to_front_window = clicked_window;
        }
        window.flags |= ~.SHOW;
    }

    if bring_to_front_window  bring_to_front(bring_to_front_window);

    if currently_dragging_window && released_widget
        currently_dragging_window = null;

    if currently_dragging_window
        update_window_drag(currently_dragging_window);

    currently_drawing_window = null;
}

gui_no_sleep_this_frame :: () {
    frame.no_sleep = true;
}


mouse: struct {
    x, y: float;
    #place x;
    position: Vector2;
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
    capital: Key_State;
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
    __pad17: [8] Key_State;
    attn: Key_State;
    crsel: Key_State;
    exsel: Key_State;
    ereof: Key_State;
    play: Key_State;
    zoom: Key_State;
    noname: Key_State;
    pa1: Key_State;
    oem_clear: Key_State;

    typed_this_frame :: () -> string {
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

    typed_this_frame :: () -> string {
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
    SMOOTH;
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

    // Window_Decoration
    MOVE;
    RESIZE;
    TITLE_BAR;
    CLOSE;
    SCROLLBAR_HORIZONTAL;
    SCROLLBAR_VERTICAL;
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

window_decoration_inherit_mask :: text_align_mask | font_style_mask | theme_index_mask;

prev_frame_time: float64;
next_warm_widget: *Widget;
next_scrollwheel_widget: *Widget;
tooltip_widget: *Widget;
prev_tooltip_widget: *Widget;
became_tooltip_widget_time: float64;
hot_widget_frame_index: int;
warm_widget_frame_index: int;

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
}

request_scrollwheel :: (widget: *Widget) {
    // scrollwheel_widget will be set at end of frame, to the last thing that called this.
    next_scrollwheel_widget = widget;
}

set_warm :: (widget: *Widget, warm: bool) {
    if warm {
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

Lost_Focus_Reason :: enum {
    UNDETERMINED; CONFIRMED; CANCELLED;
}

focus :: (widget: *$T/Widget) {
    if focussed_widget && focussed_widget != widget
        remove_focus(focussed_widget);
    focussed_widget = widget;
    widget_became_focussed_time(focussed_widget, frame.time);
}

remove_focus :: (widget: *$T/Widget, reason := Lost_Focus_Reason.UNDETERMINED) {
    if focussed_widget != widget  return;
    widget_lost_focussed_time(focussed_widget, frame.time);
    if focussed_widget.type == {
        case .TEXT_INPUT; lost_focus(cast(*Text_Input)widget, reason);
    }
    focussed_widget = null;
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

    parent_rect : Rect = ---;
    if panel.parent.calculated_rect_frame_index < frame.index
        parent_rect = calculate_rect(panel.parent);
    else
        parent_rect = panel.parent.calculated_rect;

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
application_panel: Panel;

set_application_window_size :: (window_width: int, window_height: int) {
    application_panel.parent = null;
    application_panel.desired_box = box(0, 0, window_width, window_height);
    application_panel.calculated_rect = .{ 0, 0, xx window_width, xx window_height };
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
