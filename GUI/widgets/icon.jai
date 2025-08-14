Icon :: struct {
    #as using widget: Widget;

    icon_id: Icon_Id;
    icon_size := 0;
}


icon :: (location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Icon {
    clicked, widget := _icon(0, location, flags, icon_id, size, tooltip, callsite_key(callsite));
    return clicked, widget;
}


icon :: (id: int, location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Icon {
    clicked, widget := _icon(id, location, flags, icon_id, size, tooltip, callsite_key(callsite));
    return clicked, widget;
}

icon :: (icon: *Icon, location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Icon {
    clicked, widget := _icon(icon, location, flags, icon_id, size, tooltip);
    return clicked, widget;
}


#scope_module


icon_data : Table(u64, Icon);


_icon :: inline (id: int, location: *At_Location, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string, callsite_key: u64) -> clicked: bool, *Icon {
    key := widget_key(id, currently_drawing_window, callsite_key);
    icon := find_or_add(*icon_data, key);
    clicked := _icon(icon, location, flags, icon_id, size, tooltip);
    return clicked, icon;
}

_icon :: (icon: *Icon, location: *At_Location, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string) -> clicked: bool, *Icon {
    icon.* = .{ widget(.ICON, location, tooltip, flags | .LOCKED | .OVERFLOW), icon_id, size };
    last_widget_location = location.*;

    update_widget(icon);
    draw_icon(icon);

    return was_clicked(icon), icon;
}
