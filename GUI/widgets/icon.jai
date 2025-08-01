Icon :: struct {
    #as using widget: Widget;

    icon_id: Icon_Id;
    icon_size := 0;
}


icon :: (location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Icon #expand #no_debug {
    clicked, widget := _icon(0, location, flags, icon_id, size, tooltip, #insert #run next(*icon_count));
    return clicked, widget;
}


icon :: (id: int, $reserve: int, location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Icon #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of icons being created)");
    clicked, widget := _icon(id, location, flags, icon_id, size, tooltip, #insert #run next(*icon_count, reserve));
    return clicked, widget;
}

icon :: (icon: *Icon, location: *At_Location, icon_id: Icon_Id, size := 0, flags := Flags.NONE, tooltip := "") -> clicked: bool, *Icon #expand #no_debug {
    clicked, widget := _icon(icon, location, flags, icon_id, size, tooltip);
    return clicked, widget;
}


get_index :: (icon: *Icon) -> int {
    index := icon - icon_data.data;
    assert(0 <= index && index < icon_data.count, "Called get_index with a user-allocated icon");
    return index;
}


#scope_module


icon_data : [] Icon;
#no_reset icon_count := 0;


_icon :: inline (id: int, location: *At_Location, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string, $gui_index: int) -> clicked: bool, *Icon {
    clicked, icon:= _icon(*icon_data[gui_index + id], location, flags, icon_id, size, tooltip);
    return clicked, icon;
}

_icon :: (icon: *Icon, location: *At_Location, flags: Flags, icon_id: Icon_Id, size: int, tooltip: string) -> clicked: bool, *Icon {
    icon.* = .{ widget(.ICON, location, tooltip, flags | .LOCKED | .OVERFLOW), icon_id, size };
    last_widget_location = location.*;

    update_widget(icon);
    draw_icon(icon);

    return was_clicked(icon), icon;
}
