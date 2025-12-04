Button :: struct {
    #as using widget: Widget;
    type = .BUTTON;

    text: string;
    icon_id: Icon_Id;
}


button :: (panel: *Panel, text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, panel, flags, text, Icon_Id.NONE, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, panel: *Panel, text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, panel, flags, text, Icon_Id.NONE, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, panel: *Panel, text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, panel, flags, text, Icon_Id.NONE, tooltip);
    return clicked, widget;
}


button :: (panel: *Panel, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, panel, flags, "", icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, panel: *Panel, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, panel, flags, "", icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, panel: *Panel, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, panel, flags, "", icon_id, tooltip);
    return clicked, widget;
}


button :: (panel: *Panel, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, panel, flags, text, icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, panel: *Panel, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, panel, flags, text, icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, panel: *Panel, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, panel, flags, text, icon_id, tooltip);
    return clicked, widget;
}


#scope_module


button_data: Stable_Table(u64, Button);


_button :: inline (id: int, panel: *Panel, flags: Flags, text: string, icon_id: Icon_Id, tooltip: string, callsite_key: u64) -> clicked: bool, *Button {
    key := widget_key(id, currently_drawing_window, callsite_key);
    button := find_or_add(*button_data, key);
    clicked := _button(button, panel, flags, text, icon_id, tooltip);
    return clicked, button;
}

_button :: (button: *Button, panel: *Panel, flags: Flags, text: string, icon_id: Icon_Id, tooltip: string) -> clicked: bool, *Button {
    button.* = .{ .{panel, .BUTTON, tooltip, flags}, text, icon_id };
    last_widget_panel = panel.*;

    update_widget(button);
    draw_button(button);

    return was_clicked(button), button;
}
