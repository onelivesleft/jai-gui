Button :: struct {
    #as using widget: Widget;
    type = .BUTTON;

    text: string;
    icon_id: Icon_Id;
}


button :: (location: *At_Location, text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, location, flags, text, Icon_Id.NONE, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, location: *At_Location, text: string, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, location, flags, text, Icon_Id.NONE, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, location: *At_Location, text: string, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, location, flags, text, Icon_Id.NONE, tooltip);
    return clicked, widget;
}


button :: (location: *At_Location, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, location, flags, "", icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, location: *At_Location, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, location, flags, "", icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, location: *At_Location, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, location, flags, "", icon_id, tooltip);
    return clicked, widget;
}


button :: (location: *At_Location, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(0, location, flags, text, icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (id: int, location: *At_Location, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Button {
    clicked, widget := _button(id, location, flags, text, icon_id, tooltip, callsite_key(callsite));
    return clicked, widget;
}

button :: (button: *Button, location: *At_Location, text: string, icon_id: Icon_Id, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Button {
    clicked, widget := _button(button, location, flags, text, icon_id, tooltip);
    return clicked, widget;
}


#scope_module


button_data: Table(u64, Button);


_button :: inline (id: int, location: *At_Location, flags: Flags, text: string, icon_id: Icon_Id, tooltip: string, callsite_key: u64) -> clicked: bool, *Button {
    key := widget_key(id, currently_drawing_window, callsite_key);
    button := find_or_add(*button_data, key);
    clicked := _button(button, location, flags, text, icon_id, tooltip);
    return clicked, button;
}

_button :: (button: *Button, location: *At_Location, flags: Flags, text: string, icon_id: Icon_Id, tooltip: string) -> clicked: bool, *Button {
    button.* = .{ .{location, .BUTTON, tooltip, flags}, text, icon_id };
    last_widget_location = location.*;

    update_widget(button);
    draw_button(button);

    return was_clicked(button), button;
}
