Label :: struct {
    #as using widget: Widget;

    text: string;
}

label :: (parent: *Panel, placement: Place, text: $T, flags := Widget_Flags.NONE) -> clicked: bool, *Label #expand #no_debug {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(0, parent, placement, flags, _text, #insert #run next(*label_count));
    return clicked, widget;
}

label :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: $T, flags := Widget_Flags.NONE) -> clicked: bool, *Label #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of labels being created)");
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(id, parent, placement, flags, _text, #insert #run next(*label_count, reserve));
    return clicked, widget;
}

get_index :: (label: *Label) -> int {
    index := label - labels.data;
    assert(0 <= index && index < labels.count);
    return index;
}


#scope_module


label_data : [] Label;
#no_reset label_count := 0;

_label :: (id: int, parent: *Panel, placement: Place, flags: Widget_Flags, text: string, $gui_index: int) -> clicked: bool, *Label {
    label := *label_data[gui_index + id];
    label.* = .{ widget(parent, placement, flags | .LOCKED | .OVERFLOW), text };
    last_widget_placement = placement;

    update_widget(label);
    draw_label(label);

    return was_clicked(label), label;
}
