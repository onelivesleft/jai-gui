// @TODO
// [x] Simplify (click on down, checkbox live)
// [x] Click on down instead of up
// [ ] Windows!
//  [ ] skin draw_window
//  [ ] Record bounds of widgets drawn in windows, to know how to size window interior.
//  [x] Detect widget clicked in window; raise window if so.
//  [.] Moving / Resizing.
//   [ ] Keep on screen?
//   [ ] Min/Max sizes.
//   [x] Mouse pointers
//   [ ] Min/max size.
//  [ ] What will be do about window gadgets?
//  [ ] Render window to its own buffer.
//  [ ] Content scrolling / sizing.
// [ ] text_box input.  rename text_input and text_box?  Maybe just have one call, with a flag to specify multiline (will still be two widgets behind the scenes).

// [ ] Fix scrollwheel erronously scrolling things below other things.
// [ ] Allocate all widgets as one.
// [ ] Remove was_clicked_time et al from Widgets; add hook to skin instead.
// [ ] Remove need for widget id
// [ ] radio buttons
// [ ] dropdown
// [ ] fx blend colors
// [ ] text_input/_box merge? name?
// [ ] text_input/_box take pointer to string+buffer instead of initial_text
// [ ] Move widget timestamps to skin + widget .ANIMATING flag

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
    Window, Window_Decoration, Button, Checkbox, Data_Table, Icon, Label, Scrollable_Panel, Scrollbar, Text_Input, Text_Box
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

mouse : struct {
    x, y: float;
    #place x;
    position: Vector2;
    left_button_down, left_button_up, left_button_held: bool;
    middle_button_down, middle_button_up, middle_button_held: bool;
    right_button_down, right_button_up, right_button_held: bool;
    scrollwheel: int;             // normalized, will typically be -1, +1 or 0
    scrollwheel_fraction: float;  // on devices with high-precision wheels this can be (-1.0, +1.0)
                                  // (though you can typically ignore it as it will automaticaly accumulate
                                  //  into scrollwheel)
    scrollwheel_resolution :: 120;
}

frame : struct {
    index := 1;
    time: float64;
    dt: float;
    no_sleep: bool;
}

application_window : Window_Creation.Window_Type;

gui_create_application_window :: (window_title: string, window_width: int, window_height: int, window_x := -1, window_y := -1) -> *At_Location, *Window_Creation.Window_Type {
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

    array_reset(*placement_spacing);
    array_add(*placement_spacing, .{0, 0});

    array_reset(*placement_panel);

    return *application_panel, *application_window;
}

gui_begin_frame :: () -> should_quit: bool {

    // First, clean up the previous frame.

    pointer_end_frame();

    if mouse.left_button_held {
        if mouse.left_button_down && !hot_widget && focussed_widget
            remove_focus(focussed_widget);
    }
    else if hot_widget {
        hot_widget.lost_hot_time = frame.time;
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
        became_tooltip_widget_at = frame.time;
    prev_tooltip_widget = tooltip_widget;
    if tooltip_widget && tooltip_widget.tooltip && frame.time - became_tooltip_widget_at > theme.tooltip_delay
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

    for event: Input.events_this_frame {
        if event.type == .QUIT  should_quit = true;

        if event.type == {
            case .TEXT_INPUT;
            if focussed_widget
                dispatch_event_to_focussed_widget(event);

            case .KEYBOARD;
            if focussed_widget {
                dispatch_event_to_focussed_widget(event);
            }
            else if event.key_pressed && event.key_code == .ESCAPE {
                should_quit = true; // @TODO  Don't leave this in
                //hot_widget_deactivate_all();
            }

            case .DRAG_AND_DROP_FILES;
            //for dropped_files free(it);
            //array_reset(*dropped_files);
            //for event.files array_add(*dropped_files, copy_string(it));
        }
    }

    Simp.update_window(application_window);
    clear_window();

    mouse_x, mouse_y := Window_Creation.get_mouse_pointer_position(application_window, false);
    mouse.x = xx mouse_x;
    mouse.y = xx mouse_y;

    mouse.left_button_down = xx (button_state(.MOUSE_BUTTON_LEFT) & .START);
    mouse.left_button_held = xx (button_state(.MOUSE_BUTTON_LEFT) & .DOWN);
    mouse.left_button_up   = xx (button_state(.MOUSE_BUTTON_LEFT) & .END);

    mouse.middle_button_down = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .START);
    mouse.middle_button_held = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .DOWN);
    mouse.middle_button_up   = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .END);

    mouse.right_button_down = xx (button_state(.MOUSE_BUTTON_RIGHT) & .START);
    mouse.right_button_held = xx (button_state(.MOUSE_BUTTON_RIGHT) & .DOWN);
    mouse.right_button_up   = xx (button_state(.MOUSE_BUTTON_RIGHT) & .END);


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
            currently_drawing_window = window;
            update_widget(window);

            with_panel(window);
            with_scissor(window.calculated_rect, window.flags);
            draw_window(.BACKGROUND);

            {
                calculate_usable_area(window);
                with_panel(*window.usable_area);
                with_scissor(window.available_area.calculated_rect, window.flags);

                reset_drawn_widget_bounds();
                window.draw_proc(window);
                window.drawn_bounds = drawn_widget_bounds;
            }

            update_window(window);
            draw_window(.FOREGROUND);

            if clicked_window == window  bring_to_front_window = clicked_window;
        }
        window.flags |= ~.SHOW;
    }

    if bring_to_front_window  bring_to_front(bring_to_front_window);

    if currently_dragging_window && released_widget
        currently_dragging_window = null;

    if currently_dragging_window
        drag_window(currently_dragging_window);

    currently_drawing_window = null;
}

gui_no_sleep_this_frame :: () {
    frame.no_sleep = true;
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


Widget :: struct {
    #as using location: At_Location;

    type : enum { // Need to use an enum because the Type itself can be polymorphic, e.g. Data_Table($T)
        WINDOW;
        WINDOW_DECORATION;

        BUTTON;
        CHECKBOX;
        DATA_TABLE;
        ICON;
        LABEL;
        SCROLLABLE_PANEL;
        SCROLLBAR;
        TEXT_BOX;
        TEXT_INPUT;
    }

    using timestamps: struct {
        // @Performance These could be moved to a set of arrays or hashmaps
        //              only while pertinent, instead of having them all on
        //              all widgets.  However, this is a lot simpler...
        // @Urgent THESE DON'T EVEN WORK as they are cleared whenever widget() is called :/

        became_warm_time : float64 = -99999.0;
        lost_warm_time : float64 = -99999.0;
        became_hot_time : float64 = -99999.0;
        lost_hot_time : float64 = -99999.0;
        became_focussed_time : float64 = -99999.0;
        lost_focussed_time : float64 = -99999.0;
        was_clicked_time : float64 = -99999.0;
        was_released_time : float64 = -99999.0;
        was_changed_time : float64 = -99999.0;
    }

    tooltip : string;
    flags : Flags;
}


widget :: inline (type: type_of(Widget.type), location: *At_Location, tooltip: string, flags: Flags) -> Widget {
    return .{ location, type, .{}, tooltip, flags };
}

widget_key :: (id: int, window: *Window, callsite_key: u64) -> u64 {
    data : struct {
        _id: int;
        _window_key: u64;
        _callsite_key: u64;
    } = .{id, ifx window then window.key, callsite_key};
    return fnv1a_hash(*data, size_of(type_of(data)));
}

callsite_key :: ($callsite: Source_Code_Location) -> u64 #expand {
    return #run fnv1a_hash(*callsite, size_of(Source_Code_Location));
}


widget_type :: (widget: *Widget) -> Type {
    #insert -> string {
        builder : String_Builder;
        for Widget_Types {
            info := cast(*Type_Info) it;
            type_name := tprint("%", it);
            enum_name := upper(tprint("%", it));
            print_to_builder(*builder, #string jai
                if widget.type == .%1  return %2%3;
            jai, enum_name, type_name, ifx info.runtime_size >= 0 then "" else "(void)");
        }
        append(*builder, #string jai
                assert(false, "Tried to look up a widget type for a non-existent index: %", widget.type);
            jai);
        return builder_to_string(*builder);
    }
    return Widget;
}

update_widget :: (using widget: *Widget) {
    maybe_calculate_rect(widget);
    calculate_drawn_widget_bounds(calculated_rect);

    scissor := peek_scissor();
    if scissor && !contains(scissor.*, mouse.x, mouse.y)
        return;

    is_mouse_over := contains(calculated_rect, mouse.x, mouse.y);
    if is_mouse_over
        tooltip_widget = widget;

    if is_locked(widget)
        return;

    if is_mouse_over && flags & .USE_SCROLLWHEEL
        request_scrollwheel(widget);

    if hot_widget && hot_widget != widget
        return;

    if is_mouse_over
        request_warmth(widget);

    if is_hot(widget) {
        if mouse.left_button_up {
            set_hot(widget, false);
            if is_mouse_over
                set_released(widget);
        }
    }

    if is_warm(widget) {
        if !is_mouse_over {
            set_warm(widget, false);
        }
        else if mouse.left_button_down {
            set_hot(widget, true);
            set_clicked(widget);
        }
    }
}

use_scrollwheel :: (using widget: *Widget) {
    if widget.type == {
        case .DATA_TABLE;        use_scrollwheel(*(cast(*Data_Table(void))widget).scrollbar);
        case .SCROLLABLE_PANEL;  use_scrollwheel(cast(*Scrollable_Panel) widget);
        case .SCROLLBAR;         use_scrollwheel(cast(*Scrollbar) widget);
        case .TEXT_BOX;          use_scrollwheel(*(cast(*Text_Box)widget).scrollbar);
    }
}

deplete_scrollwheel :: () {
    scrollwheel_widget = null;
}

prev_frame_time: float64;
next_warm_widget: *Widget;
next_scrollwheel_widget: *Widget;
tooltip_widget: *Widget;
prev_tooltip_widget: *Widget;
became_tooltip_widget_at: float64;
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
            warm_widget.lost_warm_time = frame.time;
        warm_widget = widget;
        widget.became_warm_time = frame.time;
        warm_widget_frame_index = frame.index;
    }
    else if warm_widget == widget {
        widget.lost_warm_time = frame.time;
        warm_widget = null;
        warm_widget_frame_index = frame.index;
    }
}


set_hot :: (widget: *Widget, hot: bool) {
    if hot {
        if focussed_widget && focussed_widget != widget
            focus(focussed_widget);
        if hot_widget && hot_widget != widget
            hot_widget.lost_hot_time = frame.time;
        hot_widget = widget;
        widget.became_hot_time = frame.time;
        hot_widget_frame_index = frame.index;
    }
    else if hot_widget == widget {
        hot_widget.lost_hot_time = frame.time;
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
    focussed_widget.became_focussed_time = frame.time;
}

remove_focus :: (widget: *$T/Widget, reason := Lost_Focus_Reason.UNDETERMINED) {
    if focussed_widget != widget  return;
    focussed_widget.lost_focussed_time = frame.time;
    if focussed_widget.type == {
        case .TEXT_INPUT; lost_focus(cast(*Text_Input)widget, reason);
    }
    focussed_widget = null;
}

dispatch_event_to_focussed_widget :: (event: Input.Event) {
    if focussed_widget.type == {
        case .TEXT_INPUT;  handle_event(cast(*Text_Input)focussed_widget, event);
    }
}

set_clicked :: (widget: *Widget) {
    clicked_widget = widget;
    clicked_window = currently_drawing_window;
    focussed_window = currently_drawing_window;
    widget.was_clicked_time = frame.time;
}

set_released :: (widget: *Widget) {
    released_widget = widget;
    widget.was_released_time = frame.time;
}

set_changed :: (widget: *Widget) {
    changed_widget = widget;
    changed_widget.was_changed_time = frame.time;
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

calculate_rect :: (parent: *Panel, _box: Box) -> Rect {
    calculate_rect(parent);
    return resolve_rect(parent.calculated_rect, _box);
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

recalculate_rect :: (panel: *Panel) {
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
