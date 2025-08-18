Label :: struct {
    #as using widget: Widget;

    text: string;
}


label :: (panel: *Panel, text: $T, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Label {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(0, panel, flags, _text, tooltip, callsite_key(callsite));
    return clicked, widget;
}


label :: (id: int, $reserve: int, panel: *Panel, text: $T, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Label {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(id, panel, flags, _text, tooltip, callsite);
    return clicked, widget;
}

label :: (label: *Label, panel: *Panel, text: $T, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Label {
    #if T == string {
        _text := text;
    }
    else {
        _text := tprint("%", text);
    }
    clicked, widget := _label(label, panel, flags, _text, tooltip);
    return clicked, widget;
}


#scope_module


label_data : Table(u64, Label);


_label :: inline (id: int, panel: *Panel, flags: Flags, text: string, tooltip: string, callsite_key: u64) -> clicked: bool, *Label {
    key := widget_key(id, currently_drawing_window, callsite_key);
    label := find_or_add(*label_data, key);
    clicked := _label(label, panel, flags, text, tooltip);
    return clicked, label;
}

_label :: (label: *Label, panel: *Panel, flags: Flags, text: string, tooltip: string) -> clicked: bool, *Label {
    label.* = .{ .{panel, .LABEL, tooltip, flags | .LOCKED | .OVERFLOW}, text };
    last_widget_panel = panel.*;

    update_widget(label);
    draw_label(label);

    return was_clicked(label), label;
}
