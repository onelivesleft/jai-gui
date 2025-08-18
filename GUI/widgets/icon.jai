Icon :: struct {
    #as using widget: Widget;

    icon_id: Icon_Id;
    icon_size := 0;
}


icon :: (panel: *Panel, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Icon {
    clicked, widget := _icon(0, panel, flags, icon_id, size, tooltip, callsite_key(callsite));
    return clicked, widget;
}


icon :: (id: int, panel: *Panel, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> clicked: bool, *Icon {
    clicked, widget := _icon(id, panel, flags, icon_id, size, tooltip, callsite_key(callsite));
    return clicked, widget;
}

icon :: (icon: *Icon, panel: *Panel, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Icon {
    clicked, widget := _icon(icon, panel, flags, icon_id, size, tooltip);
    return clicked, widget;
}


#scope_module


icon_data : Table(u64, Icon);


_icon :: inline (id: int, panel: *Panel, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string, callsite_key: u64) -> clicked: bool, *Icon {
    key := widget_key(id, currently_drawing_window, callsite_key);
    icon := find_or_add(*icon_data, key);
    clicked := _icon(icon, panel, flags, icon_id, size, tooltip);
    return clicked, icon;
}

_icon :: (icon: *Icon, panel: *Panel, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string) -> clicked: bool, *Icon {
    icon.* = .{ .{panel, .ICON, tooltip, flags | .LOCKED | .OVERFLOW}, icon_id, size };
    last_widget_panel = panel.*;

    update_widget(icon);
    draw_icon(icon);

    return was_clicked(icon), icon;
}
