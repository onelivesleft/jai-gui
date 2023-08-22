Text_Box :: struct {
    #as using widget: Widget;

    text: string;

    clicked_row_index: int;
    clicked_column_index: int;

    hot_label : *Label;

    scrollbar : Scrollbar;
    labels : [] Label;
}


text_box :: (location: *At_Location, text: string, flags := Flags.NONE, tooltip := "") -> *Text_Box #expand #no_debug {
    widget := _text_box(0, location, flags, tooltip, text, #insert #run next(*text_box_count));
    return widget;
}

text_box :: (id: int, $reserve: int, location: *At_Location, text: string, flags := Flags.NONE, tooltip := "") -> *Text_Box #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of text_boxs being created)");
    widget := _text_box(id, location, flags, tooltip, text, #insert #run next(*text_box_count, reserve));
    return widget;
}

text_box :: (text_box: *Text_Box, location: *At_Location, text: string, flags := Flags.NONE, tooltip := "") -> *Text_Box #expand #no_debug {
    widget := _text_box(text_box, location, flags, tooltip, text);
    return widget;
}


get_index :: (text_box: *Text_Box) -> int {
    index := text_box - text_box_data.data;
    assert(0 <= index && index < text_box_data.count, "Called get_index with a user-allocated text_box");
    return index;
}

move_by_steps :: (using text_box: *Text_Box, steps: int) {
    move_by_steps(*scrollbar, steps);
}

use_scrollwheel :: (using text_box: *Text_Box, force := false) {
    use_scrollwheel(*scrollbar, force);
}

free :: (text_box: *Text_Box) {
    if text_box.labels  free(text_box.labels.data);
}



#scope_module


text_box_data : [] Text_Box;
#no_reset text_box_count := 0;

_text_box :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, text: string, $gui_index: int) -> *Text_Box {
    text_box := _text_box(*text_box_data[gui_index + id], location, flags, tooltip, text);
    return text_box;
}

_text_box :: (text_box: *Text_Box, location: *At_Location, flags: Flags, tooltip: string, text: string) -> *Text_Box {
    text_box.widget = widget(location, "", flags);
    text_box.text = text;
    text_box.hot_label = null;

    update_text_box(text_box);
    draw_text_box(text_box);

    last_widget_location = location.*;

    return text_box;
}

update_text_box :: (using text_box: *Text_Box) {
    maybe_calculate_rect(text_box);

    visible_row_count := cast(int)(text_box.rect.h / theme.text_box_row_height);
    label_count := visible_row_count + 1;
    if labels.count < label_count {
        if labels.data  free(labels.data);
        labels = NewArray(label_count, Label);
    }

    text_panel, scrollbar_panel := split_scrollbar_right(text_box);
    text_rect := calculate_rect(text_panel);

    lines : [..] string;
    defer array_free(lines);

    font_style := font_style_from_flags(flags, .SERIF);

    s := text;
    line_end_index := 0;
    line: string;
    while s {
        line, s = bite_text_line_for_width(s, font_style, theme.text_box_text_size, flags, xx text_rect.w);
        array_add(*lines, line);
    }

    offset := 0.0;
    top_index := ifx flags & .SMOOTH {
                    count := cast(float)(lines.count - visible_row_count - 1);
                    count = max(1.0, count);
                    f := vertical_scrollbar(*scrollbar, at(scrollbar_panel, box(.FILL)), 0, .{0, count}, handle_size=1.0 / (count/visible_row_count), flags);
                    result := cast(int) f;
                    offset = f - result;
                    result;
                 }
                 else {
                    vertical_scrollbar(*scrollbar, at(scrollbar_panel, box(.FILL)), 0, .{0, lines.count - visible_row_count - 1});
                 };

    do_scrollwheel := false;

    y := -cast(int)(theme.text_box_row_height * offset);
    label_flags := flags | .INTERACTS | flags_from_font_style(font_style);

    with_scissor(text_rect, flags);

    for index: 0 .. visible_row_count { // not -1 as we want to draw a partial row if the table size leaves space for one
        row_index := index + top_index;
        if row_index >= lines.count  break;
        row_text := lines[row_index];
        if row_text && row_text[row_text.count - 1] == #char "\n"
            row_text.count -= 1;
        _label := *labels[index];

        if label(_label, at(text_panel, box(0,ord(0.0,y), 1.0,ord(0.0,y+theme.text_box_row_height))), row_text, label_flags) {
            clicked_row_index = row_index;
            clicked_column_index = 0;
        }

        if is_hot(_label) || is_active(_label) {
            hot_label = _label;
            do_scrollwheel = true;
        }

        y += theme.text_box_row_height;
    }

    if do_scrollwheel  use_scrollwheel(text_box);
}
