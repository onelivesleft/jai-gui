Scrollable_Panel :: struct {
    #as using widget: Widget;

    width, height: int;
    available_area: Panel;

    _vertical_scrollbar: Scrollbar;
    _horizontal_scrollbar: Scrollbar;
    has_vertical_scrollbar: bool;
    has_horizontal_scrollbar: bool;
}


push_scrollable_panel :: (panel: *Panel, width: int, height: int, flags := Flags.NONE, $callsite := #caller_location) -> available_area: *Panel, *Scrollable_Panel {
    scrollable_panel := _scrollable_panel(0, panel, flags, width, height, callsite_key(callsite));
    assert(scrollable_panel.available_area.calculated_rect_frame_index == frame.index);
    return *scrollable_panel.available_area, scrollable_panel;
}

push_scrollable_panel :: (id: int, panel: *Panel, width: int, height: int, flags := Flags.NONE, $callsite := #caller_location) -> available_area: *Panel, *Scrollable_Panel {
    scrollable_panel := _scrollable_panel(id, panel, flags, width, height, callsite_key(callsite));
    assert(scrollable_panel.available_area.calculated_rect_frame_index == frame.index);
    return *scrollable_panel.available_area, scrollable_panel;
}

push_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, panel: *Panel, width: int, height: int, flags := Flags.NONE) -> available_area: *Panel, *Scrollable_Panel {
    _scrollable_panel(scrollable_panel, panel, flags, width, height);
    assert(scrollable_panel.available_area.calculated_rect_frame_index == frame.index);
    return *scrollable_panel.available_area, scrollable_panel;
}

pop_scrollable_panel :: () {
    maybe_pop_scissor();
    pop_panel();
}

with_scrollable_panel :: (panel: *Panel, width: int, height: int, flags := Flags.NONE, $callsite := #caller_location) -> available_area: *Panel, *Scrollable_Panel #expand {
    widget := _scrollable_panel(0, panel, flags, width, height, callsite_key(callsite));
    assert(widget.available_area.calculated_rect_frame_index == frame.index);
    `defer pop_scrollable_panel();
    return *widget.available_area, widget;
}

with_scrollable_panel :: (id: int, panel: *Panel, width: int, height: int, flags := Flags.NONE, $callsite := #caller_location) -> available_area: *Panel, *Scrollable_Panel #expand {
    widget := _scrollable_panel(id, panel, flags, width, height, callsite_key(callsite));
    `defer pop_scrollable_panel();
    assert(widget.available_area.calculated_rect_frame_index == frame.index);
    return *widget.available_area, widget;
}

with_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, panel: *Panel, width: int, height: int, flags := Flags.NONE) -> available_area: *Panel, *Scrollable_Panel #expand {
    _scrollable_panel(scrollable_panel, panel, flags, width, height);
    assert(scrollable_panel.available_area.calculated_rect_frame_index == frame.index);
    `defer pop_scrollable_panel();
    return *scrollable_panel.available_area, scrollable_panel;
}


move_by_steps :: (using scrollable_panel: *Scrollable_Panel, steps: int) {
    if has_vertical_scrollbar
        move_by_steps(*_vertical_scrollbar, steps);
    else if has_horizontal_scrollbar
        move_by_steps(*_horizontal_scrollbar, steps);
}

use_scrollwheel :: (using scrollable_panel: *Scrollable_Panel) {
    if has_vertical_scrollbar == has_horizontal_scrollbar
        return;

    if has_vertical_scrollbar  use_scrollwheel(*_vertical_scrollbar);
    else                       use_scrollwheel(*_horizontal_scrollbar);
}


#scope_module


scrollable_panel_data : Table(u64, Scrollable_Panel);


_scrollable_panel :: inline (id: int, panel: *Panel, flags: Flags, width: int, height: int, callsite_key: u64) -> *Scrollable_Panel {
    key := widget_key(id, currently_drawing_window, callsite_key);
    scrollable_panel := find_or_add(*scrollable_panel_data, key);
    return _scrollable_panel(scrollable_panel, panel, flags, width, height);
}

_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, panel: *Panel, flags: Flags, width: int, height: int) -> *Scrollable_Panel {
    scrollable_panel.widget = .{panel, .SCROLLABLE_PANEL, "", flags | .USE_SCROLLWHEEL};
    scrollable_panel.width = width;
    scrollable_panel.height = height;

    update_scrollable_panel(scrollable_panel);
    draw_scrollable_panel(scrollable_panel);

    last_widget_panel = panel.*;

    return scrollable_panel;
}

update_scrollable_panel :: (using scrollable_panel: *Scrollable_Panel) {
    update_widget(scrollable_panel);

    main_panel, bottom_scrollbar_panel, right_scrollbar_panel: *Panel;
    w := cast(float) width;
    h := cast(float) height;

    has_vertical_scrollbar = scrollable_panel.calculated_rect.h < h;
    if has_vertical_scrollbar {
        has_horizontal_scrollbar = scrollable_panel.calculated_rect.w < w - theme.scrollbar_size;
    }
    else {
        has_horizontal_scrollbar = scrollable_panel.calculated_rect.w < w;
        has_vertical_scrollbar = scrollable_panel.calculated_rect.h < h - theme.scrollbar_size;
    }

    if !has_vertical_scrollbar && flags & .FIT {
        h = scrollable_panel.calculated_rect.h - ifx has_horizontal_scrollbar then theme.scrollbar_size;
        height = cast(int) h;
    }
    if !has_horizontal_scrollbar && flags & .FIT {
        w = scrollable_panel.calculated_rect.w - ifx has_vertical_scrollbar then theme.scrollbar_size;
        width = cast(int) w;
    }

    if has_vertical_scrollbar {
        if has_horizontal_scrollbar
            main_panel, bottom_scrollbar_panel, right_scrollbar_panel = split_for_bottom_and_right_scrollbars(scrollable_panel);
        else
            main_panel, right_scrollbar_panel = split_for_right_scrollbar(scrollable_panel);
    }
    else if has_horizontal_scrollbar {
        main_panel, bottom_scrollbar_panel = split_for_bottom_scrollbar(scrollable_panel);
    }
    else {
        main_panel = scrollable_panel;
    }

    calculate_rect(main_panel);
    vertical_position, horizontal_position: Ord;

    if has_vertical_scrollbar {
        handle_size := main_panel.calculated_rect.h / h;
        t := vertical_scrollbar(*_vertical_scrollbar, right_scrollbar_panel, handle_size=handle_size, flags);
        vertical_position.rel = t;
        vertical_position.abs = -lerp(0, height, t);
    }

    if has_horizontal_scrollbar {
        handle_size := main_panel.calculated_rect.w / w;
        t := horizontal_scrollbar(*_horizontal_scrollbar, bottom_scrollbar_panel, handle_size=handle_size, flags);
        horizontal_position.rel = t;
        horizontal_position.abs = -lerp(0, width, t);
    }

    available_area.parent = main_panel;
    available_area.desired_box = box(horizontal_position,vertical_position, horizontal_position+width, vertical_position+height);
    calculate_rect(*available_area); // finalize panel for this frame, as its parent main_panel is about to disappear off the stack
    push_scissor(main_panel.calculated_rect, flags);
    push_panel(*available_area);
}
