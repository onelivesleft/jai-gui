// @TODO
// [x] tooltips
// [x] checkbox
// [ ] radio buttons
// [ ] input
// [ ] text
// [ ] dropdown
// [ ] data table
// [ ] icon
// [ ] icon button
// [ ] fx blend colors

#load "widgets/button.jai";
#load "widgets/checkbox.jai";
#load "widgets/data_table.jai";
#load "widgets/label.jai";
#load "widgets/scrollbar.jai";
#load "widgets/text_box.jai";
#load "widgets/text_input.jai";

Widgets :: Type.[
    Button, Checkbox, Data_Table, Label, Scrollbar, Text_Input, Text_Box
];

hot_widget:      *Widget;    // prefer is_hot(widget)
active_widget:   *Widget;    // prefer is_active(widget)
focussed_widget: *Widget;    // prefer has_focus(widget)
focussed_widget_type: Type;

clicked_widget:  *Widget;    // prefer was_clicked(widget).  Lasts a single frame, when mouse is released on active_widget
changed_widget:  *Widget;    // prefer was_changed(widget).  Lasts a single frame, a widget which changed substantially, i.e. a scrollbar moving
scrollwheel_widget: *Widget; // prefer was_scrollwheeled(widget).  Lasts a single frame, when widget has used the scrollwheel for something

mouse : struct {
    x, y: float;
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
    count: int;
    time: float64;
    dt: float;
}

gui_window : Window_Creation.Window_Type;


gui_create_window :: (window_title: string, window_width: int, window_height: int) -> *At_Location, *Window_Creation.Window_Type {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    #insert -> string {
        builder : String_Builder;
        for Widgets {
            info := cast(*Type_Info) it;
            type_name := tprint(ifx info.runtime_size >= 0 then "%" else "%(void)", it);
            name := lower(tprint("%", it));
            print_to_builder(*builder, #string jai
                %1_data = NewArray(%1_count, %2);
            jai, name, type_name);
        }
        return builder_to_string(*builder);
    }

    allocate_text_edit(1024);

    array_reset(*auto_place_spacing);
    array_add(*auto_place_spacing, .{0, 0});

    set_window_size(window_width, window_height);
    gui_window = Window_Creation.create_window(window_width, window_height, window_title);

    Simp.set_render_target(gui_window);

    return *window_panel, *gui_window;
}

gui_begin_frame :: () -> continue_running: bool {
    #if !MANUAL_END_FRAME
        gui_end_frame();

    frame.count += 1;
    prev_frame_time = frame.time;
    frame.time = get_time();
    frame.dt = cast(float)(frame.time - prev_frame_time);

    Input.update_window_events();

    for Input.get_window_resizes() {
        Simp.update_window(it.window);

        if it.window == gui_window
            set_window_size(it.width, it.height);
    }

    for event: Input.events_this_frame {
        if event.type == .QUIT  continue_running = false;

        if event.type == {
            case .TEXT_INPUT;
            if focussed_widget
                dispatch_event_to_focussed_widget(event);

            case .KEYBOARD;
            if focussed_widget {
                dispatch_event_to_focussed_widget(event);
            }
            else if event.key_pressed && event.key_code == .ESCAPE {
                continue_running = false;
                //active_widget_deactivate_all();
            }

            case .DRAG_AND_DROP_FILES;
            //for dropped_files free(it);
            //array_reset(*dropped_files);
            //for event.files array_add(*dropped_files, copy_string(it));
        }
    }

    Simp.update_window(gui_window);
    clear_window();

    mouse_x, mouse_y := Window_Creation.get_mouse_pointer_position(gui_window, false);
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

    tooltip_widget = null;
    clicked_widget = null;
    next_hot_widget = null;
    scrollwheel_widget = null;

    return continue_running;
}

gui_end_frame :: inline () {
    if mouse.left_button_held {
        if mouse.left_button_down && !active_widget && focussed_widget
            set_focus(focussed_widget, false, .SOFT);
    }
    else {
        if active_widget {
            active_widget.lost_active_time = frame.time;
            active_widget = null;
        }
    }

    if next_hot_widget
        set_hot(next_hot_widget, true);
    else if hot_widget
        set_hot(hot_widget, false);

    if tooltip_widget && tooltip_widget != prev_tooltip_widget
        became_tooltip_widget_at = frame.time;
    prev_tooltip_widget = tooltip_widget;
    if tooltip_widget && frame.time - became_tooltip_widget_at > theme.tooltip_delay
        draw_tooltip(tooltip_widget);

    Simp.swap_buffers(gui_window);

    if active_widget_frame_count != frame.count && hot_widget_frame_count != frame.count && !clicked_widget && !changed_widget {
        // Nothing interesting happened so sleep a little
        dt := get_time() - frame.time;
        ms := clamp(10 - cast(s32)(dt * 1000), 1, 10);
        sleep_milliseconds(ms);
    }

    reset_temporary_storage();
}

Widget :: struct {
    #as using location: At_Location;
    using timestamps: struct {
        // @Performance These could be moved to a set of arrays or hashmaps
        //              only while pertinent, instead of having them all on
        //              all widgets.  However, this is a lot simpler...
        became_hot_time: float64;
        lost_hot_time: float64;
        became_active_time: float64;
        lost_active_time: float64;
        became_focussed_time: float64;
        lost_focussed_time: float64;
        was_clicked_time: float64;
        was_changed_time: float64;
    }
    tooltip : string;
    flags : Flags;
}

widget :: inline (location: *At_Location, tooltip: string, flags: Flags) -> Widget {
    return .{ location, .{0, 0, 0, 0, 0, 0, 0, 0}, tooltip, flags };
}


widget_type :: (widget: *Widget) -> Type {
    #insert -> string {
        builder : String_Builder;
        for Widgets {
            type_name := tprint("%", it);
            name := copy_string(type_name, temp);
            if type_name == "Data_Table" {
                print_to_builder(*builder, #string jai
                    if widget >= xx %1_data.data && widget < xx (%1_data.data + %1_data.count)  return %2(void);
                jai, lower(name), type_name);
            }
            else {
                print_to_builder(*builder, #string jai
                    if widget >= xx %1_data.data && widget < xx (%1_data.data + %1_data.count)  return %2;
                jai, lower(name), type_name);
            }
        }
        return builder_to_string(*builder);
    }
    return Widget;
}


Flags :: enum_flags u64 {
    NONE    :: 0;

    // masked out to get text align
    LEFT   :: 1;
    RIGHT  :: 2;
    CENTER :: 3;

    // masked out to get font style
    SANS   :: 4;
    SERIF  :: 8;
    FIXED  :: 12;

    // masked out to get theme index (set none of these for default theme)
    THEME_A :: 16;
    THEME_B :: 32;
    THEME_C :: 48;

    // scrollbar
    SMOOTH  :: 64;
    REVERSE_SCROLLWHEEL;  // inverts scrollwheel direction

    // flags
    LOCKED;
    INTERACTS;  // overrides LOCKED (a widget is only locked if LOCKED & !INTERACTS)
    READ_ONLY;
    OVERFLOW;   // don't scissor
    CROP;       // do scissor even if OVERFLOW is set
    FIT;
    IMMEDIATE;  // update value immediately, rather than when user completes action

}

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


font_style_mask : u64 : 0b1100;

Font_Style :: enum u8 {
    DEFAULT :: 0;
    SANS    :: 1;
    SERIF   :: 2;
    FIXED   :: 3;
}

flags_from_font_style :: (font_style: Font_Style) -> Flags {
    return xx font_style << 2;
}

font_style_from_flags :: (flags: Flags, default_font_style: Font_Style) -> Font_Style {
    font_style : Font_Style = xx ((font_style_mask & xx flags) >> 2);
    if font_style  return font_style;
    else           return default_font_style;
}

sans_font :: #bake_arguments font_style_from_flags(default_font_style=.SANS);
serif_font :: #bake_arguments font_style_from_flags(default_font_style=.SERIF);
fixed_font :: #bake_arguments font_style_from_flags(default_font_style=.FIXED);


theme_index_mask : u64 : 0b110000;

theme_index :: (flags: Flags) -> int {
    return xx (theme_index_mask & xx flags) >> 4;
}


prev_frame_time: float64;
next_hot_widget: *Widget;
tooltip_widget: *Widget;
prev_tooltip_widget: *Widget;
became_tooltip_widget_at: float64;
active_widget_frame_count: int;
hot_widget_frame_count: int;

is_hot :: inline (widget: *Widget) -> bool {
    return widget == hot_widget;
}

is_active :: inline (widget: *Widget) -> bool {
    return widget == active_widget;
}

has_focus :: inline (widget: *Widget) -> bool {
    return widget == focussed_widget;
}

was_clicked :: inline (widget: *Widget) -> bool {
    return widget == clicked_widget;
}

was_changed :: inline (widget: *Widget) -> bool {
    return widget == changed_widget;
}

was_scrollwheeled :: inline (widget: *Widget) -> bool {
    return widget == scrollwheel_widget;
}

set_hot :: (widget: *Widget, hot: bool) {
    if hot {
        if hot_widget && hot_widget != widget
            hot_widget.lost_hot_time = frame.time;
        hot_widget = widget;
        widget.became_hot_time = frame.time;
        hot_widget_frame_count = frame.count;
    }
    else if hot_widget == widget {
        widget.lost_hot_time = frame.time;
        hot_widget = null;
        hot_widget_frame_count = frame.count;
    }
}

request_hot :: (widget: *Widget) {
    // The idea of request_hot is we set hot_widget at end of frame, so only one widget can ever be considered
    // hot in a given frame.  However, this may not be an issue, so we're just going to set hot directly for now.
    // Return to this when we support windows / layers / popups...
    hot_widget = widget; // @TODO
    next_hot_widget = widget;
}

set_active :: (widget: *Widget, active: bool) {
    if active {
        if focussed_widget && focussed_widget != widget
            set_focus(focussed_widget, false, .SOFT);
        if active_widget && active_widget != widget
            active_widget.lost_active_time = frame.time;
        active_widget = widget;
        widget.became_active_time = frame.time;
        active_widget_frame_count = frame.count;
    }
    else if active_widget == widget {
        active_widget.lost_active_time = frame.time;
        active_widget = null;
    }
}

Lost_Focus_Reason :: enum {
    NONE; CONFIRMED; CANCELLED; SOFT;
}

set_focus :: (widget: *$T/Widget, focussed: bool, reason := Lost_Focus_Reason.NONE) {
    if focussed {
        if focussed_widget && focussed_widget != widget
            focussed_widget.lost_focussed_time = frame.time;
        focussed_widget = widget;
        focussed_widget.became_focussed_time = frame.time;
        focussed_widget_type = T;
    }
    else if focussed_widget == widget {
        assert(reason != .NONE);
        focussed_widget.lost_focussed_time = frame.time;
        focussed_widget = null;
        if focussed_widget_type == {
            case Text_Input; lost_focus(cast(*Text_Input)widget, reason);
        }
    }
}

dispatch_event_to_focussed_widget :: (event: Input.Event) {
    if focussed_widget_type == {
        case Text_Input;  handle_event(cast(*Text_Input)focussed_widget, event);
    }
}

set_clicked :: (widget: *Widget) {
    clicked_widget = widget;
    widget.was_clicked_time = frame.time;
}

set_changed :: (widget: *Widget) {
    changed_widget = widget;
    changed_widget.was_changed_time = frame.time;
}

update_widget :: (using widget: *Widget) {
    maybe_calculate_rect(widget);

    is_mouse_over := contains(rect, mouse.x, mouse.y);
    if is_mouse_over && tooltip
        tooltip_widget = widget;

    if (flags & .LOCKED) && !(flags & .INTERACTS)
    || active_widget && active_widget != widget
        return;

    if is_mouse_over
        request_hot(widget);

    if is_active(widget) {
        if mouse.left_button_up {
            set_active(widget, false);
            if is_mouse_over
                set_clicked(widget);
        }
    }

    if is_hot(widget) {
        if !is_mouse_over
            set_hot(widget, false);
        else if mouse.left_button_down
            set_active(widget, true);
    }
}

hot_active_else :: (widget: *Widget, hot: $U, active: U, default: U) -> U {
    return ifx is_hot(widget) then hot
      else ifx is_active(widget) then active
      else default;
}

active_hot_else :: (widget: *Widget, active: $U, hot: U, default: U) -> U {
    return ifx is_active(widget) then active
      else ifx is_hot(widget) then hot
      else default;
}


#scope_module


continue_running := true;
window_panel : At_Location;
window_rect : Rect;

set_window_size :: (window_width: int, window_height: int) {
    window_panel.parent = null;
    window_panel.box = get_box(0, 0, window_width, window_height);
    window_panel.rect = .{ 0, 0, xx window_width, xx window_height };
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

resolve_rect :: (rect: Rect, box: Box) -> Rect {
    x := resolve_ord(rect.x, rect.w, box.tl.x);
    y := resolve_ord(rect.y, rect.h, box.tl.y);
    w := resolve_ord(rect.x, rect.w, box.br.x) - x;
    h := resolve_ord(rect.y, rect.h, box.br.y) - y;
    return .{ x, y, w, h };
}

calculate_rect :: (at: *$T/At_Location) -> Rect {
    if !at.parent  return at.rect;

    parent_rect : Rect = ---;
    if at.parent.rect_frame_count < frame.count
        parent_rect = calculate_rect(at.parent);
    else
        parent_rect = at.parent.rect;

    at.rect = resolve_rect(parent_rect, at.box);
    at.rect_frame_count = frame.count;

    return at.rect;
}

calculate_rect :: (parent: *$T/At_Location, box: Box) -> Rect {
    calculate_rect(parent);
    return resolve_rect(parent.rect, box);
}

get_rect :: (widget: *Widget) -> Rect {
    if widget.rect_frame_count  == frame.count
        return widget.rect;
    else
        return calculate_rect(widget);
}

maybe_calculate_rect :: (widget: *Widget) {
     if widget.rect_frame_count != frame.count
         widget.rect = calculate_rect(widget);
}


button_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
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
                return it_value;
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
