Application_Window_Decoration :: struct {
    #as using widget: Widget;
    type = .APPLICATION_WINDOW_DECORATION;
}


application_window_decoration :: (panel: *Panel, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Application_Window_Decoration {
    widget := _application_window_decoration(0, panel, flags, tooltip, callsite_key(callsite));
    return widget;
}

application_window_decoration :: (id: int, panel: *Panel, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Application_Window_Decoration {
    widget := _application_window_decoration(id, panel, flags, tooltip, callsite_key(callsite));
    return widget;
}

application_window_decoration :: (application_window_decoration: *Application_Window_Decoration, panel: *Panel, flags := Flags.NONE, tooltip := "") -> *Application_Window_Decoration {
    widget := _application_window_decoration(application_window_decoration, panel, flags, tooltip);
    return widget;
}


#scope_module


application_window_decoration_data: Table(u64, Application_Window_Decoration);


_application_window_decoration :: inline (id: int, panel: *Panel, flags: Flags, tooltip: string, callsite_key: u64) -> *Application_Window_Decoration {
    key := widget_key(id, currently_drawing_window, callsite_key);
    application_window_decoration := find_or_add(*application_window_decoration_data, key);
    _application_window_decoration(application_window_decoration, panel, flags, tooltip);
    return application_window_decoration;
}

_application_window_decoration :: (application_window_decoration: *Application_Window_Decoration, panel: *Panel, flags: Flags, tooltip: string) -> *Application_Window_Decoration {
    application_window_decoration.* = .{ .{panel, .APPLICATION_WINDOW_DECORATION, tooltip, flags} };
    last_widget_panel = panel.*;

    update_application_window_decoration(application_window_decoration);
    draw_application_window_decoration(application_window_decoration);

    return application_window_decoration;
}


update_application_window_decoration :: (application_window_decoration: *Application_Window_Decoration) {
    update_widget(application_window_decoration);

    if !is_warm(application_window_decoration) && !is_hot(application_window_decoration)
        return;

    if application_window_decoration.flags & .CLOSE {
        application_window_decoration_override = .CLOSE;
        return;
    }

    if application_window_decoration.flags & .TITLE_BAR {
        application_window_decoration_override = .TITLE_BAR;
        return;
    }

    if application_window_decoration.flags & .MAXIMIZE {
        application_window_decoration_override = .MAXIMIZE;
        return;
    }

    if application_window_decoration.flags & .MINIMIZE {
        application_window_decoration_override = .MINIMIZE;
        return;
    }

    drag_flags := drag_flags_from_flags(application_window_decoration.flags);
    if drag_flags == {
        case .MOVE;      application_window_decoration_override = .TITLE_BAR;
        case .RESIZE_NW; application_window_decoration_override = .RESIZE_NW;
        case .RESIZE_NE; application_window_decoration_override = .RESIZE_NE;
        case .RESIZE_SW; application_window_decoration_override = .RESIZE_SW;
        case .RESIZE_SE; application_window_decoration_override = .RESIZE_SE;
        case .RESIZE_N;  application_window_decoration_override = .RESIZE_N;
        case .RESIZE_E;  application_window_decoration_override = .RESIZE_E;
        case .RESIZE_S;  application_window_decoration_override = .RESIZE_S;
        case .RESIZE_W;  application_window_decoration_override = .RESIZE_W;
    }
/*
    if application_window_decoration.flags & .CLOSE {
        if was_clicked(application_window_decoration) {
            close_window(currently_drawing_window);
        }
        return;
    }

    if application_window_decoration.flags & .TITLE_BAR {
        if is_warm(application_window_decoration)  set_pointer_image(.MOVE);
        if was_clicked(application_window_decoration)  start_window_drag(currently_drawing_window, .MOVE);
        return;
    }
*/
}
