Text_Input :: struct {
    #as using widget: Widget;

    initialized := false;

    text: string;
}

text_input :: (parent: *Panel, placement: Place, initial_text: string, flags := Widget_Flags.NONE, tooltip := "") -> text: *string, *Text_Input #expand #no_debug {
    text, widget := _text_input(0, parent, placement, flags, initial_text, tooltip,  #insert #run next(*text_input_count));
    return text, widget;
}

text_input :: (id: int, $reserve: int, parent: *Panel, placement: Place, initial_text: string, flags := Widget_Flags.NONE, tooltip := "") -> text: *string, *Text_Input #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of inputs being created)");
    text, widget := _text_input(id, parent, placement, flags, initial_text, tooltip, #insert #run next(*text_input_count, reserve));
    return text, widget;
}

get_index :: (text_input: *Text_Input) -> int {
    index := text_input - text_input_data.data;
    assert(0 <= index && index < text_input_data.count);
    return index;
}


#scope_module


text_input_data : [] Text_Input;
#no_reset text_input_count := 0;

_text_input :: (id: int, parent: *Panel, placement: Place, flags: Widget_Flags, initial_text: string, tooltip: string, $gui_index: int) -> text: *string, *Text_Input {
    text_input := *text_input_data[gui_index + id];
    text := ifx text_input.initialized then text_input.text else copy_string(initial_text);
    text_input.* = .{ widget(parent, placement, tooltip, flags), true, text };
    last_widget_placement = placement;

    update_widget(text_input);
    draw_text_input(text_input);

    return *text_input.text, text_input;
}
