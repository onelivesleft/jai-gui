Data_Table :: struct(T: Type) {
    #as using widget: Widget;

    data : [] T;

    clicked_item: *T;
    clicked_header: bool;
    clicked_item_row_index: int;
    clicked_item_column_index: int;

    selected_row_index := -1;

    first_label_on_hot_row: *Label;
    first_label_on_selected_row: *Label;

    scrollbar: Scrollbar;
    buttons: [] Button;
    labels: [] Label;

    #insert -> string {
        #if T == void {
            return "";
        }
        else {
            info := type_info(T);
            builder : String_Builder;
            column_flags : [..] u64;
            column_ends : [..] Ord;
            abs_total := 0;
            rel_total := 0.0;
            for member: info.members {
                o := get_note_value(member.notes, "Width", ord(0));
                abs_total += o.abs;
                rel_total += o.rel;
                array_add(*column_ends, ord(abs_total, rel_total));

                flags : Flags;
                if get_note(member.notes, "Left")    flags |= .LEFT;
                if get_note(member.notes, "Right")   flags |= .RIGHT;
                if get_note(member.notes, "Center")  flags |= .CENTER;
                if get_note(member.notes, "Sans")    flags |= .SANS;
                if get_note(member.notes, "Serif")   flags |= .SERIF;
                if get_note(member.notes, "Fixed")   flags |= .FIXED;
                if flags & .CENTER == 0  flags |= .CENTER;
                array_add(*column_flags, cast(u64)flags);
            }
            column_ends[column_ends.count - 1] = ord(1.0);
            print_to_builder(*builder, #string jai
                columns :: %;
                column_flags :: u64.[
            jai, column_ends.count);

            for member: info.members {
                print_to_builder(*builder, #string jai
                    %,
                jai, column_flags[it_index]);
            }
            append(*builder, #string jai
                ];
                column_ends :: Ord.[
            jai);
            for member: info.members {
                print_to_builder(*builder, #string jai
                        .{%, %},
                jai, formatFloat(column_ends[it_index].rel, zero_removal=.NO), column_ends[it_index].abs);
            }
            append(*builder, #string jai
                ];
            jai);
            return builder_to_string(*builder);
        }
    }
}

keep_selection : int = 0xffff_ffff;

data_table :: (parent: *At_Location, box: Box, data: [] $T, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    clicked, widget := _data_table(0, parent, box, flags, data, keep_selection, #insert #run next(*data_table_count));
    return clicked, widget;
}

data_table :: (id: int, $reserve: int, parent: *At_Location, box: Box, data: [] $T, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of data_tables being created)");
    clicked, widget := _data_table(id, parent, box, flags, data, keep_selection, #insert #run next(*data_table_count, reserve));
    return clicked, widget;
}

data_table :: (data_table: *Data_Table, parent: *At_Location, box: Box, data: [] $T, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    clicked, widget := _data_table(data_table, parent, box, flags, data, keep_selection);
    return clicked, widget;
}


data_table :: (parent: *At_Location, box: Box, data: [] $T, selected_row_index: int, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    clicked, widget := _data_table(0, parent, box, flags, data, selected_row_index, #insert #run next(*data_table_count));
    return clicked, widget;
}

data_table :: (id: int, $reserve: int, parent: *At_Location, box: Box, data: [] $T, selected_row_index: int, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of data_tables being created)");
    clicked, widget := _data_table(id, parent, box, flags, data, selected_row_index, #insert #run next(*data_table_count, reserve));
    return clicked, widget;
}

data_table :: (data_table: *Data_Table, parent: *At_Location, box: Box, data: [] $T, selected_row_index: int, flags := Flags.NONE) -> clicked: bool, *Data_Table(T) #expand #no_debug {
    clicked, widget := _data_table(data_table, parent, box, flags, data, selected_row_index);
    return clicked, widget;
}

free :: (data_table: *Data_Table) {
    if data_table.buttons  free(data_table.buttons.data);
    if data_table.labels  free(data_table.labels.data);
}

get_index :: (data_table: *Data_Table) -> int {
    index := data_table - data_table_data.data;
    assert(0 <= index && index < data_table_data.count, "Called get_index with a user-allocated data_table");
    return index;
}


select_row :: (using data_table: *Data_Table, row_index: int, toggle_if_already_selected := false) {
    if toggle_if_already_selected && selected_row_index == row_index
        selected_row_index = -1;
    else
        selected_row_index = row_index;
}

select_clicked_row :: (using data_table: *Data_Table, toggle_if_already_selected := false) {
    if clicked_item  select_row(data_table, clicked_item_row_index, toggle_if_already_selected);
}

clear_row_selection :: (using data_table: *Data_Table) {
    selected_row_index = -1;
}

move_by_steps :: (using data_table: *Data_Table, steps: int) {
    move_by_steps(*scrollbar, steps);
}

use_scrollwheel :: (using data_table: *Data_Table, force := false) {
    use_scrollwheel(*scrollbar, force);
}


to_string :: (i: $T) -> string {
    return tprint("%", i);
}

sort :: (data: [] $T, member_index: int, reversed: bool)
#modify {
    info := cast(*Type_Info) T;
    return info.type == .STRUCT, "data must be array of struct!";
} {
    _sort :: (data: [] $T, $member_index: int, $reversed: bool) {
        #insert -> string {
            info := type_info(T);
            assert(member_index >= 0 && member_index < info.members.count);
            vars :: string.["a", "b"];
            return tprint(#string jai
                quick_sort(data, (a, b) => compare(%2.%1, %3.%1));
            jai, info.members[member_index].name, vars[xx reversed], vars[xx !reversed]);
        }
    }

    #insert -> string {
        builder : String_Builder;
        append(*builder, #string jai
            if member_index == {
        jai);
        info := type_info(T);
        for 0 .. info.members.count - 1 {
            print_to_builder(*builder, #string jai
                case %1;
                if reversed  _sort(data, %1, true);
                else         _sort(data, %1, false);

            jai, it);
        }
        append(*builder, #string jai
            }
        jai);
        return builder_to_string(*builder);
    }
}

compare :: inline (a: $T, b: T) -> int
#modify {
    info := cast(*Type_Info) T;
    return info.type == .INTEGER || info.type == .FLOAT || info.type == .STRING, "This compare only handles ints, floats, and strings";
}
{
    #insert -> string {
        info := cast(*Type_Info) T;
        if info.type == .INTEGER  return #string jai
            return a - b;
        jai;

        if info.type == .FLOAT  return #string jai
            return compare_floats(a, b);
        jai;

        return #string jai
            return compare_strings(a, b);
        jai;
    }
}


#scope_module


data_table_data : [] Data_Table(void);
#no_reset data_table_count := 0;

_data_table :: inline (id: int, parent: *At_Location, box: Box, flags: Flags, data: [] $T, selected_row_index: int, $gui_index: int) -> clicked: bool, *Data_Table(T) {
    #assert(size_of(Data_Table(T)) == size_of(type_of(data_table_data[0])));
    clicked, data_table := _data_table(cast(*Data_Table(T))*data_table_data[gui_index + id], parent, box, flags, data, selected_row_index);
    return clicked, data_table;
}

_data_table :: (data_table: *Data_Table(T), parent: *At_Location, box: Box, flags: Flags, data: [] $T, selected_row_index: int) -> clicked: bool, *Data_Table(T)
#modify {
    info := cast(*Type_Info) T;
    return info.type == .STRUCT, "data must be array of struct!";
} {
    if !data_table.buttons {
        data_table.buttons = NewArray(data_table.columns + 1, Button);
        assert(data_table.labels.count == 0);
    }

    data_table.widget = widget(at(parent, box), "", flags);
    data_table.data = data;
    data_table.clicked_item = null;
    data_table.clicked_header = false;
    data_table.first_label_on_hot_row = null;
    data_table.first_label_on_selected_row = null;
    if selected_row_index != keep_selection
        data_table.selected_row_index = selected_row_index;

    update_data_table(data_table);
    draw_data_table(data_table);

    return data_table.clicked_header || data_table.clicked_item, data_table;
}

update_data_table :: (using data_table: *Data_Table) {
    maybe_calculate_rect(data_table);

    visible_row_count := cast(int)(data_table.rect.h / theme.data_table_row_height) - 1;
    label_count := (visible_row_count + 1) * columns;
    if labels.count < label_count {
        if labels.data  free(labels.data);
        labels = NewArray(label_count, Label);
    }

    top, bottom := split_top_bottom(data_table, theme.data_table_row_height);
    header_row, top_right_stub := split_scrollbar_right(top);
    table_panel, scrollbar_panel := split_scrollbar_right(bottom);

    top_index := vertical_scrollbar(*scrollbar, scrollbar_panel, get_box(.FILL), 0, .{0, data.count - visible_row_count - 1});

    left_ord, right_ord: Ord;
    do_scrollwheel := false;

    jump_to_top_or_bottom_or_selection := false;
    jump_destination : enum { TOP; SELECTION; BOTTOM; } = .TOP;
    if selected_row_index >= 0 {
        if top_index + visible_row_count < selected_row_index
            jump_destination = .SELECTION;
        else if scrollbar.int_value < scrollbar.int_range.max
            jump_destination = .BOTTOM;
    }
    else {
        if scrollbar.int_value == 0
            jump_destination = .BOTTOM;
    }

    #insert -> string {
        info := type_info(T);
        builder : String_Builder;
        for member: info.members {
            print_to_builder(*builder, #string jai
                right_ord = %4;
                if button(*buttons[%3], header_row, get_box(left_ord,0, right_ord,1.0), "%1", %2) {
                    clicked_header = true;
                    clicked_item_row_index = -1;
                    clicked_item_column_index = %3;
                }
                if is_hot(*buttons[%3])  do_scrollwheel = true;
                left_ord = right_ord;
            jai, member.name, column_flags[it_index], it_index, ord_constructor(column_ends[it_index]));
        }
        return builder_to_string(*builder);
    }

    jump_tooltip := ifx jump_destination == .TOP then "Jump to top" else ifx jump_destination == .BOTTOM then "Jump to bottom" else "Jump to selected row";
    jump_to_top_or_bottom_or_selection = button(*buttons[columns], top_right_stub, get_box(.FILL), "", tooltip=jump_tooltip);

    y := 0;

    for index: 0 .. visible_row_count { // not -1 as we want to draw a partial row if the table size leaves space for one
        row_index := index + top_index;
        if row_index >= data.count  break;
        row_item := data[row_index];
        first_label_on_row, _label := *labels[index * columns];

        if row_index == selected_row_index
            first_label_on_selected_row = first_label_on_row;

        left_ord, right_ord = ord(0), ord(0);

        #insert -> string {
            info := type_info(T);
            builder : String_Builder;
            for member: info.members {
                print_to_builder(*builder, #string jai
                    right_ord = %4;
                    if label(_label, at(table_panel, get_box(left_ord,y, right_ord,y+theme.data_table_row_height)), to_string(row_item.%1), Flags.INTERACTS | .CROP | %2) {
                        clicked_item = *data[row_index];;
                        clicked_item_row_index = row_index;
                        clicked_item_column_index = %3;
                    }
                    if is_hot(_label) || is_active(_label) {
                        first_label_on_hot_row = first_label_on_row;
                        do_scrollwheel = true;
                    }
                    left_ord = right_ord;
                    _label += 1;
                jai, member.name, column_flags[it_index], it_index, ord_constructor(column_ends[it_index]));
            }
            append(*builder, #string jai
                    y += theme.data_table_row_height;
            jai);
            return builder_to_string(*builder);
        }
    }

    if do_scrollwheel  use_scrollwheel(data_table);

    if jump_to_top_or_bottom_or_selection {
        if #complete jump_destination == {
            case .TOP;        scrollbar.int_value = 0;
            case .SELECTION;  scrollbar.int_value = max(0, selected_row_index - visible_row_count / 2);
            case .BOTTOM;     scrollbar.int_value = scrollbar.int_range.max;
        }
    }
}
