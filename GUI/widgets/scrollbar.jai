Scrollbar :: struct {
    #as using widget: Widget;
    type = .SCROLLBAR;

    initialized := false;

    Orientation :: enum u8 { HORIZONTAL; VERTICAL; };
    orientation := Orientation.VERTICAL;

    handle_move_step: float;
    handle_size: float;
    handle_position: float;

    value_type: enum u8 { FLOAT; INTEGER; } = .FLOAT;

    int_range : Int_Range = ---;
    int_value : int = ---;

    #place int_range;
    float_range : Float_Range = .{ 0.0, 1.0 };
    float_value : float = 0.0;
}

Int_Range :: struct {
    min: int;
    max: int;
}

Float_Range :: struct {
    min := 0.0;
    max := 1.0;
}


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


move_by_steps :: (using scrollbar: *Scrollbar, steps: int) {
    if value_type == .INTEGER {
        int_value += steps;
        Clamp(*int_value, int_range.min, int_range.max);
        handle_position = calculate_handle_position(int_value, int_range);
    }
    else {
        handle_position += handle_move_step * steps;
        Clamp(*handle_position, 0.0, 1.0);
        float_value = lerp(float_range.min, float_range.max, handle_position);
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
        float_value = clamp(_value, float_range.min, float_range.max);
        handle_position = (float_value - float_range.min) / (float_range.max - float_range.min);
    }
    else {
        _value := cast(int) value;
        scrollbar.int_value = clamp(_value, int_range.min, int_range.max);
        handle_position = calculate_handle_position(int_value, int_range);
    }
}


#scope_module


scrollbar_data : Table(u64, Scrollbar);


int_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, initial_value: int, range: Int_Range, callsite_key: u64) -> value: int, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    value := int_scrollbar(scrollbar, orientation, panel, flags, tooltip, initial_value, range);
    return value, scrollbar;
}

int_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, initial_value: int, range: Int_Range) -> value: int, *Scrollbar {
    value := ifx scrollbar.initialized then scrollbar.int_value else initial_value;
    _range := range;
    if _range.max < _range.min  _range.max = _range.min;
    Clamp(*value, _range.min, _range.max);
    spread := cast(float)(_range.max - _range.min + 1);
    handle_move_step : float = 1.0 / spread;
    handle_size : float = max(theme.scrollbar_min_handle_size, handle_move_step);
    scrollbar.* = .{ .{panel, .SCROLLBAR, tooltip, flags | .USE_SCROLLWHEEL}, true, orientation, handle_move_step, handle_size, calculate_handle_position(value, _range), .INTEGER, _range, value};
    last_widget_panel = panel.*;

    prev_handle_position := scrollbar.handle_position;
    update_scrollbar(scrollbar);
    if scrollbar.handle_position != prev_handle_position
        set_changed(scrollbar);
    draw_scrollbar(scrollbar);

    return scrollbar.int_value, scrollbar;
}


float_scrollbar :: inline (orientation: Scrollbar.Orientation, id: int, panel: *Panel, flags: Flags, tooltip: string, initial_value: float, range: Float_Range, handle_size: float, callsite_key: u64) -> value: float, *Scrollbar {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollbar := find_or_add(*scrollbar_data, key);
    value := float_scrollbar(scrollbar, orientation, panel, flags, tooltip, initial_value, range, handle_size);
    return value, scrollbar;
}

float_scrollbar :: (scrollbar: *Scrollbar, orientation: Scrollbar.Orientation, panel: *Panel, flags: Flags, tooltip: string, initial_value: float, range: Float_Range, handle_size: float) -> value: float, *Scrollbar {
    value := ifx scrollbar.initialized then scrollbar.float_value else initial_value;
    _range := range;
    Clamp(*_range.max, _range.min, _range.max);
    Clamp(*value, _range.min, _range.max);
    handle_move_step := handle_size;
    Clamp(*handle_size, theme.scrollbar_min_handle_size, handle_size);
    scrollbar.* = .{ .{panel, .SCROLLBAR, tooltip, flags | .USE_SCROLLWHEEL}, true, orientation, handle_move_step, handle_size, calculate_handle_position(value, _range), .FLOAT, .{}, 0};
    scrollbar.float_range = _range;
    scrollbar.float_value = value;
    last_widget_panel = panel.*;

    prev_handle_position := scrollbar.handle_position;
    update_scrollbar(scrollbar);
    if scrollbar.handle_position != prev_handle_position
        set_changed(scrollbar);
    draw_scrollbar(scrollbar);

    return scrollbar.float_value, scrollbar;
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
            int_value = int_range.min + cast(int) f;
            Clamp(*int_value, int_range.min, int_range.max);
            if !(flags & .SMOOTH)
                handle_position = calculate_handle_position(int_value, int_range);
        }
        else {
            float_value = lerp(float_range.min, float_range.max, handle_position);
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
