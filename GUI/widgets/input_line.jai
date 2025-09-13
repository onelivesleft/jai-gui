Input_Line :: struct {
    #as using widget: Widget;

    initialized := false;

    text: string;
}


input_line :: (panel: *Panel, initial_text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> text: string, *Input_Line {
    text, widget := _input_line(0, panel, flags, initial_text, tooltip, callsite_key(callsite));
    return text, widget;
}

input_line :: (id: int, panel: *Panel, initial_text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> text: string, *Input_Line {
    text, widget := _input_line(id, panel, flags, initial_text, tooltip, callsite_key(callsite));
    return text, widget;
}

input_line :: (input_line: *Input_Line, panel: *Panel, initial_text: string, flags := Flags.NONE, tooltip := "") -> text: string, *Input_Line {
    text, widget := _input_line(input_line, panel, flags, initial_text, tooltip);
    return text, widget;
}


set_text :: (input_line: *Input_Line, text: string) {
    if has_focus(input_line) && input_line.flags & .IMMEDIATE
        set_text_edit(input_line, text);
    else {
        if input_line.text  free(input_line.text);
        input_line.text = copy_string(text);
        set_changed(input_line);
    }
}


#scope_module


input_line_data: Table(u64, Input_Line);


_input_line :: inline (id: int, panel: *Panel, flags: Flags, initial_text: string, tooltip: string, callsite_key: u64) -> text: string, *Input_Line {
    key := widget_key(id, currently_drawing_window, callsite_key);
    input_line := find_or_add(*input_line_data, key);
    text := _input_line(input_line, panel, flags, initial_text, tooltip);
    return text, input_line;
}

_input_line :: (input_line: *Input_Line, panel: *Panel, flags: Flags, initial_text: string, tooltip: string) -> text: string, *Input_Line {
    text := ifx input_line.initialized then input_line.text else copy_string(initial_text);
    input_line.* = .{ .{panel, .INPUT_LINE, tooltip, flags}, true, text };
    last_widget_panel = panel.*;

    update_input_line(input_line);

    if is_hot(input_line) {
        character_index := draw_input_line(input_line, query_character_index=true, mouse.position);
        text_edit_set_cursor(character_index, !was_clicked(input_line));
    }
    else {
        draw_input_line(input_line);
    }

    if has_focus(input_line) && flags & .IMMEDIATE
        return text_edit.as_string, input_line;
    else
        return input_line.text, input_line;
}

update_input_line :: (using input_line: *Input_Line) {
    update_widget(input_line);

    if is_hot(input_line) {
        if was_clicked(input_line) && !has_focus(input_line) {
            focus(input_line);
            set_text_edit(input_line, text);
        }
    }
    else if has_focus(input_line) {
        if text_edit.currently_editting == input_line {
            focus_change := text_edit_handle_keyboard_input(flags & .READ_ONLY != 0);
            if focus_change  remove_focus(input_line, focus_change);
        }
    }
}


lost_focus ::  (using input_line: *Input_Line, reason: Focus_Change) {
    if reason == .CONFIRMED || (reason == .UNDETERMINED && flags & .IMMEDIATE) {
        free(text);
        text = copy_string(text_edit.as_string);
        set_changed(input_line);
    }
}



