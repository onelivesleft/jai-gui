Text_Box :: struct {
    #as using widget: Widget;

    text: string;

    first_visible_row_index: int;
    visible_row_count: int;

    clicked_row_index: int;
    clicked_column_index: int;

    hot_label : *Label;

    scrollbar : Scrollbar;
    labels : [] Label;

    lines : [..] string;

    previous_width: int;
    initialized := false;
    dirty := true;
}


text_box :: (location: *At_Location, initial_text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Text_Box #expand #no_debug {
    clicked, widget := _text_box(0, location, flags, tooltip, initial_text, #insert #run next(*text_box_count));
    return clicked, widget;
}

text_box :: (id: int, $reserve: int, location: *At_Location, initial_text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Text_Box #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of text_boxs being created)");
    clicked, widget := _text_box(id, location, flags, tooltip, initial_text, #insert #run next(*text_box_count, reserve));
    return clicked, widget;
}

text_box :: (text_box: *Text_Box, location: *At_Location, initial_text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Text_Box #expand #no_debug {
    clicked, widget := _text_box(text_box, location, flags, tooltip, initial_text);
    return clicked, widget;
}

set_text :: (text_box: *Text_Box, text: string) {
    if text_box.text  free(text_box.text);
    text_box.text = copy_string(text);
    text_box.dirty = true;
}


get_index :: (text_box: *Text_Box) -> int {
    index := text_box - text_box_data.data;
    assert(0 <= index && index < text_box_data.count, "Called get_index with a user-allocated text_box");
    return index;
}

move_by_steps :: (using text_box: *Text_Box, steps: int) {
    move_by_steps(*scrollbar, steps);
}

free :: (text_box: *Text_Box) {
    if text_box.text    free(text_box.text);
    if text_box.labels  free(text_box.labels.data);
    if text_box.lines   array_free(text_box.lines);
}

label_for_text_row :: (using text_box: *Text_Box, row: int) -> *Label {
    if row < first_visible_row_index || row > first_visible_row_index + visible_row_count
        return null;
    return *labels[row - first_visible_row_index];
}


#scope_module


text_box_data : [] Text_Box;
#no_reset text_box_count := 0;

_text_box :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, initial_text: string, $gui_index: int) -> clicked: bool, *Text_Box {
    clicked, text_box := _text_box(*text_box_data[gui_index + id], location, flags, tooltip, initial_text);
    return clicked, text_box;
}

_text_box :: (text_box: *Text_Box, location: *At_Location, flags: Flags, tooltip: string, initial_text: string) -> clicked: bool, *Text_Box {
    text_box.widget = widget(.TEXT_BOX, location, "", flags | .USE_SCROLLWHEEL);
    if !text_box.initialized {
        text_box.text = copy_string(initial_text);
        text_box.initialized = true;
    }
    text_box.hot_label = null;

    clicked := update_text_box(text_box);
    draw_text_box(text_box);

    last_widget_location = location.*;

    return clicked, text_box;
}

update_text_box :: (using text_box: *Text_Box) -> bool {
    update_widget(text_box);

    clicked := false;

    visible_row_count = cast(int)(text_box.calculated_rect.h / theme.text_box_row_height);
    label_count := visible_row_count + 1;
    if labels.count < label_count {
        if labels.data  free(labels.data);
        labels = NewArray(label_count, Label);
    }

    text_panel, scrollbar_panel := split_for_right_scrollbar(text_box);
    text_rect := calculate_rect(text_panel);


    font_style := font_style_from_flags(flags, .SERIF);

    s := text;
    width := ifx flags & .NO_WRAP then 0 else cast(int)text_rect.w;
    if dirty || width != previous_width {
        dirty = false;
        previous_width = width;
        array_reset(*lines);
        line: string;
        while s {
            line, s = bite_text_line_for_width(s, font_style, theme.text_box_text_size, flags, width);
            array_add(*lines, line);
        }
    }

    offset := 0.0;
    first_visible_row_index = ifx flags & .SMOOTH {
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

    y := -cast(int)(theme.text_box_row_height * offset);
    label_flags := (flags | .INTERACTS | flags_from_font_style(font_style)) & ~.USE_SCROLLWHEEL;

    with_scissor(text_rect, flags);

    for index: 0 .. visible_row_count { // not -1 as we want to draw a partial row if the table size leaves space for one
        row_index := index + first_visible_row_index;
        if row_index >= lines.count  break;
        row_text := lines[row_index];
        if row_text && row_text[row_text.count - 1] == #char "\n"
            row_text.count -= 1;
        _label := *labels[index];

        if label(_label, at(text_panel, box(0,ord(0.0,y), 1.0,ord(0.0,y+theme.text_box_row_height))), row_text, label_flags) {
            clicked_row_index = row_index;
            clicked_column_index = 0;
            clicked = true;
        }

        if is_warm(_label) || is_hot(_label)
            hot_label = _label;

        y += theme.text_box_row_height;
    }

    return clicked;
}
