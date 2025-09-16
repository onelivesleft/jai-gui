Window :: struct {
    #as using widget: Widget;
    type = .WINDOW;

    // The window's panel is the undecorated client area on the screen.  Decorations can be drawn
    // outwith this area (and indeed usually are).  For example, the title bar will typically be drawn
    // above the window's panel.  This gives the client an easy time, since they interact directly
    // with the area they care about.
    virtual_panel: *Panel;  // The region the client can draw to, handled by the windows scrollbars.

    is_open := true;
    key: u64;
    draw_proc: Window_Draw_Proc;
    drawn_bounds: Rect;
    border_rect: Rect;

    _vertical_scrollbar := Scrollbar.{orientation=.VERTICAL};
    _horizontal_scrollbar := Scrollbar.{orientation=.HORIZONTAL};

    text: string;
    icon_id: Icon_Id;
}

DEFAULT_WINDOW_FLAGS :: Flags.CAN_MOVE|.CAN_RESIZE|.USE_SCROLLWHEEL|.CLOSE|.RESIZE|.MOVE|.TITLE_BAR|.LEFT;

Window_Draw_Proc :: #type (window: *Window);

focussed_window: *Window;
clicked_window: *Window;
warm_window: *Window;
currently_drawing_window: *Window;
currently_dragging_window: *Window;

current_window_drag := Drag_Flags.NONE;
drag_start_mouse_position: Vector2;
drag_start_window_box: Box;

Drag_Flags :: enum_flags {
    NONE :: 0;

    RESIZE_N :: 1;
    RESIZE_E :: 2;
    RESIZE_S :: 4;
    RESIZE_W :: 8;

    RESIZE_NW :: RESIZE_N|RESIZE_W;
    RESIZE_NE :: RESIZE_N|RESIZE_E;
    RESIZE_SW :: RESIZE_S|RESIZE_W;
    RESIZE_SE :: RESIZE_S|RESIZE_E;

    MOVE :: 15;
}

window :: (draw_proc: Window_Draw_Proc, text: string, initial_panel: *Panel, flags := DEFAULT_WINDOW_FLAGS, tooltip := "", initially_closed := false, $callsite := #caller_location) -> *Window {
    return _window(0, draw_proc, initial_panel, flags, text, Icon_Id.NONE, tooltip, initially_closed, callsite_key(callsite));
}

window :: (id: int, draw_proc: Window_Draw_Proc, text: string, initial_panel: *Panel, flags := DEFAULT_WINDOW_FLAGS, tooltip := "", initially_closed := false, $callsite := #caller_location) -> *Window {
    return _window(id, draw_proc, initial_panel, flags, text, Icon_Id.NONE, tooltip, initially_closed, callsite_key(callsite));
}


bring_to_front :: (window: *Window) {
    i := window_order.count;
    for 0 .. window_order.count - 2 {
        if window_order[it] == window.key {
            i = it;
            break;
        }
    }
    for i .. window_order.count - 2 {
        window_order[it] = window_order[it + 1];
    }
    window_order[window_order.count - 1] = window.key;
}

open_window :: (window: *Window) {
    window.is_open = true;
}

close_window :: (window: *Window) {
    window.is_open = false;
}

use_scrollwheel :: (using window: *Window) {
//    if mouse.scrollwheel {
//        steps := ifx (flags & .REVERSE_SCROLLWHEEL) then mouse.scrollwheel else -mouse.scrollwheel;
//        scrollbar_to_use : enum { HORIZONTAL; VERTICAL; } = .VERTICAL;
//        if window.flags & .SCROLLBAR_VERTICAL && window._vertical_scrollbar.handle_size < 1.0
//        move_by_steps(scrollbar, steps);
//        deplete_scrollwheel();
//    }
}


#scope_module


window_data: Table(u64, Window);
window_order: [..] u64;


_window :: (id: int, draw_proc: Window_Draw_Proc, initial_panel: *Panel, flags: Flags, text: string, icon_id: Icon_Id, tooltip: string, initially_closed: bool, callsite_key: u64) -> *Window {
    key := widget_key(id, null, callsite_key);
    window := find_or_add(*window_data, key);

    if !(window.flags & .HAS_BEEN_SHOWN) {
        window.flags |= .HAS_BEEN_SHOWN;
        window.key = key;

        array_add(*window_order, key);
        window.panel = initial_panel.*;

        if initially_closed  window.is_open = false;
    }

    window.draw_proc = draw_proc;
    window.tooltip = tooltip;
    window.flags = flags;
    window.text = text;
    window.icon_id = icon_id;

    window.flags |= .SHOW;

    return window;
}

update_window :: (window: *Window) {
    if is_hot(window) {
        if was_clicked(window) {
            drag_flags := get_mouse_pointer_window_drag(window);
            if drag_flags  start_window_drag(window, drag_flags);
        }
    } else if is_warm(window) {
        drag_flags := get_mouse_pointer_window_drag(window);
        set_pointer_image(drag_flags);
    }
}

calculate_virtual_panel :: (using window: *Window) {
    virtual_panel = at(window);

    if !(flags & .SCROLLBARS) {
        calculate_rect(virtual_panel);
        return;
    }

    vertical_position, horizontal_position: Ord;
    width := cast(int) drawn_bounds.w;
    height := cast(int) drawn_bounds.h;

    if drawn_bounds.w > 0 && window.calculated_rect.w < drawn_bounds.w {
        _horizontal_scrollbar.handle_size = window.calculated_rect.w / drawn_bounds.w;
        horizontal_position.rel = _horizontal_scrollbar.float_value;
        horizontal_position.abs = -lerp(0, width, _horizontal_scrollbar.float_value);
    }
    else {
        _horizontal_scrollbar.handle_size = 1.0;
    }

    if drawn_bounds.h > 0 && window.calculated_rect.h < drawn_bounds.h {
        _vertical_scrollbar.handle_size = window.calculated_rect.h / drawn_bounds.h;
        vertical_position.rel = _vertical_scrollbar.float_value;
        vertical_position.abs = -lerp(0, height, _vertical_scrollbar.float_value);
    }
    else {
        _vertical_scrollbar.handle_size = 1.0;
    }

    virtual_panel.desired_box = box(horizontal_position,vertical_position, horizontal_position+width, vertical_position+height);
    calculate_rect(virtual_panel);
}


start_window_drag :: (window: *Window, drag_flags: Drag_Flags) {
    currently_dragging_window = window;
    current_window_drag = drag_flags;
    drag_start_mouse_position = mouse.position;
    drag_start_window_box = window.desired_box;
}

update_window_drag :: (window: *Window) {
    delta := mouse.position - drag_start_mouse_position;
    window.desired_box = drag_start_window_box;
    if current_window_drag == .MOVE {
        window.desired_box.tlx.abs += xx delta.x;
        window.desired_box.tly.abs += xx delta.y;
        window.desired_box.brx.abs += xx delta.x;
        window.desired_box.bry.abs += xx delta.y;
    } else {
        if current_window_drag & .RESIZE_N {
            window.desired_box.tly.abs += xx delta.y;
        }
        if current_window_drag & .RESIZE_E {
            window.desired_box.brx.abs += xx delta.x;
        }
        if current_window_drag & .RESIZE_S {
            window.desired_box.bry.abs += xx delta.y;
        }
        if current_window_drag & .RESIZE_W {
            window.desired_box.tlx.abs += xx delta.x;
        }
    }
    set_pointer_image(current_window_drag);
}

get_mouse_pointer_window_drag :: (window: *Window) -> Drag_Flags {
    r := *window.border_rect;
    if !contains(r, mouse.x, mouse.y)  return .NONE;

    theme := get_theme(window);
    border_size := cast(float) theme.window_draggable_border_size;

    drag_flags: Drag_Flags;
    if window.flags & .CAN_RESIZE {
        if mouse.y - r.y <= border_size        drag_flags |= .RESIZE_N;
        if r.y + r.h - mouse.y <= border_size  drag_flags |= .RESIZE_S;
        if mouse.x - r.x <= border_size        drag_flags |= .RESIZE_W;
        if r.x + r.w - mouse.x <= border_size  drag_flags |= .RESIZE_E;
        if drag_flags  return drag_flags;
    }

    if window.flags & .CAN_MOVE
        return .MOVE;

    return .NONE;
}

drag_flags_mask : u64 : (1 << 26) | (1 << 27) | (1 << 28) | (1 << 29);

drag_flags_from_flags :: (flags: Flags) -> Drag_Flags {
    drag_flags : Drag_Flags = xx ((drag_flags_mask & xx flags) >> 26);
    return drag_flags;
}
