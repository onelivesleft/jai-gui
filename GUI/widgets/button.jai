Button :: struct {
    #as using widget: Widget;

    text: string;
}


button :: (parent: *At_Location, box: Box, text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button #expand #no_debug {
    clicked, widget := _button(0, parent, box, flags, text, tooltip,  #insert #run next(*button_count));
    return clicked, widget;
}

button :: (id: int, $reserve: int, parent: *At_Location, box: Box, text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of buttons being created)");
    clicked, widget := _button(id, parent, box, flags, text, tooltip, #insert #run next(*button_count, reserve));
    return clicked, widget;
}

button :: (button: *Button, parent: *At_Location, box: Box, text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button #expand #no_debug {
    clicked, widget := _button(button, parent, box, flags, text, tooltip);
    return clicked, widget;
}


get_index :: (button: *Button) -> int {
    index := button - button_data.data;
    assert(0 <= index && index < button_data.count, "Called get_index with a user-allocated button");
    return index;
}


#scope_module


button_data : [] Button;
#no_reset button_count := 0;

_button :: inline (id: int, parent: *At_Location, box: Box, flags: Flags, text: string, tooltip: string, $gui_index: int) -> clicked: bool, *Button {
    clicked, button := _button(*button_data[gui_index + id], parent, box, flags, text, tooltip);
    return clicked, button;
}

_button :: (button: *Button, parent: *At_Location, box: Box, flags: Flags, text: string, tooltip: string) -> clicked: bool, *Button {
    button.* = .{ widget(at(parent, box), tooltip, flags), text };
    last_widget_box = box;

    update_widget(button);
    draw_button(button);

    return was_clicked(button), button;
}
