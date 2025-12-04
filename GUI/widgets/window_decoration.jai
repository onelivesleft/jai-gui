Window_Decoration :: struct {
    #as using widget: Widget;
    type = .WINDOW_DECORATION;

    //text: string;
    //icon_id: Icon_Id;
}


window_decoration :: (panel: *Panel, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Window_Decoration {
    widget := _window_decoration(0, panel, flags, tooltip, callsite_key(callsite));
    return widget;
}

window_decoration :: (id: int, panel: *Panel, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Window_Decoration {
    widget := _window_decoration(id, panel, flags, tooltip, callsite_key(callsite));
    return widget;
}

window_decoration :: (window_decoration: *Window_Decoration, panel: *Panel, flags := Flags.NONE, tooltip := "") -> *Window_Decoration {
    widget := _window_decoration(window_decoration, panel, flags, tooltip);
    return widget;
}


#scope_module


window_decoration_data: Stable_Table(u64, Window_Decoration);


_window_decoration :: inline (id: int, panel: *Panel, flags: Flags, tooltip: string, callsite_key: u64) -> *Window_Decoration {
    key := widget_key(id, currently_drawing_window, callsite_key);
    window_decoration := find_or_add(*window_decoration_data, key);
    _window_decoration(window_decoration, panel, flags, tooltip);
    return window_decoration;
}

_window_decoration :: (window_decoration: *Window_Decoration, panel: *Panel, flags: Flags, tooltip: string) -> *Window_Decoration {
    window_decoration.* = .{ .{panel, .WINDOW_DECORATION, tooltip, flags} };
    last_widget_panel = panel.*;

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
        if currently_drawing_window.flags & .CAN_MOVE {
            if is_warm(window_decoration)  set_pointer_image(.MOVE);
            if was_clicked(window_decoration)  start_window_drag(currently_drawing_window, .MOVE);
        }
        return;
    }

    if window_decoration.flags & (.SCROLLBAR_HORIZONTAL | .SCROLLBAR_VERTICAL) {
        scrollbar := ifx window_decoration.flags & .SCROLLBAR_HORIZONTAL
             then *currently_drawing_window._horizontal_scrollbar
             else *currently_drawing_window._vertical_scrollbar;
        float_scrollbar(scrollbar, scrollbar.orientation, *window_decoration.panel, window_decoration.flags, window_decoration.tooltip, 0, .{}, scrollbar.handle_size);
        return;
    }

    if window_decoration.flags & .RESIZE {
        if currently_drawing_window.flags & .CAN_RESIZE {
            if is_warm(window_decoration)  set_pointer_image(.RESIZE_SE);
            if was_clicked(window_decoration)  start_window_drag(currently_drawing_window, .RESIZE_SE);
        }
        return;
    }

    if window_decoration.flags & .MOVE {
        if currently_drawing_window.flags & .CAN_MOVE {
            if is_warm(window_decoration)  set_pointer_image(.MOVE);
            if was_clicked(window_decoration)  start_window_drag(currently_drawing_window, .MOVE);
        }
        return;
    }
}
