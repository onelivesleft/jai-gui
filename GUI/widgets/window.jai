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

    _vertical_scrollbar := Scrollbar.{orientation=.VERTICAL};
    _horizontal_scrollbar := Scrollbar.{orientation=.HORIZONTAL};

    text: string;
    icon_id: Icon_Id;
}

DEFAULT_WINDOW_FLAGS :: Flags.CAN_MOVE | .CAN_RESIZE | .USE_SCROLLWHEEL | .CLOSE | .RESIZE | .MOVE | .TITLE_BAR | .LEFT;

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

window :: (draw_proc: Window_Draw_Proc, text: string, initial_panel: *Panel, flags := DEFAULT_WINDOW_FLAGS, tooltip := "", initially_closed := false, $callsite := #caller_location) -> *Window{
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

    if  drawn_bounds.h > 0 && window.calculated_rect.h < drawn_bounds.h {
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
    border_size :: 10;
    r := *window.calculated_rect;
    if !contains(r, mouse.x, mouse.y)  return .NONE;

    drag_flags: Drag_Flags;
    if mouse.y - r.y <= border_size        drag_flags |= .RESIZE_N;
    if r.y + r.h - mouse.y <= border_size  drag_flags |= .RESIZE_S;
    if mouse.x - r.x <= border_size        drag_flags |= .RESIZE_W;
    if r.x + r.w - mouse.x <= border_size  drag_flags |= .RESIZE_E;
    if !drag_flags  return ifx window.flags & .CAN_MOVE then .MOVE;
    return ifx window.flags & .CAN_RESIZE then drag_flags;
}

drag_flags_mask : u64 : (1 << 26) | (1 << 27) | (1 << 28) | (1 << 29);

drag_flags_from_flags :: (flags: Flags) -> Drag_Flags {
    drag_flags : Drag_Flags = xx ((drag_flags_mask & xx flags) >> 26);
    return drag_flags;
}

// Pointer_Image copied from GetRect

Pointer_Image :: enum u16 {
    NORMAL    :: 0;  // Normal arrow for pointing at stuff, or whatever.
    PRESSABLE :: 1;
    LOCKED    :: 2;  // No action can currently be performed.

    DRAGGING_HORIZONTAL   :: 3;
    DRAGGING_VERTICAL     :: 4;
    DRAGGING_FREE         :: 5;

    DRAGGING_NW_SE        :: 6;
    DRAGGING_NE_SW        :: 7;
}

#if OS == .WINDOWS {
    Windows :: #import "Windows";

    set_pointer_image :: (image: Pointer_Image) {
        if !initted_pointers  init_pointers();

        if (image >= 0) && (image <= cast(Pointer_Image) NUM_POINTERS) {
            Windows.SetCursor(pointers[image]);
            pointer_image_was_set_this_frame = true;
            already_reset_pointer_image = (image == .NORMAL);  // No need to reset the image if it was set to NORMAL.
        } else {
            log_error("Invalid pointer index %\n", image);
        }
    }

    init_pointers :: () {
        initted_pointers = true;

        using Pointer_Image;

        w :: Windows;

        pointers[NORMAL]                = w.LoadCursorW(null, w.IDC_ARROW);
        pointers[PRESSABLE]             = w.LoadCursorW(null, w.IDC_HAND);
        pointers[LOCKED]                = w.LoadCursorW(null, w.IDC_NO);
        pointers[DRAGGING_HORIZONTAL]   = w.LoadCursorW(null, w.IDC_SIZEWE);
        pointers[DRAGGING_VERTICAL]     = w.LoadCursorW(null, w.IDC_SIZENS);
        pointers[DRAGGING_FREE]         = w.LoadCursorW(null, w.IDC_SIZEALL);
        pointers[DRAGGING_NW_SE]        = w.LoadCursorW(null, w.IDC_SIZENWSE);
        pointers[DRAGGING_NE_SW]        = w.LoadCursorW(null, w.IDC_SIZENESW);
    }

    pointers: [NUM_POINTERS] Windows.HCURSOR;
} else #if OS == .MACOS {
    #import "Objective_C/AppKit";
    set_pointer_image :: (image: Pointer_Image) {
        if !initted_pointers  init_pointers();

        if (image >= 0) && (image <= cast(Pointer_Image) NUM_POINTERS) {
            NSCursor.set(pointers[image]);
            pointer_image_was_set_this_frame = true;
            already_reset_pointer_image = (image == .NORMAL);  // No need to reset the image if it was set to NORMAL.
        } else {
            log_error("Invalid pointer index %\n", image);
        }
    }

    init_pointers :: () {
        initted_pointers = true;

        using Pointer_Image;
        pointers[NORMAL]                = NSCursor.arrowCursor();
        pointers[PRESSABLE]             = NSCursor.pointingHandCursor();
        pointers[LOCKED]                = NSCursor.operationNotAllowedCursor();
        pointers[DRAGGING_HORIZONTAL]   = NSCursor.resizeLeftRightCursor();
        pointers[DRAGGING_VERTICAL]     = NSCursor.resizeUpDownCursor();
        pointers[DRAGGING_FREE]         = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
        pointers[DRAGGING_NW_SE]        = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
        pointers[DRAGGING_NE_SW]        = NSCursor.openHandCursor(); // @Hack: There are no publicly available cursors for this.
    }

    pointers: [NUM_POINTERS] *NSCursor;
} else {
    set_pointer_image :: (image: Pointer_Image) {
        if !initted_pointers  init_pointers();

        // @Incomplete: Implement this.
    }

    init_pointers :: () {
        initted_pointers = true;

        using Pointer_Image;
        // @Incomplete: Implement this.
    }
}

NUM_POINTERS :: #run enum_highest_value(Pointer_Image)+1;

set_pointer_image :: (drag_flags: Drag_Flags) {
    if drag_flags == .NONE  return;

    if drag_flags == .MOVE {
        set_pointer_image(.DRAGGING_FREE);
        return;
    }

    if drag_flags ==.RESIZE_NW || drag_flags == .RESIZE_SE {
        set_pointer_image(.DRAGGING_NW_SE);
        return;
    }

    if drag_flags ==.RESIZE_NE || drag_flags == .RESIZE_SW {
        set_pointer_image(.DRAGGING_NE_SW);
        return;
    }

    if drag_flags & (.RESIZE_E | .RESIZE_W) {
        set_pointer_image(.DRAGGING_HORIZONTAL);
        return;
    }

    if drag_flags & (.RESIZE_N | .RESIZE_S) {
        set_pointer_image(.DRAGGING_VERTICAL);
        return;
    }
}

pointer_end_frame :: () {
    if !pointer_image_was_set_this_frame {
        if !already_reset_pointer_image {
            set_pointer_image(.NORMAL); // This itself sets pointer_image* and already_reset*, so don't assume anything!
            already_reset_pointer_image = true;
        }
    }

    // Pointer-handling contribution by Rafał "Veeq7" Jurkiewicz.
    // We change custom cursor handling each frame, depending on whether we set the cursor or not.
    // The reason is, if we did set the cursor, we don't want Windows to set it back, which it seems
    // to do, every frame. But if we didn't want to set the cursor, we do want to pay attention
    // to Windows cursor changes, for example, as the user mouses over the window's resize frame.
    pointer_image_was_set_this_frame = false;
}

initted_pointers                 := false;
pointer_image_was_set_this_frame := false;
already_reset_pointer_image      := false;
