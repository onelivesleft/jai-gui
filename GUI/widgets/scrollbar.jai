Scrollbar :: struct {
    #as using widget: Widget;
    type = .SCROLLBAR;

    Orientation :: enum u8 { HORIZONTAL; VERTICAL; };
    orientation := Orientation.VERTICAL;

    handle_move_step: float;
    handle_size: float;
    handle_position: float;

    value_type: enum u8 { FLOAT; INTEGER; } = .FLOAT;

    int_value_pointer : *int = ---;
    int_value : int = ---;
    int_range : Int_Range = ---;

    #place int_value_pointer;
    float_value_pointer : *float = null;
    float_value : float = 0.0;
    float_range : Float_Range = .{ 0.0, 1.0 };
}

Int_Range :: struct {
    min: int;
    max: int;
}

Float_Range :: struct {
    min := 0.0;
    max := 1.0;
}


// Horizontal with float value

horizontal_scrollbar :: (panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: float, *Scrollbar {
    value, widget := float_scrollbar(.HORIZONTAL, 0, panel, flags, tooltip, initial_value, range, handle_size, callsite_key(callsite));
    return value, widget;
}

horizontal_scrollbar :: (id: int, panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: float, *Scrollbar {
    value, widget := float_scrollbar(.HORIZONTAL, id, panel, flags, tooltip, initial_value, range, handle_size, callsite_key(callsite));
    return value, widget;
}

horizontal_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "") -> value: float, *Scrollbar {
    value, widget := float_scrollbar(scrollbar, .HORIZONTAL, panel, flags, tooltip, initial_value, range, handle_size);
    return value, widget;
}

// Horizontal with float pointer

horizontal_scrollbar :: (panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(.HORIZONTAL, 0, panel, flags, tooltip, value_pointer, range, handle_size, callsite_key(callsite));
    return was_changed, widget;
}

horizontal_scrollbar :: (id: int, panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(.HORIZONTAL, id, panel, flags, tooltip, value_pointer, range, handle_size, callsite_key(callsite));
    return was_changed, widget;
}

horizontal_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "") -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(scrollbar, .HORIZONTAL, panel, flags, tooltip, value_pointer, range, handle_size);
    return was_changed, widget;
}

// Horizontal with integer value

horizontal_scrollbar :: (panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: int, *Scrollbar {
    value, widget := int_scrollbar(.HORIZONTAL, 0, panel, flags, tooltip, initial_value, range, callsite_key(callsite));
    return value, widget;
}

horizontal_scrollbar :: (id: int, panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: int, *Scrollbar {
    value, widget := int_scrollbar(.HORIZONTAL, id, panel, flags, tooltip, initial_value, range, callsite_key(callsite));
    return value, widget;
}

horizontal_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "") -> value: int, *Scrollbar {
    value, widget := int_scrollbar(scrollbar, .HORIZONTAL, panel, flags, tooltip, initial_value, range);
    return value, widget;
}

// Horizontal with integer pointer

horizontal_scrollbar :: (panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(.HORIZONTAL, 0, panel, flags, tooltip, value_pointer, range, callsite_key(callsite));
    return was_changed, widget;
}

horizontal_scrollbar :: (id: int, panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(.HORIZONTAL, id, panel, flags, tooltip, value_pointer, range, callsite_key(callsite));
    return was_changed, widget;
}

horizontal_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "") -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(scrollbar, .HORIZONTAL, panel, flags, tooltip, value_pointer, range);
    return was_changed, widget;
}

// Vertical with float value

vertical_scrollbar :: (panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: float, *Scrollbar {
    value, widget := float_scrollbar(.VERTICAL, 0, panel, flags, tooltip, initial_value, range, handle_size, callsite_key(callsite));
    return value, widget;
}

vertical_scrollbar :: (id: int, panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: float, *Scrollbar {
    value, widget := float_scrollbar(.VERTICAL, id, panel, flags, tooltip, initial_value, range, handle_size, callsite_key(callsite));
    return value, widget;
}

vertical_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, initial_value := 0.0, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "") -> value: float, *Scrollbar {
    value, widget := float_scrollbar(scrollbar, .VERTICAL, panel, flags, tooltip, initial_value, range, handle_size);
    return value, widget;
}

// Vertical with float pointer

vertical_scrollbar :: (panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(.VERTICAL, 0, panel, flags, tooltip, value_pointer, range, handle_size, callsite_key(callsite));
    return was_changed(widget), widget;
}

vertical_scrollbar :: (id: int, panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(.VERTICAL, id, panel, flags, tooltip, value_pointer, range, handle_size, callsite_key(callsite));
    return was_changed(widget), widget;
}

vertical_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, value_pointer: *float, range := Float_Range.{}, handle_size := 0.1, flags := Flags.NONE, tooltip := "") -> was_changed: bool, *Scrollbar {
    was_changed, widget := float_scrollbar(scrollbar, .VERTICAL, panel, flags, tooltip, value_pointer, range, handle_size);
    return was_changed, widget;
}

// Vertical with integer value

vertical_scrollbar :: (panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: int, *Scrollbar {
    value, widget := int_scrollbar(.VERTICAL, 0, panel, flags, tooltip, initial_value, range, callsite_key(callsite));
    return value, widget;
}

vertical_scrollbar :: (id: int, panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: int, *Scrollbar {
    value, widget := int_scrollbar(.VERTICAL, id, panel, flags, tooltip, initial_value, range, callsite_key(callsite));
    return value, widget;
}

vertical_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, initial_value: int, range: Int_Range, flags := Flags.NONE, tooltip := "") -> value: int, *Scrollbar {
    value, widget := int_scrollbar(scrollbar, .VERTICAL, panel, flags, tooltip, initial_value, range);
    return value, widget;
}

// Vertical with integer pointer

vertical_scrollbar :: (panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(.VERTICAL, 0, panel, flags, tooltip, value_pointer, range, callsite_key(callsite));
    return was_changed, widget;
}

vertical_scrollbar :: (id: int, panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(.VERTICAL, id, panel, flags, tooltip, value_pointer, range, callsite_key(callsite));
    return was_changed, widget;
}

vertical_scrollbar :: (scrollbar: *Scrollbar, panel: *Panel, value_pointer: *int, range: Int_Range, flags := Flags.NONE, tooltip := "") -> was_changed: bool, *Scrollbar {
    was_changed, widget := int_scrollbar(scrollbar, .VERTICAL, panel, flags, tooltip, value_pointer, range);
    return was_changed, widget;
}

// Direct

int_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, initial_value: int, range: Int_Range, callsite_key: u64) -> value: int, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    int_scrollbar(scrollbar, orientation, panel, flags, tooltip, initial_value, range);
    return scrollbar.int_value_pointer.*, scrollbar;
}

int_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, initial_value: int, range: Int_Range) -> value: int, *Scrollbar {
    if !scrollbar.int_value_pointer
        scrollbar.int_value = initial_value;
    scrollbar.int_value_pointer = *scrollbar.int_value;
    _int_scrollbar(scrollbar, orientation, panel, flags, tooltip, range);
    return scrollbar.int_value_pointer.*, scrollbar;
}

int_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, value_pointer: *int, range: Int_Range, callsite_key: u64) -> was_changed: bool, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    was_changed := int_scrollbar(scrollbar, orientation, panel, flags, tooltip, value_pointer, range);
    return was_changed, scrollbar;
}

int_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, value_pointer: *int, range: Int_Range) -> was_changed: bool, *Scrollbar {
    scrollbar.int_value_pointer = value_pointer;
    was_changed := _int_scrollbar(scrollbar, orientation, panel, flags, tooltip, range);
    scrollbar.int_value = scrollbar.int_value_pointer.*;
    return was_changed, scrollbar;
}

float_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, initial_value: float, range: Float_Range, handle_size: float, callsite_key: u64) -> value: float, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    float_scrollbar(scrollbar, orientation, panel, flags, tooltip, initial_value, range, handle_size);
    return scrollbar.float_value_pointer.*, scrollbar;
}

float_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, initial_value: float, range: Float_Range, handle_size: float) -> value: float, *Scrollbar {
    if !scrollbar.float_value_pointer  scrollbar.float_value = initial_value;
    scrollbar.float_value_pointer = *scrollbar.float_value;
    _float_scrollbar(scrollbar, orientation, panel, flags, tooltip, range, handle_size);
    return scrollbar.float_value_pointer.*, scrollbar;
}

float_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, value_pointer: *float, range: Float_Range, handle_size: float, callsite_key: u64) -> was_changed: bool, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    was_changed := float_scrollbar(scrollbar, orientation, panel, flags, tooltip, value_pointer, range, handle_size);
    return was_changed, scrollbar;
}

float_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, value_pointer: *float, range: Float_Range, handle_size: float) -> was_changed: bool, *Scrollbar {
    scrollbar.float_value_pointer = value_pointer;
    was_changed := _float_scrollbar(scrollbar, orientation, panel, flags, tooltip, range, handle_size);
    scrollbar.float_value = scrollbar.float_value_pointer.*;
    return was_changed, scrollbar;
}


move_by_steps :: (using scrollbar: *Scrollbar, steps: int) {
    if value_type == .INTEGER {
        int_value_pointer.* += steps;
        Clamp(int_value_pointer, int_range.min, int_range.max);
        handle_position = calculate_handle_position(int_value_pointer.*, int_range);
    }
    else {
        handle_position += handle_move_step * steps;
        Clamp(*handle_position, 0.0, 1.0);
        float_value_pointer.* = lerp(float_range.min, float_range.max, handle_position);
    }
}

use_scrollwheel :: (using scrollbar: *Scrollbar) {
    if mouse.scrollwheel {
        steps := ifx (flags & .REVERSE_SCROLLWHEEL) then mouse.scrollwheel else -mouse.scrollwheel;
        move_by_steps(scrollbar, steps);
        deplete_scrollwheel();
    }
}

set_value :: (using scrollbar: *Scrollbar, value: $T)
#modify {
    info := cast(*Type_Info) T;
    return info.type == .INTEGER || info.type == .FLOAT;
}
{
    if scrollbar.type == .FLOAT {
        _value := cast(float) value;
        float_value_pointer.* = clamp(_value, float_range.min, float_range.max);
        handle_position = (float_value_pointer.* - float_range.min) / (float_range.max - float_range.min);
    }
    else {
        _value := cast(int) value;
        int_value_pointer.* = clamp(_value, int_range.min, int_range.max);
        handle_position = calculate_handle_position(int_value_pointer.*, int_range);
    }
}


#scope_module


scrollbar_data : Table(u64, Scrollbar);

_int_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, range: Int_Range) -> was_changed: bool {
    scrollbar.widget = .{panel, .SCROLLBAR, tooltip, flags | .USE_SCROLLWHEEL};
    scrollbar.orientation = orientation;
    scrollbar.value_type = .INTEGER;
    scrollbar.int_range = range;
    if scrollbar.int_range.max < scrollbar.int_range.min  scrollbar.int_range.max = scrollbar.int_range.min;
    Clamp(scrollbar.int_value_pointer, scrollbar.int_range.min, scrollbar.int_range.max);
    spread := cast(float)(scrollbar.int_range.max - scrollbar.int_range.min + 1);
    scrollbar.handle_position = calculate_handle_position(scrollbar.int_value_pointer.*, scrollbar.int_range);
    scrollbar.handle_move_step = 1.0 / spread;
    scrollbar.handle_size = max(theme.scrollbar_min_handle_size, scrollbar.handle_move_step);

    last_widget_panel = panel.*;

    prev_handle_position := scrollbar.handle_position;
    update_scrollbar(scrollbar);
    was_changed := scrollbar.handle_position != prev_handle_position;
    if was_changed  set_changed(scrollbar);
    draw_scrollbar(scrollbar);

    return was_changed;
}


_float_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, range: Float_Range, handle_size: float) -> was_changed: bool {
    scrollbar.widget = .{panel, .SCROLLBAR, tooltip, flags | .USE_SCROLLWHEEL};
    scrollbar.orientation = orientation;
    scrollbar.value_type = .FLOAT;
    scrollbar.float_range = range;
    Clamp(*scrollbar.float_range.max, scrollbar.float_range.min, scrollbar.float_range.max);
    Clamp(scrollbar.float_value_pointer, scrollbar.float_range.min, scrollbar.float_range.max);
    scrollbar.handle_move_step = handle_size;
    scrollbar.handle_size = handle_size;
    Clamp(*scrollbar.handle_size, theme.scrollbar_min_handle_size, scrollbar.handle_size);
    scrollbar.handle_position = calculate_handle_position(scrollbar.float_value_pointer.*, scrollbar.float_range);

    last_widget_panel = panel.*;

    prev_handle_position := scrollbar.handle_position;
    update_scrollbar(scrollbar);
    was_changed := scrollbar.handle_position != prev_handle_position;
    if was_changed  set_changed(scrollbar);
    draw_scrollbar(scrollbar);

    return was_changed;
}


update_scrollbar :: (using scrollbar: *Scrollbar) {
    was_hot := is_hot(scrollbar);
    update_widget(scrollbar);

    if !is_hot(scrollbar) {
        if is_warm(scrollbar)
            use_scrollwheel(scrollbar);
        return;
    }

    if !was_hot { // just pressed
        _, handle, _ := get_scrollbar_rects(scrollbar);
        mouse_pos, start, handle_start : float = ---;
        if #complete orientation == {
            case .HORIZONTAL;
            mouse_pos = mouse.x;
            start = calculated_rect.x;
            handle_start = handle.x;

            case .VERTICAL;
            mouse_pos = mouse.y;
            start = calculated_rect.y;
            handle_start = handle.y;
        }

        if contains(handle, mouse.x, mouse.y) {
            scrollbar_grab_offset = mouse_pos - start;
            scrollbar_grab_value = handle_position;
        }
        else {
            set_hot(scrollbar, false);
            if mouse_pos < handle_start
                move_by_steps(scrollbar, -1);
            else
                move_by_steps(scrollbar, +1);
        }
    }
    else {
        mouse_pos, start, size : float = ---;
        if #complete orientation == {
            case .HORIZONTAL;
            mouse_pos = mouse.x;
            start = calculated_rect.x;
            size = calculated_rect.w;

            case .VERTICAL;
            mouse_pos = mouse.y;
            start = calculated_rect.y;
            size = calculated_rect.h;
        }

        handle_position = scrollbar_grab_value + (mouse_pos - scrollbar_grab_offset - start) / (size * (1.0 - handle_move_step));
        Clamp(*handle_position, 0.0, 1.0);
        if value_type == .INTEGER {
            spread := cast(float) int_range.max - int_range.min + 1;
            f := spread * handle_position;
            int_value_pointer.* = int_range.min + cast(int) f;
            Clamp(int_value_pointer, int_range.min, int_range.max);
            if !(flags & .SMOOTH)
                handle_position = calculate_handle_position(int_value_pointer.*, int_range);
        }
        else {
            float_value_pointer.* = lerp(float_range.min, float_range.max, handle_position);
        }
    }
}

scrollbar_grab_offset : float;
scrollbar_grab_value : float;

calculate_handle_position :: (value: int, range: Int_Range) -> float {
    if range.max <= range.min  return 0.0;

    value -= range.min;
    return cast(float)value / (range.max - range.min);
}

calculate_handle_position :: (value: float, range: Float_Range) -> float {
    if range.max <= range.min  return 0.0;

    value -= range.min;
    return value / (range.max - range.min);
}

get_scrollbar_rects :: (using scrollbar: *Scrollbar) -> Rect, Rect, Rect {
    before, handle, after := calculated_rect;
    if #complete orientation == {
        case .HORIZONTAL;
        actual_handle_size := calculated_rect.w * handle_size;
        groove_length := calculated_rect.w - actual_handle_size;
        handle_start := groove_length * handle_position;
        handle_end := handle_start + actual_handle_size;
        before.w = handle_start - calculated_rect.x;
        handle.x += handle_start;
        handle.w = actual_handle_size;
        after.x += handle_end;
        after.w = calculated_rect.w - after.x;

        case .VERTICAL;
        actual_handle_size := calculated_rect.h * handle_size;
        groove_length := calculated_rect.h - actual_handle_size;
        handle_start := groove_length * handle_position;
        handle_end := handle_start + actual_handle_size;
        before.h = handle_start - calculated_rect.y;
        handle.y += handle_start;
        handle.h = actual_handle_size;
        after.y += handle_end;
        after.h = calculated_rect.h - after.y;
    }
    return before, handle, after;
}
