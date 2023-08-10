Label :: struct {
    #as using widget: Widget;

    text: string;
}

label :: (parent: *Panel, placement: Place, text: string, flags := Widget_Flags.NONE) -> clicked: bool, *Label #expand #no_debug {
    clicked, widget := _label(0, parent, placement, flags, text, #insert #run next(*labels_count));
    return clicked, widget;
}

label :: (id: int, $reserve: int, parent: *Panel, placement: Place, text: string, flags := Widget_Flags.NONE) -> clicked: bool, *Label #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of labels being created)");
    clicked, widget := _label(id, parent, placement, flags, text, #insert #run next(*labels_count, reserve));
    return clicked, widget;
}

get_index :: (label: *Label) -> int {
    index := label - labels.data;
    assert(0 <= index && index < labels.count);
    return index;
}


#scope_module


labels : [] Label;
#no_reset labels_count := 0;

_label :: (id: int, parent: *Panel, placement: Place, flags: Widget_Flags, text: string, $gui_index: int) -> clicked: bool, *Label {
    label := *labels[gui_index + id];
    label.* = .{ widget(parent, placement, flags | .LOCKED | .OVERFLOW), text };

    if label.flags & .HIDDEN  return false, label;

    update_widget(label);
    draw_label(label);

    return was_clicked(label), label;
}
