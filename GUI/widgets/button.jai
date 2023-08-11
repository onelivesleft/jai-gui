Button :: struct {
    #as using widget: Widget;

    text: string;
}

button :: (parent: *Panel, placement: Place, text: string, flags := Widget_Flags.NONE) -> clicked: bool, *Button #expand #no_debug {
    clicked, widget := _button(0, parent, placement, flags, text, #insert #run next(*button_count));
    return clicked, widget;
}

button :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: string, flags := Widget_Flags.NONE) -> clicked: bool, *Button #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of buttons being created)");
    clicked, widget := _button(id, parent, placement, flags, text, #insert #run next(*button_count, reserve));
    return clicked, widget;
}

get_index :: (button: *Button) -> int {
    index := button - buttons.data;
    assert(0 <= index && index < buttons.count);
    return index;
}


#scope_module


button_data : [] Button;
#no_reset button_count := 0;

_button :: (id: int, parent: *Panel, placement: Place, flags: Widget_Flags, text: string, $gui_index: int) -> clicked: bool, *Button {
    button := *button_data[gui_index + id];
    button.* = .{ widget(parent, placement, flags), text };
    last_widget_placement = placement;

    update_widget(button);
    draw_button(button);

    return was_clicked(button), button;
}
