Window_Decoration :: struct {
    #as using widget: Widget;
    type = .WINDOW_DECORATION;

    //text: string;
    //icon_id: Icon_Id;
}


window_decoration :: (location: *At_Location, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Window_Decoration {
    widget := _window_decoration(0, location, flags, tooltip, callsite_key(callsite));
    return widget;
}

window_decoration :: (id: int, location: *At_Location, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Window_Decoration {
    widget := _window_decoration(id, location, flags, tooltip, callsite_key(callsite));
    return widget;
}

window_decoration :: (window_decoration: *Window_Decoration, location: *At_Location, flags := Flags.NONE, tooltip := "") -> *Window_Decoration {
    widget := _window_decoration(window_decoration, location, flags, tooltip);
    return widget;
}


#scope_module


window_decoration_data: Table(u64, Window_Decoration);


_window_decoration :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, callsite_key: u64) -> *Window_Decoration {
    key := widget_key(id, currently_drawing_window, callsite_key);
    window_decoration := find_or_add(*window_decoration_data, key);
    _window_decoration(window_decoration, location, flags, tooltip);
    return window_decoration;
}

_window_decoration :: (window_decoration: *Window_Decoration, location: *At_Location, flags: Flags, tooltip: string) -> *Window_Decoration {
    window_decoration.* = .{ widget(.WINDOW_DECORATION, location, tooltip, flags) };
    last_widget_location = location.*;

    update_window_decoration(window_decoration);
    draw_window_decoration(window_decoration);

    return window_decoration;
}


update_window_decoration :: (window_decoration: *Window_Decoration) {
    update_widget(window_decoration);

    if window_decoration.flags & .CLOSE {
        if was_clicked(window_decoration) {
            close_window(currently_drawing_window);
        }
        return;
    }

    if window_decoration.flags & .TITLE_BAR {
        if was_clicked(window_decoration) {
            current_window_drag = .MOVE;
            currently_dragging_window = currently_drawing_window;
            drag_start_mouse_position = mouse.position;
            drag_start_window_box = currently_drawing_window.desired_box;
        }
        return;
    }

    if window_decoration.flags & .SCROLLBAR_HORIZONTAL {
        return;
    }

    if window_decoration.flags & .SCROLLBAR_VERTICAL {
        return;
    }

    if window_decoration.flags & .RESIZE {
        return;
    }

    if window_decoration.flags & .MOVE {
        return;
    }
}
