Label :: struct {
    #as using widget: Widget;

    text: string;
}


label :: (parent: *Panel, placement: Place, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(0, parent, placement, flags, _text, tooltip, #insert #run next(*label_count));
    return clicked, widget;
}


label :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of labels being created)");
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(id, parent, placement, flags, _text, tooltip, #insert #run next(*label_count, reserve));
    return clicked, widget;
}

label :: (label: *Label, parent: *Panel, placement: Place, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(label, parent, placement, flags, _text, tooltip);
    return clicked, widget;
}


get_index :: (label: *Label) -> int {
    index := label - label_data.data;
    assert(0 <= index && index < label_data.count, "Called get_index with a user-allocated label");
    return index;
}


#scope_module


label_data : [] Label;
#no_reset label_count := 0;

_label :: inline (id: int, parent: *Panel, placement: Place, flags: Flags, text: string, tooltip: string, $gui_index: int) -> clicked: bool, *Label {
    clicked, label:= _label(*label_data[gui_index + id], parent, placement, flags, text, tooltip);
    return clicked, label;
}

_label :: (label: *Label, parent: *Panel, placement: Place, flags: Flags, text: string, tooltip: string) -> clicked: bool, *Label {
    label.* = .{ widget(parent, placement, tooltip, flags | .LOCKED | .OVERFLOW), text };
    last_widget_placement = placement;

    update_widget(label);
    draw_label(label);

    return was_clicked(label), label;
}
