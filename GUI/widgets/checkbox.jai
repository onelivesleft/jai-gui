Checkbox :: struct {
    #as using widget: Widget;
    type = .CHECKBOX;

    initialized := false;

    value: bool;
    text: string;
}


// @TODO Make a checkbox which takes [value_flags_pointer: *$T(enum_flags), flag: T] and returns [changed, checkbox]

checkbox :: (location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(0, location, flags, tooltip, text, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (location: *At_Location, text: string, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(0, location, flags, tooltip, text, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (id: int, location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(id, location, flags, tooltip, text, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (id: int, location: *At_Location, text: string, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(id, location, flags, tooltip, text, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (checkbox: *Checkbox, location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox {
    value, widget := _checkbox(checkbox, location, flags, tooltip, text, initial_value, null);
    return value, widget;
}

checkbox :: (checkbox: *Checkbox, location: *At_Location, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> changed: bool, *Checkbox {
    _, widget := _checkbox(checkbox, location, flags, tooltip, text, false, value_pointer);
    return was_changed(widget), widget;
}



#scope_module


checkbox_data: Table(u64, Checkbox);


_checkbox :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool, callsite_key: u64) -> value: bool, *Checkbox {
    key := widget_key(id, currently_drawing_window, callsite_key);
    checkbox := find_or_add(*checkbox_data, key);
    value := _checkbox(checkbox, location, flags, tooltip, text, initial_value, value_pointer);
    return value, checkbox;
}

_checkbox :: (checkbox: *Checkbox, location: *At_Location, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool) -> value: bool, *Checkbox {
    _value : bool = ---;
    if value_pointer
        _value = value_pointer.*;
    else if !checkbox.initialized
        _value = initial_value;
    else
        _value = checkbox.value;

    checkbox.* = .{ widget(.CHECKBOX, location, tooltip, flags), true, _value, text };
    last_widget_location = location.*;

    update_widget(checkbox);
    if was_clicked(checkbox) {
        checkbox.value = !checkbox.value;
        set_changed(checkbox);
    }

    draw_checkbox(checkbox);

    if value_pointer  value_pointer.* = checkbox.value;

    return checkbox.value, checkbox;
}
