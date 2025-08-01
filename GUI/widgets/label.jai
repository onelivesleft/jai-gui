Label :: struct {
    #as using widget: Widget;

    text: string;
}


label :: (location: *At_Location, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    //widget := get_label(#insert #run next(*label_count));
    clicked, widget := _label(0, location, flags, _text, tooltip, #insert #run next(*label_count));
    return clicked, widget;
}


label :: (id: int, $reserve: int, location: *At_Location, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of labels being created)");
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(id, location, flags, _text, tooltip, #insert #run next(*label_count, reserve));
    return clicked, widget;
}

label :: (label: *Label, location: *At_Location, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label #expand #no_debug {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(label, location, flags, _text, tooltip);
    return clicked, widget;
}


#scope_module


label_data : [] Label;
#no_reset label_count := 0;

get_label :: (index: int) -> *Label {
    widget := label_data[index];
    if widget.type == .LABEL {
        if widget.updated_on_frame_index == frame.index {
            // We've already referred to this widget this frame, so we need to move it to the widget pool
            // and access it via the widget_table.
            new_widget := New(Label,, widget_allocator);
            table_add(*widget_table, .{index, 0}, new_widget);
            memcpy(new_widget, widget, size_of(Label));

            // Convert the label_data entry into a Widget_Indirect.
            indirect := cast(*Widget_Indirect) widget;
            indirect.type = .INDIRECT;
            indirect.last_used_widget_index = 0;
        }
        else {
            return widget;
        }
    }

    indirect := cast(*Widget_Indirect) widget;
    indirect.last_used_widget_index += 1;
    widget_id := Widget_Id.{index, indirect.last_used_widget_index};

    entry, created := find_or_add(*widget_table, widget_id);
    if created  entry.* = New(Label,, widget_allocator);
    return entry.*;
}

_label :: inline (id: int, location: *At_Location, flags: Flags, text: string, tooltip: string, $gui_index: int) -> clicked: bool, *Label {
    clicked, label:= _label(*label_data[gui_index + id], location, flags, text, tooltip);
    return clicked, label;
}

_label :: (label: *Label, location: *At_Location, flags: Flags, text: string, tooltip: string) -> clicked: bool, *Label {
    label.* = .{ widget(.LABEL, location, tooltip, flags | .LOCKED | .OVERFLOW), text };
    last_widget_location = location.*;

    update_widget(label);
    draw_label(label);

    return was_clicked(label), label;
}
