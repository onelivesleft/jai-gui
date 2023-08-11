// @TODO
// [ ] tooltips
// [ ] checkbox
// [ ] radio buttons
// [ ] data table
// [ ] icon
// [ ] icon button
// [ ] input
// [ ] text

#load "widgets/panel.jai";
#load "widgets/button.jai";
#load "widgets/checkbox.jai";
#load "widgets/label.jai";
#load "widgets/scrollbar.jai";

Widgets :: Type.[
    Panel, Button, Checkbox, Label, Scrollbar
];

hot_widget:      *Widget;    // typically use is_hot(widget)
active_widget:   *Widget;    // typically use is_active(widget)

clicked_widget:  *Widget;    // lasts a single frame, when mouse is released on active_widget
changed_widget:  *Widget;    // lasts a single frame, a widget which changed substantially, i.e. a scrollbar moving
scrollwheel_widget: *Widget; // lasts a single frame, when widget has used the scrollwheel for something

mouse_x, mouse_y: float;
mouse_left_button_down, mouse_left_button_up, mouse_left_button_held: bool;
mouse_middle_button_down, mouse_middle_button_up, mouse_middle_button_held: bool;
mouse_right_button_down, mouse_right_button_up, mouse_right_button_held: bool;
mouse_scrollwheel: int;       // normalized, will typically be -1, +1 or 0
mouse_scrollwheel_fraction: float;  // on devices with high-precision wheels this can be [0.0, +/-1.0)
                                    // (though you can typically ignore it as it will automaticaly accumulate
                                    //  into mouse_scrollwheel)
frame_count: int;
frame_time: float64;
frame_dt: float;

gui_window : Window_Creation.Window_Type;


gui_create_window :: (window_title: string, window_width: int, window_height: int) -> *Panel, *Window_Creation.Window_Type {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    #insert -> string {
        builder : String_Builder;
        for Widgets {
            type_name := tprint("%", it);
            name := copy_string(type_name, temp);
            name[0] = to_lower(name[0]);
            print_to_builder(*builder, #string jai
                %1_data = NewArray(%1_count, %2);
            jai, name, type_name);
        }
        return builder_to_string(*builder);
    }

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

    frame_count += 1;
    prev_frame_time = frame_time;
    frame_time = get_time();
    frame_dt := cast(float)(frame_time - prev_frame_time);
    //Clamp(*dt, 0, 0.1);

    Input.update_window_events();

    for Input.get_window_resizes() {
        Simp.update_window(it.window);

        if it.window == gui_window
            set_window_size(it.width, it.height);
    }

    for event: Input.events_this_frame {
        if event.type == .QUIT  continue_running = false;

        if event.type == {
          case .KEYBOARD;
            if event.key_pressed && event.key_code == .ESCAPE {
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

    _mouse_x, _mouse_y := Window_Creation.get_mouse_pointer_position(gui_window, false);
    mouse_x = xx _mouse_x;
    mouse_y = xx _mouse_y;

    mouse_left_button_down = xx (button_state(.MOUSE_BUTTON_LEFT) & .START);
    mouse_left_button_held = xx (button_state(.MOUSE_BUTTON_LEFT) & .DOWN);
    mouse_left_button_up   = xx (button_state(.MOUSE_BUTTON_LEFT) & .END);

    mouse_middle_button_down = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .START);
    mouse_middle_button_held = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .DOWN);
    mouse_middle_button_up   = xx (button_state(.MOUSE_BUTTON_MIDDLE) & .END);

    mouse_right_button_down = xx (button_state(.MOUSE_BUTTON_RIGHT) & .START);
    mouse_right_button_held = xx (button_state(.MOUSE_BUTTON_RIGHT) & .DOWN);
    mouse_right_button_up   = xx (button_state(.MOUSE_BUTTON_RIGHT) & .END);

    mouse_scrollwheel_resolution :: 120;
    mouse_scrollwheel = Input.mouse_delta_z / mouse_scrollwheel_resolution;
    mouse_scrollwheel_fraction += (Input.mouse_delta_z % mouse_scrollwheel_resolution) / cast(float)mouse_scrollwheel_resolution;
    if mouse_scrollwheel_fraction <= -1.0 {
        mouse_scrollwheel -= 1;
        mouse_scrollwheel_fraction += 1.0;
    }
    else if mouse_scrollwheel_fraction >= 1.0 {
        mouse_scrollwheel += 1;
        mouse_scrollwheel_fraction -= 1.0;
    }

    clicked_widget = null;
    next_hot_widget = null;
    scrollwheel_widget = null;

    return continue_running;
}

gui_end_frame :: inline () {
    if !mouse_left_button_held {
        if active_widget {
            active_widget.became_inactive_at = frame_time;
            active_widget = null;
        }
    }

    if next_hot_widget
        set_hot(next_hot_widget, true);
    else if hot_widget
        set_hot(hot_widget, false);

    Simp.swap_buffers(gui_window);

    if active_widget_frame_count != frame_count && hot_widget_frame_count != frame_count && !clicked_widget && !changed_widget {
        // Nothing big changed so sleep a little
        dt := get_time() - frame_time;
        ms := clamp(10 - cast(s32)(dt * 1000), 1, 10);
        sleep_milliseconds(ms);
    }

    reset_temporary_storage();
}

widget_type :: (widget: *Widget) -> Type {
    #insert -> string {
        builder : String_Builder;
        for Widgets {
            type_name := tprint("%", it);
            name := copy_string(type_name, temp);
            name[0] = to_lower(name[0]);
            print_to_builder(*builder, #string jai
                if widget >= xx %1_data.data && widget < xx (%1_data.data + %1_data.count)  return %2;
            jai, name, type_name);
        }
        return builder_to_string(*builder);
    }
    return Widget;
}

Widget :: struct {
    #as using panel: Panel;
    using timestamps : struct {
        became_hot_at : float64;
        became_cold_at : float64;
        became_active_at : float64;
        became_inactive_at : float64;
        was_clicked_at : float64;
    }
    flags : Widget_Flags;
}

widget :: inline (parent: *Panel, placement: Place, flags: Widget_Flags) -> Widget {
    return .{ panel(parent, placement), .{0, 0, 0, 0, 0}, flags };
}

Widget_Flags :: enum_flags u64 {
    NONE    :: 0;

    // masked out to get text align
    LEFT   :: 1;
    CENTER :: 2;
    RIGHT  :: 3;

    // masked out to get font style
    SANS   :: 4;
    SERIF  :: 8;
    FIXED  :: 12;

    // masked out to get theme index (set none of these for default theme)
    THEME_A :: 16;
    THEME_B :: 32;
    THEME_C :: 48;

    // scrollbar
    SMOOTH  :: 1;
    REVERSE_SCROLLWHEEL :: 2;  // inverts scrollwheel direction

    // flags
    LOCKED  :: 64;
    INTERACTS;  // overrides LOCKED (a widget is only locked if LOCKED & !INTERACTS)
    FIT;
    OVERFLOW;   // don't scissor
    CROP;       // do scissor even if OVERFLOW is set
    IMMEDIATE;  // update value immediately, based on is_active and is_hot (instead of waiting for click)

}

fit_width :: (rect: Rect, flags: Widget_Flags) -> float {
    return ifx flags & .FIT then rect.w else 0;
}


text_align_mask : u64 : 0b11;

Text_Alignment :: enum u8 {
    DEFAULT :: 0;
    LEFT    :: 1;
    CENTER  :: 2;
    RIGHT   :: 3;
}

left_align :: (flags: Widget_Flags) -> Text_Alignment {
    text_align : Text_Alignment = xx (text_align_mask & xx flags);
    if !text_align  return .LEFT;
    return text_align;
}

center_align :: (flags: Widget_Flags) -> Text_Alignment {
    text_align : Text_Alignment = xx (text_align_mask & xx flags);
    if !text_align  return .CENTER;
    return text_align;
}

right_align :: (flags: Widget_Flags) -> Text_Alignment {
    text_align : Text_Alignment = xx (text_align_mask & xx flags);
    if !text_align  return .RIGHT;
    return text_align;
}


font_style_mask : u64 : 0b1100;

Font_Style :: enum u8 {
    DEFAULT :: 0;
    SANS    :: 1;
    SERIF   :: 2;
    FIXED   :: 3;
}

sans_font :: (flags: Widget_Flags) -> Font_Style {
    font_style : Font_Style = xx ((font_style_mask & xx flags) >> 2);
    if !font_style  return .SANS;
    return font_style;
}

serif_font :: (flags: Widget_Flags) -> Font_Style {
    font_style : Font_Style = xx ((font_style_mask & xx flags) >> 2);
    if !font_style  return .SERIF;
    return font_style;
}

fixed_font :: (flags: Widget_Flags) -> Font_Style {
    font_style : Font_Style = xx ((font_style_mask & xx flags) >> 2);
    if !font_style  return .FIXED;
    return font_style;
}

theme_index_mask : u64 : 0b110000;

theme_index :: (flags: Widget_Flags) -> int {
    return xx (theme_index_mask & xx flags) >> 4;
}


prev_frame_time: float64;
next_hot_widget: *Widget;
active_widget_frame_count: int;
hot_widget_frame_count: int;

is_hot :: inline (widget: *Widget) -> bool {
    return widget == hot_widget;
}

is_active :: inline (widget: *Widget) -> bool {
    return widget == active_widget;
}

was_clicked :: inline (widget: *Widget) -> bool {
    return widget == clicked_widget;
}

set_hot :: (widget: *Widget, hot: bool) {
    if hot {
        if hot_widget {
            if hot_widget != widget {
                hot_widget.became_cold_at = frame_time;
                hot_widget = widget;
                widget.became_hot_at = frame_time;
                hot_widget_frame_count = frame_count;
            }
        }
        else {
            hot_widget = widget;
            widget.became_hot_at = frame_time;
            hot_widget_frame_count = frame_count;
        }
    }
    else if hot_widget == widget {
        widget.became_cold_at = frame_time;
        hot_widget = null;
        hot_widget_frame_count = frame_count;
    }
}

request_hot :: (widget: *Widget) {
    next_hot_widget = widget;
}

set_active :: (widget: *Widget, active: bool) {
    if active {
        if active_widget && active_widget != widget
            active_widget.became_inactive_at = frame_time;
        active_widget = widget;
        widget.became_active_at = frame_time;
        active_widget_frame_count = frame_count;
    }
    else if active_widget == widget {
        active_widget.became_inactive_at = frame_time;
        active_widget = null;
    }
}

set_clicked :: (widget: *Widget) {
    clicked_widget = widget;
    widget.was_clicked_at = frame_time;
}

set_changed :: (widget: *Widget) {
    changed_widget = widget;
}

update_widget :: (using widget: *Widget) {
    maybe_calculate_rect(widget);

    if (flags & .LOCKED) && !(flags & .INTERACTS)
    || active_widget && active_widget != widget
        return;

    is_mouse_over := contains(rect, mouse_x, mouse_y);
    if is_mouse_over
        request_hot(widget);

    if is_active(widget) {
        if mouse_left_button_up {
            set_active(widget, false);
            if is_mouse_over
                set_clicked(widget);
        }
    }

    if is_hot(widget) {
        if !is_mouse_over
            set_hot(widget, false);
        else if mouse_left_button_down
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
window_panel : Panel;
window_rect : Rect;

set_window_size :: (window_width: int, window_height: int) {
    window_panel.parent = null;
    window_panel.placement = place(0, 0, window_width, window_height);
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

resolve_rect :: (rect: Rect, place: Place) -> Rect {
    x := resolve_ord(rect.x, rect.w, place.tl.x);
    y := resolve_ord(rect.y, rect.h, place.tl.y);
    w := resolve_ord(rect.x, rect.w, place.br.x) - x;
    h := resolve_ord(rect.y, rect.h, place.br.y) - y;
//    x := clamp(resolve_ord(rect.x, rect.w, place.tl.x), 0, window_panel.rect.w);
//    y := clamp(resolve_ord(rect.y, rect.h, place.tl.y), 0, window_panel.rect.h);
//    w := clamp(resolve_ord(rect.x, rect.w, place.br.x) - x, 0, window_panel.rect.w);
//    h := clamp(resolve_ord(rect.y, rect.h, place.br.y) - y, 0, window_panel.rect.h);

    return .{ x, y, w, h };
}

calculate_rect :: (panel: *$T/Panel) -> Rect {
    if !panel.parent  return panel.rect;

    parent_rect : Rect = ---;
    if panel.parent.rect_frame_count < frame_count
        parent_rect = calculate_rect(panel.parent);
    else
        parent_rect = panel.parent.rect;

    panel.rect = resolve_rect(parent_rect, panel.placement);
    panel.rect_frame_count = frame_count;

    return panel.rect;
}

get_rect :: (widget: *Widget) -> Rect {
    if widget.rect_frame_count  == frame_count
        return widget.rect;
    else
        return calculate_rect(widget);
}

maybe_calculate_rect :: (widget: *Widget) {
     if widget.rect_frame_count != frame_count
         widget.rect = calculate_rect(widget);
}


button_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
}
