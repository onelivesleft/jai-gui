Checkbox :: struct {
    #as using widget: Widget;
    type = .CHECKBOX;

    initialized := false;

    value: bool;
    text: string;
    icon_id: Icon_Id;
}


// @TODO Make a checkbox which takes [value_flags_pointer: *$T(enum_flags), flag: T] and returns [changed, checkbox]

// Text

checkbox :: (panel: *Panel, text: string, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(0, panel, flags, tooltip, text, .NONE, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (panel: *Panel, text: string, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(0, panel, flags, tooltip, text, .NONE, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (id: int, panel: *Panel, text: string, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(id, panel, flags, tooltip, text, .NONE, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (id: int, panel: *Panel, text: string, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(id, panel, flags, tooltip, text, .NONE, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (checkbox: *Checkbox, panel: *Panel, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox {
    value, widget := _checkbox(checkbox, panel, flags, tooltip, text, .NONE, initial_value, null);
    return value, widget;
}

checkbox :: (checkbox: *Checkbox, panel: *Panel, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> changed: bool, *Checkbox {
    _, widget := _checkbox(checkbox, panel, flags, tooltip, text, .NONE, false, value_pointer);
    return was_changed(widget), widget;
}

// Icon

checkbox :: (panel: *Panel, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(0, panel, flags, tooltip, "", icon_id, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (panel: *Panel, icon_id: Icon_Id, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(0, panel, flags, tooltip, "", icon_id, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (id: int, panel: *Panel, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(id, panel, flags, tooltip, "", icon_id, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (id: int, panel: *Panel, icon_id: Icon_Id, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(id, panel, flags, tooltip, "", icon_id, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (checkbox: *Checkbox, panel: *Panel, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox {
    value, widget := _checkbox(checkbox, panel, flags, tooltip, "", icon_id, initial_value, null);
    return value, widget;
}

checkbox :: (checkbox: *Checkbox, panel: *Panel, icon_id: Icon_Id, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> changed: bool, *Checkbox {
    _, widget := _checkbox(checkbox, panel, flags, tooltip, "", icon_id, false, value_pointer);
    return was_changed(widget), widget;
}

// Text & Icon

checkbox :: (panel: *Panel, text: string, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(0, panel, flags, tooltip, text, icon_id, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (panel: *Panel, text: string, icon_id: Icon_Id, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(0, panel, flags, tooltip, text, icon_id, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (id: int, panel: *Panel, text: string, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> value: bool, *Checkbox {
    value, widget := _checkbox(id, panel, flags, tooltip, text, icon_id, initial_value, null, callsite_key(callsite));
    return value, widget;
}

checkbox :: (id: int, panel: *Panel, text: string, icon_id: Icon_Id, value_pointer: *bool, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> changed: bool, *Checkbox {
    _, widget := _checkbox(id, panel, flags, tooltip, text, icon_id, false, value_pointer, callsite_key(callsite));
    return was_changed(widget), widget;
}


checkbox :: (checkbox: *Checkbox, panel: *Panel, text: string, icon_id: Icon_Id, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox {
    value, widget := _checkbox(checkbox, panel, flags, tooltip, text, icon_id, initial_value, null);
    return value, widget;
}

checkbox :: (checkbox: *Checkbox, panel: *Panel, text: string, icon_id: Icon_Id, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> changed: bool, *Checkbox {
    _, widget := _checkbox(checkbox, panel, flags, tooltip, text, icon_id, false, value_pointer);
    return was_changed(widget), widget;
}


#scope_module


checkbox_data: Table(u64, Checkbox);


_checkbox :: inline (id: int, panel: *Panel, flags: Flags, tooltip: string, text: string, icon_id: Icon_Id, initial_value: bool, value_pointer: *bool, callsite_key: u64) -> value: bool, *Checkbox {
    key := widget_key(id, currently_drawing_window, callsite_key);
    checkbox := find_or_add(*checkbox_data, key);
    value := _checkbox(checkbox, panel, flags, tooltip, text, icon_id, initial_value, value_pointer);
    return value, checkbox;
}

_checkbox :: (checkbox: *Checkbox, panel: *Panel, flags: Flags, tooltip: string, text: string, icon_id: Icon_Id, initial_value: bool, value_pointer: *bool) -> value: bool, *Checkbox {
    _value : bool = ---;
    if value_pointer
        _value = value_pointer.*;
    else if !checkbox.initialized
        _value = initial_value;
    else
        _value = checkbox.value;

    checkbox.* = .{ .{panel, .CHECKBOX, tooltip, flags}, true, _value, text, icon_id };
    last_widget_panel = panel.*;

    update_widget(checkbox);
    if was_clicked(checkbox) {
        checkbox.value = !checkbox.value;
        set_changed(checkbox);
        if value_pointer  value_pointer.* = checkbox.value;
    }

    draw_checkbox(checkbox);

    return checkbox.value, checkbox;
}
