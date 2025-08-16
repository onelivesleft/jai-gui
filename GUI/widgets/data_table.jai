Data_Table :: struct(T: Type)
#modify {
    return T == void || is_struct_or_pointer_to_struct(T) , "data must be an array of struct or pointer-to-struct";
} {
    #as using widget: Widget;
    type = .DATA_TABLE;

    data : [] T;

    selected_row_index := -1;

    first_label_on_warm_row: *Label;
    first_label_on_selected_row: *Label;

    scrollbar: Scrollbar;
    buttons: [] Button;
    labels: [] Label;

    last_clicked_header_index: int;
    last_clicked_header_parity: bool;

    clicked_header: bool;
    clicked_item_row_index: int;
    clicked_item_column_index: int;

    #insert -> string {
        #if T == void {
            return #string jai
                clicked_item: *T;
                default_last_clicked_header_index :: 0;
                default_last_clicked_header_parity :: false;
            jai;
        }
        else {
            _, info := is_struct_or_pointer_to_struct(T);
            is_pointer_array := (cast(*Type_Info)T).type == .POINTER;
            builder : String_Builder;
            column_flags : [..] u64;
            column_ends : [..] Ord;
            column_visible : [..] bool;
            visible_column_count := 0;
            abs_total := 0;
            rel_total := 0.0;
            default_sort_index := -1;
            default_sort_parity := false;
            for member: info.members {
                hidden := get_note(member.notes, "Hidden");
                o := ifx hidden
                     then ord(0)
                     else get_note_value(member.notes, "Width", ord(0));
                if !hidden {
                    array_add(*column_visible, true);
                    visible_column_count += 1;
                }
                else {
                    array_add(*column_visible, false);
                }
                abs_total += o.abs;
                rel_total += o.rel;
                array_add(*column_ends, ord(abs_total, rel_total));

                flags : Flags;
                if get_note(member.notes, "Left")            flags |= .LEFT;
                if get_note(member.notes, "Right")           flags |= .RIGHT;
                if get_note(member.notes, "Center")          flags |= .CENTER;
                if get_note(member.notes, "Sans")            flags |= .SANS;
                if get_note(member.notes, "Serif")           flags |= .SERIF;
                if get_note(member.notes, "Fixed")           flags |= .FIXED;
                if get_note(member.notes, "SansAlternate")   flags |= .SANS_ALTERNATE;
                if get_note(member.notes, "SerifAlternate")  flags |= .SERIF_ALTERNATE;
                if get_note(member.notes, "FixedAlternate")  flags |= .FIXED_ALTERNATE;
                if get_note(member.notes, "Icon")            flags |= .ICON;
                if get_note(member.notes, "DefaultSort") {
                    default_sort_index = it_index;
                    default_sort_parity = false;
                }
                if get_note(member.notes, "DefaultSortReverse") {
                    default_sort_index = it_index;
                    default_sort_parity = true;
                }
                if flags & .CENTER == 0  flags |= .CENTER;
                array_add(*column_flags, cast(u64)flags);
            }
            column_ends[column_ends.count - 1] = ord(1.0);

            clicked_item_type := ifx is_pointer_array then "T" else "*T";
            print_to_builder(*builder, #string jai
                clicked_item: %;

                default_last_clicked_header_index :: %;
                default_last_clicked_header_parity :: %;

                is_pointer_array :: %;
                columns :: %;
                visible_columns :: %;
                column_flags :: u64.[
            jai, clicked_item_type, default_sort_index, default_sort_parity, is_pointer_array, column_ends.count, visible_column_count);

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
                column_visible :: bool.[
            jai);
            for member: info.members {
                print_to_builder(*builder, #string jai
                        %,
                jai, column_visible[it_index]);
            }
            append(*builder, #string jai
                ];
                column_headers :: string.[
            jai);
            for member: info.members {
                print_to_builder(*builder, #string jai
                        "%",
                jai, get_note_value(member.notes, "Title", ""));
            }
            append(*builder, #string jai
                ];
                column_tooltips :: string.[
            jai);
            for member: info.members {
                print_to_builder(*builder, #string jai
                        "%",
                jai, get_note_value(member.notes, "Tooltip", ""));
            }
            append(*builder, #string jai
                ];
            jai);
            return builder_to_string(*builder);
        }
    }
}

keep_selection : int = 0xffff_ffff;

data_table :: (location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, flags := Flags.NONE, $callsite := #caller_location) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(0, location, flags, data, keep_selection, callsite_key(callsite));
    return clicked, widget;
}

data_table :: (id: int, $reserve: int, location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, flags := Flags.NONE, $callsite := #caller_location) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(id, location, flags, data, keep_selection, callsite_key(callsite));
    return clicked, widget;
}

data_table :: (data_table: *Data_Table, location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, flags := Flags.NONE) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(data_table, location, flags, data, keep_selection);
    return clicked, widget;
}


data_table :: (location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, selected_row_index: int, flags := Flags.NONE, $callsite := #caller_location) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(0, location, flags, data, selected_row_index, callsite_key(callsite));
    return clicked, widget;
}

data_table :: (id: int, $reserve: int, location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, selected_row_index: int, flags := Flags.NONE, $callsite := #caller_location) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(id, location, flags, data, selected_row_index, callsite_key(callsite));
    return clicked, widget;
}

data_table :: (data_table: *Data_Table, location: *At_Location, data: [] $STRUCT_OR_POINTER_TO_STRUCT, selected_row_index: int, flags := Flags.NONE) -> clicked: bool, *Data_Table(STRUCT_OR_POINTER_TO_STRUCT) {
    clicked, widget := _data_table(data_table, location, flags, data, selected_row_index);
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

to_string :: (i: $T) -> string {
    return tprint("%", i);
}

sort :: inline (data: [] $T, data_table: *Data_Table($U))
#modify {
    t_ok, t_info := is_struct_or_pointer_to_struct(T);
    _, u_info := is_struct_or_pointer_to_struct(U);
    return t_ok && t_info == u_info , "data must be an array of struct or pointer-to-struct";
} {
    sort(data, data_table.last_clicked_header_index, data_table.last_clicked_header_parity);
}

sort :: (data: [] $T, member_index: int, reversed: bool)
#modify {
    return is_struct_or_pointer_to_struct(T) , "data must be an array of struct or pointer-to-struct";
} {
    _sort :: (data: [] $T, $member_index: int, $reversed: bool) {
        #insert -> string {
            _, info := is_struct_or_pointer_to_struct(T);
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
        _, info := is_struct_or_pointer_to_struct(T);
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


data_table_data : Table(u64, Data_Table(void));


_data_table :: inline (id: int, location: *At_Location, flags: Flags, data: [] $T, selected_row_index: int, callsite_key: u64) -> clicked: bool, *Data_Table(T)
#modify {
    return T == void || is_struct_or_pointer_to_struct(T) , "data must be an array of struct or pointer-to-struct";
} {
    key := widget_key(id, currently_drawing_window, callsite_key);
    data_table := cast(*Data_Table(T)) find_or_add(*data_table_data, key);
    #assert(size_of(Data_Table(T)) == size_of(type_of(data_table.*)));
    clicked := _data_table(cast(*Data_Table(T))data_table, location, flags, data, selected_row_index);
    return clicked, data_table;
}

_data_table :: (data_table: *Data_Table(T), location: *At_Location, flags: Flags, data: [] $T, selected_row_index: int) -> clicked: bool, *Data_Table(T)
#modify {
    return T == void || is_struct_or_pointer_to_struct(T) , "data must be an array of struct or pointer-to-struct";
} {
    if !data_table.buttons {
        data_table.buttons = NewArray(data_table.columns + 1, Button);
        assert(data_table.labels.count == 0);
        data_table.last_clicked_header_index = data_table.default_last_clicked_header_index;
        data_table.last_clicked_header_parity = data_table.default_last_clicked_header_parity;
    }

    data_table.widget = .{location, .DATA_TABLE, "", flags | .USE_SCROLLWHEEL};
    data_table.data = data;
    data_table.clicked_item = null;
    data_table.clicked_header = false;
    data_table.first_label_on_warm_row = null;
    data_table.first_label_on_selected_row = null;
    if selected_row_index != keep_selection
        data_table.selected_row_index = selected_row_index;

    update_data_table(data_table);
    draw_data_table(data_table);

    last_widget_location = location.*;

    return data_table.clicked_header || data_table.clicked_item, data_table;
}

update_data_table :: (using data_table: *Data_Table) {
    update_widget(data_table);
    with_scissor(data_table.calculated_rect);

    visible_row_count := cast(int)(data_table.calculated_rect.h / theme.data_table_row_height) - 1;
    label_count := (visible_row_count + 1) * columns;
    if labels.count < label_count {
        if labels.data  free(labels.data);
        labels = NewArray(label_count, Label);
    }

    top, bottom := split_top_bottom(data_table, theme.data_table_row_height);
    header_row, top_right_stub := split_for_right_scrollbar(top);
    table_panel, scrollbar_panel := split_for_right_scrollbar(bottom);

    top_index := vertical_scrollbar(*scrollbar, at(scrollbar_panel, box(.FILL)), 0, .{0, data.count - visible_row_count - 1});

    left_ord, right_ord: Ord;

    jump_to_top_or_bottom_of_selection := false;
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
        base_info : *Type_Info = type_info(T);
        info : *Type_Info_Struct = ifx base_info.type == .POINTER
                                   then cast(*Type_Info_Struct)(cast(*Type_Info_Pointer)base_info).pointer_to
                                   else cast(*Type_Info_Struct)base_info;
        assert(info.type == .STRUCT);
        builder : String_Builder;
        for member: info.members {
            if !column_visible[it_index]  continue;
            print_to_builder(*builder, #string jai
                right_ord = %4;
                if button(*buttons[%3], at(header_row, box(left_ord,0, right_ord,1.0)), "%1", flags=%2, tooltip="%5") {
                    clicked_header = true;
                    clicked_item_row_index = -1;
                    clicked_item_column_index = %3;
                    if last_clicked_header_index == %3
                        last_clicked_header_parity = !last_clicked_header_parity;
                    else
                        last_clicked_header_index = %3;
                }
                left_ord = right_ord;
            jai, ifx column_headers[it_index] then column_headers[it_index] else member.name,
                 column_flags[it_index],
                 it_index,
                 ord_constructor(column_ends[it_index]),
                 column_tooltips[it_index]
            );
        }
        return builder_to_string(*builder);
    }

    jump_tooltip := ifx jump_destination == .TOP then "Jump to top" else ifx jump_destination == .BOTTOM then "Jump to bottom" else "Jump to selected row";
    jump_to_top_or_bottom_of_selection = button(*buttons[columns], at(top_right_stub, box(.FILL)), "", tooltip=jump_tooltip);

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
            _, info := is_struct_or_pointer_to_struct(T);
            builder : String_Builder;
            for member: info.members {
                if !column_visible[it_index]  continue;
                print_to_builder(*builder, #string jai
                    right_ord = %4;
                    if label(_label, at(table_panel, box(left_ord,y, right_ord,y+theme.data_table_row_height)), to_string(row_item.%1), Flags.INTERACTS | .CROP | %2) {
                        clicked_item = %5data[row_index];;
                        clicked_item_row_index = row_index;
                        clicked_item_column_index = %3;
                    }
                    if is_warm(_label) || is_hot(_label)
                        first_label_on_warm_row = first_label_on_row;
                    left_ord = right_ord;
                    _label += 1;
                jai, member.name, column_flags[it_index], it_index, ord_constructor(column_ends[it_index]), ifx !is_pointer_array then "*");
            }
            append(*builder, #string jai
                    y += theme.data_table_row_height;
            jai);
            return builder_to_string(*builder);
        }
    }

    if jump_to_top_or_bottom_of_selection {
        if #complete jump_destination == {
            case .TOP;        scrollbar.int_value = 0;
            case .SELECTION;  scrollbar.int_value = max(0, selected_row_index - visible_row_count / 2);
            case .BOTTOM;     scrollbar.int_value = scrollbar.int_range.max;
        }
    }
}
