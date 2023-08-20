Text_Input :: struct {
    #as using widget: Widget;

    initialized := false;

    text: string;
}


text_input :: (parent: *Panel, placement: Place, initial_text: string, flags := Flags.NONE, tooltip := "") -> text: string, *Text_Input #expand #no_debug {
    text, widget := _text_input(0, parent, placement, flags, initial_text, tooltip,  #insert #run next(*text_input_count));
    return text, widget;
}

text_input :: (id: int, $reserve: int, parent: *Panel, placement: Place, initial_text: string, flags := Flags.NONE, tooltip := "") -> text: string, *Text_Input #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of inputs being created)");
    text, widget := _text_input(id, parent, placement, flags, initial_text, tooltip, #insert #run next(*text_input_count, reserve));
    return text, widget;
}

text_input :: (text_input: *Text_Input, parent: *Panel, placement: Place, initial_text: string, flags := Flags.NONE, tooltip := "") -> text: string, *Text_Input #expand #no_debug {
    text, widget := _text_input(text_input, parent, placement, flags, initial_text, tooltip);
    return text, widget;
}


get_index :: (text_input: *Text_Input) -> int {
    index := text_input - text_input_data.data;
    assert(0 <= index && index < text_input_data.count);
    return index;
}

select_all :: (text_input: *Text_Input) {
    if text_edit.currently_editting == text_input
        set_text_edit_selection(0, text_edit.bytes.count);
}


#scope_module


text_input_data : [] Text_Input;
#no_reset text_input_count := 0;

_text_input :: inline (id: int, parent: *Panel, placement: Place, flags: Flags, initial_text: string, tooltip: string, $gui_index: int) -> text: string, *Text_Input {
    text, text_input := _text_input(*text_input_data[gui_index + id], parent, placement, flags, initial_text, tooltip);
    return text, text_input;
}

_text_input :: (text_input: *Text_Input, parent: *Panel, placement: Place, flags: Flags, initial_text: string, tooltip: string) -> text: string, *Text_Input {
    text := ifx text_input.initialized then text_input.text else copy_string(initial_text);
    text_input.* = .{ widget(parent, placement, tooltip, flags), true, text };
    last_widget_placement = placement;

    update_text_input(text_input);
    draw_text_input(text_input);

    if has_focus(text_input) && flags & .IMMEDIATE
        return text_edit.as_string, text_input;
    else
        return text_input.text, text_input;
}

update_text_input :: (using text_input: *Text_Input) {
    was_active := is_active(text_input);
    update_widget(text_input);

    if is_active(text_input) && !was_active {
        set_focus(text_input, true);
        set_text_edit(text_input, text);
    }
}


handle_event :: (using text_input: *Text_Input, event: Input.Event) {
    assert(focussed_widget == text_input);
    if event.type == {
        case .TEXT_INPUT;
        utf8_bytes : [4] u8;
        typed_string : string = ---;
        typed_string.data = utf8_bytes.data;
        character_utf32_to_utf8(event.utf32, *typed_string);
        insert_text_edit(typed_string);

        case .KEYBOARD;
        if event.key_pressed {
            if event.key_code == {
                case .ESCAPE;       set_focus(text_input, false, .CANCELLED);
                case .ENTER;        set_focus(text_input, false, .CONFIRMED);
                case .TAB;          set_focus(text_input, false, .SOFT);
                case .ARROW_LEFT;   move_cursor(-1, event.shift_pressed);
                case .ARROW_RIGHT;  move_cursor(+1, event.shift_pressed);
                case .BACKSPACE;    backspace();
                case .DELETE;       delete();
                case .HOME;         set_text_edit_cursor(0, event.shift_pressed);
                case .END;          set_text_edit_cursor(text_edit.bytes.count, event.shift_pressed);
                case #char "A";     if event.ctrl_pressed  select_all(text_input);
            }
        }

    }
}

lost_focus ::  (using text_input: *Text_Input, reason: Lost_Focus_Reason) {
    if reason == .CONFIRMED || (reason == .SOFT && flags & .IMMEDIATE) {
        free(text);
        text = copy_string(text_edit.as_string);
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

    allocate_text_edit(bytes.count + s.count);
    if cursor < bytes.count
        memcpy(bytes.data + cursor + s.count, bytes.data + cursor, bytes.count - cursor);
    memcpy(bytes.data + cursor, s.data, s.count);
    bytes.count += s.count;
    if select_anchor >= cursor  select_anchor += s.count;
    cursor += s.count;
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