Checkbox :: struct {
    #as using widget: Widget;

    initialized := false;

    value: bool;
    text: string;
}


checkbox :: (parent: *Panel, placement: Place, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    clicked, widget := _checkbox(0, parent, placement, flags, tooltip, text, initial_value, null, #insert #run next(*checkbox_count));
    return clicked, widget;
}

checkbox :: (parent: *Panel, placement: Place, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    clicked, widget := _checkbox(0, parent, placement, flags, tooltip, text, false, value_pointer, #insert #run next(*checkbox_count));
    return clicked, widget;
}


checkbox :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of checkbox_data being created)");
    clicked, widget := _checkbox(id, parent, placement, flags, tooltip, text, initial_value, null, #insert #run next(*checkbox_count, reserve));
    return clicked, widget;
}

checkbox :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: string, value_pointer : *bool = null, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of checkbox_data being created)");
    clicked, widget := _checkbox(id, parent, placement, flags, tooltip, text, false, value_pointer, #insert #run next(*checkbox_count, reserve));
    return clicked, widget;
}


checkbox :: (checkbox: *Checkbox, parent: *Panel, placement: Place, text: string, initial_value := false, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    clicked, widget := _checkbox(checkbox, parent, placement, flags, tooltip, text, initial_value, null);
    return clicked, widget;
}

checkbox :: (checkbox: *Checkbox, parent: *Panel, placement: Place, text: string, value_pointer : *bool, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Checkbox #expand #no_debug {
    clicked, widget := _checkbox(checkbox, parent, placement, flags, tooltip, text, false, value_pointer);
    return clicked, widget;
}


get_index :: (checkbox: *Checkbox) -> int {
    index := checkbox - checkbox_data.data;
    assert(0 <= index && index < checkbox_data.count, "Called get_index with a user-allocated checkbox");
    return index;
}


#scope_module


checkbox_data : [] Checkbox;
#no_reset checkbox_count := 0;


_checkbox :: inline (id: int, parent: *Panel, placement: Place, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool, $gui_index: int) -> clicked: bool, *Checkbox {
    clicked, checkbox := _checkbox(*checkbox_data[gui_index + id], parent, placement, flags, tooltip, text, initial_value, value_pointer);
    return clicked, checkbox;
}

_checkbox :: (checkbox: *Checkbox, parent: *Panel, placement: Place, flags: Flags, tooltip: string, text: string, initial_value: bool, value_pointer: *bool) -> clicked: bool, *Checkbox {
    _value : bool = ---;
    if value_pointer && !(flags & .IMMEDIATE && is_active(checkbox))
        _value = value_pointer.*;
    else if !checkbox.initialized
        _value = initial_value;
    else
        _value = checkbox.value;

    checkbox.* = .{ widget(parent, placement, tooltip, flags), true, _value, text };
    last_widget_placement = placement;

    update_widget(checkbox);
    if was_clicked(checkbox)
        checkbox.value = !checkbox.value;
    draw_checkbox(checkbox);

    immediate_value := checkbox.value;
    if checkbox.flags & .IMMEDIATE && is_active(checkbox) && is_hot(checkbox)
        immediate_value = !immediate_value;

    if value_pointer  value_pointer.* = immediate_value;

    return immediate_value, checkbox;
}
