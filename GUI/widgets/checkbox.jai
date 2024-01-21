Checkbox :: struct {
    #as using widget: Widget;

    initialized := false;

    value: bool;
    text: string;
}


checkbox :: (location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    value, widget := _checkbox(0, location, flags, tooltip, text, initial_value, null, #insert #run next(*checkbox_count));
    return value, widget;
}

checkbox :: (location: *At_Location, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    value, widget := _checkbox(0, location, flags, tooltip, text, false, value_pointer, #insert #run next(*checkbox_count));
    return value, widget;
}


checkbox :: (id: int, $reserve: int, location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of checkbox_data being created)");
    value, widget := _checkbox(id, location, flags, tooltip, text, initial_value, null, #insert #run next(*checkbox_count, reserve));
    return value, widget;
}

checkbox :: (id: int, $reserve: int, location: *At_Location, text: string, value_pointer : *bool = null, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of checkbox_data being created)");
    value, widget := _checkbox(id, location, flags, tooltip, text, false, value_pointer, #insert #run next(*checkbox_count, reserve));
    return value, widget;
}


checkbox :: (checkbox: *Checkbox, location: *At_Location, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    value, widget := _checkbox(checkbox, location, flags, tooltip, text, initial_value, null);
    return value, widget;
}

checkbox :: (checkbox: *Checkbox, location: *At_Location, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> value: bool, *Checkbox #expand #no_debug {
    value, widget := _checkbox(checkbox, location, flags, tooltip, text, false, value_pointer);
    return value, widget;
}


get_index :: (checkbox: *Checkbox) -> int {
    index := checkbox - checkbox_data.data;
    assert(0 <= index && index < checkbox_data.count, "Called get_index with a user-allocated checkbox");
    return index;
}


#scope_module


checkbox_data : [] Checkbox;
#no_reset checkbox_count := 0;


_checkbox :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool, $gui_index: int) -> value: bool, *Checkbox {
    value, checkbox := _checkbox(*checkbox_data[gui_index + id], location, flags, tooltip, text, initial_value, value_pointer);
    return value, checkbox;
}

_checkbox :: (checkbox: *Checkbox, location: *At_Location, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool) -> value: bool, *Checkbox {
    _value : bool = ---;
    if value_pointer && !(flags & .IMMEDIATE && is_active(checkbox))
        _value = value_pointer.*;
    else if !checkbox.initialized
        _value = initial_value;
    else
        _value = checkbox.value;

    checkbox.* = .{ widget(location, tooltip, flags), true, _value, text };
    last_widget_location = location.*;

    update_widget(checkbox);
    if was_clicked(checkbox) {
        checkbox.value = !checkbox.value;
        set_changed(checkbox);
    }
    draw_checkbox(checkbox);

    immediate_value := checkbox.value;
    if checkbox.flags & .IMMEDIATE && is_active(checkbox) && is_hot(checkbox) {
        immediate_value = !immediate_value;
        set_changed(checkbox);
    }

    if value_pointer  value_pointer.* = immediate_value;

    return immediate_value, checkbox;
}
