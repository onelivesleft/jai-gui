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


select_all :: (input_line: *Input_Line) {
    if text_edit.currently_editting == input_line
        set_text_edit_selection(0, text_edit.bytes.count);
}

copy_selection :: (input_line: *Input_Line) {
    if text_edit.currently_editting != input_line
        return;

    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection
        os_clipboard_set_text(string.{end - start, *bytes[start]});
}

cut_selection :: (input_line: *Input_Line) {
    if text_edit.currently_editting != input_line
        return;

    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        os_clipboard_set_text(string.{end - start, *bytes[start]});
        remove_text_edit(start, end);
    }
}

paste :: (input_line: *Input_Line) {
    if text_edit.currently_editting != input_line
        return;

    insert_text_edit(os_clipboard_get_text());
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
    draw_input_line(input_line);

    if has_focus(input_line) && flags & .IMMEDIATE
        return text_edit.as_string, input_line;
    else
        return input_line.text, input_line;
}

update_input_line :: (using input_line: *Input_Line) {
    was_hot := is_hot(input_line);
    update_widget(input_line);

    if has_focus(input_line) {
        if keyboard.any_typing_this_frame()
            insert_text_edit(keyboard.eat_typed_this_frame());

        if was_clicked(keyboard.escape)     remove_focus(input_line, .CANCELLED);
        if was_clicked(keyboard.enter)      remove_focus(input_line, .CONFIRMED);
        if was_clicked(keyboard.tab)        remove_focus(input_line, .UNDETERMINED);
        if was_clicked(keyboard.left)       move_cursor(-1, xx keyboard.shift);
        if was_clicked(keyboard.right)      move_cursor(+1, xx keyboard.shift);
        if was_clicked(keyboard.backspace)  backspace();
        if was_clicked(keyboard.delete)     delete();
        if was_clicked(keyboard.home)       set_text_edit_cursor(0, xx keyboard.shift);
        if was_clicked(keyboard.end)        set_text_edit_cursor(text_edit.bytes.count, xx keyboard.shift);

        if keyboard.control {
            if was_clicked(keyboard.a)  select_all(input_line);
            if was_clicked(keyboard.c)  copy_selection(input_line);
            if was_clicked(keyboard.x)  cut_selection(input_line);
            if was_clicked(keyboard.v)  paste(input_line);
        }
    }

    if is_hot(input_line) && !was_hot {
        focus(input_line);
        set_text_edit(input_line, text);
    }
}


lost_focus ::  (using input_line: *Input_Line, reason: Lost_Focus_Reason) {
    if reason == .CONFIRMED || (reason == .UNDETERMINED && flags & .IMMEDIATE) {
        free(text);
        text = copy_string(text_edit.as_string);
        set_changed(input_line);
    }
}



text_edit : struct {
    currently_editting: *Widget;
    bytes: [] u8;
    allocated_count: int;
    cursor: int;
    select_anchor: int;
    cursor_x: float;
    before_cursor: string;
    after_cursor: string;
    lines: [] string;

    #place bytes;
    as_string : string = ---;
}

allocate_text_edit :: (size: int) {
    using text_edit;
    if size <= allocated_count  return;

    new_bytes := NewArray(size + 1024, u8);  // allocate extra space so we likely don't have to reallocate again soon
    bytes_count := bytes.count;
    if allocated_count {
        if bytes.count
            memcpy(new_bytes.data, bytes.data, bytes.count);
        free(bytes.data);
    }
    bytes = new_bytes;
    allocated_count = bytes.count;
    bytes.count = bytes_count;
}

update_text_edit :: () {
    using text_edit;
    before_cursor.data = bytes.data;
    before_cursor.count = cursor;
    after_cursor.data = bytes.data + cursor;
    after_cursor.count = bytes.count - cursor;
}

set_text_edit :: (widget: *Widget, s: string, cursor_position := 0x7fffffff) {
    using text_edit;
    currently_editting = widget;
    bytes.count = 0; // we don't need to preserve the buffer as we're setting it from scratch.
    allocate_text_edit(s.count);
    if s  memcpy(bytes.data, s.data, s.count);
    bytes.count = s.count;
    set_text_edit_cursor(cursor_position, false);
}

insert_text_edit :: (s: string) {
    if !s  return;
    using text_edit;

    has_selection, start, end := text_edit_selection();
    if has_selection
        remove_text_edit(start, end);

    allocate_text_edit(bytes.count + s.count);
    if cursor < bytes.count
        memcpy(bytes.data + cursor + s.count, bytes.data + cursor, bytes.count - cursor);
    memcpy(bytes.data + cursor, s.data, s.count);
    bytes.count += s.count;
    if select_anchor >= cursor  select_anchor += s.count;
    cursor += s.count;
    if currently_editting.flags & .IMMEDIATE
        set_changed(currently_editting);
    update_text_edit();
}

remove_text_edit :: (from: int, to: int) {
    if from >= to  return;
    using text_edit;

    if to < bytes.count
        memcpy(bytes.data + from, bytes.data + to, bytes.count - to);
    bytes.count -= (to - from);
    if cursor > from {
        if cursor <= to  cursor = from;
        else             cursor -= (to - from);
    }
    if select_anchor > from {
        if select_anchor <= to  select_anchor = from;
        else                    select_anchor -= (to - from);
    }
    if currently_editting.flags & .IMMEDIATE
        set_changed(currently_editting);
    update_text_edit();
}

set_text_edit_cursor :: (cursor_position: int, selecting: bool) {
    using text_edit;
    cursor = clamp(cursor_position, 0, bytes.count);
    if !selecting  select_anchor = cursor;
    update_text_edit();
}

set_text_edit_selection :: (select_anchor_position: int, cursor_position: int) {
    using text_edit;
    cursor = clamp(cursor_position, 0, bytes.count);
    select_anchor = clamp(select_anchor_position, 0, bytes.count);
    update_text_edit();
}

character_utf32_to_utf8 :: (ch: u32, preallocated_string: *string) {  // preallocated_string must have at least 4 characters of allocated memory.
    UNI_MAX_LEGAL_UTF32  :: 0x0010FFFF;
    UNI_REPLACEMENT_CHAR :: 0x0000FFFD;
    firstByteMark : [7] u8 : .[ 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC ];

    count := 0;
    if ch < 0x80                        count = 1;
    else if ch < 0x800                  count = 2;
    else if ch < 0x10000                count = 3;
    else if ch <= UNI_MAX_LEGAL_UTF32   count = 4;
    else {
        count = 3;
        ch = UNI_REPLACEMENT_CHAR;
    }

    byteMask :: 0xBF;
    byteMark :: 0x80;

    preallocated_string.count = count;
    s := preallocated_string;

    if count == {
        case 4; s.data[3] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 3; s.data[2] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 2; s.data[1] = xx (ch | byteMark) & byteMask; ch = ch >> 6; #through;
        case 1; s.data[0] = xx (ch | firstByteMark[count]);
    }
}

text_edit_selection :: () -> has_selection: bool, start: int, end: int {
    using text_edit;
    if select_anchor > cursor
        return cursor != select_anchor, cursor, select_anchor;
    else
        return cursor != select_anchor, select_anchor, cursor;
}


#scope_file


move_cursor :: (count: int, selecting: bool) {
    using text_edit;
    if count < 0 {
        for outer: 1 .. -count {
            while true {
                if cursor == 0  break outer;
                cursor -= 1;
                if 192 & bytes[cursor] != 128  break outer;
            }
        }
    }
    else if cursor < bytes.count {
        for outer: 1 .. count {
            cursor += 1 + trailing_utf8_bytes[bytes[cursor]];
            if cursor >= bytes.count {
                cursor = bytes.count;
                break outer;
            }
        }
    }
    if !selecting  select_anchor = cursor;
    update_text_edit();
}

backspace :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        remove_text_edit(start, end);
    }
    else {
        if cursor == 0  return;
        start_cursor := cursor;
        move_cursor(-1, false);
        remove_text_edit(cursor, start_cursor);
    }
}

delete :: () {
    using text_edit;
    has_selection, start, end := text_edit_selection();
    if has_selection {
        remove_text_edit(start, end);
    }
    else {
        if cursor >= bytes.count  return;
        start_cursor := cursor;
        move_cursor(+1, false);
        remove_text_edit(start_cursor, cursor);
    }
}
