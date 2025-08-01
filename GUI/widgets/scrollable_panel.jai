Scrollable_Panel :: struct {
    #as using widget: Widget;

    width, height: int;
    panel: *Panel;

    _vertical_scrollbar: Scrollbar;
    _horizontal_scrollbar: Scrollbar;
    has_vertical_scrollbar: bool;
    has_horizontal_scrollbar: bool;
}


push_scrollable_panel :: (location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(0, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count));
    assert(interior_panel.calculated_rect_frame_index == frame.index);
    return *interior_panel, widget;
}

push_scrollable_panel :: (id: int, $reserve: int, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of scrollable_panels being created)");
    interior_panel : Panel = ---;
    widget := _scrollable_panel(id, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count, reserve));
    assert(interior_panel.rect_frame_count == frame.count);
    return *interior_panel, widget;
}

push_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: bool, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(scrollable_panel, location, flags, width, height, *interior_panel);
    assert(interior_panel.rect_frame_count == frame.count);
    return *interior_panel, widget;
}

pop_scrollable_panel :: () {
    maybe_pop_scissor();
    pop_panel();
}

with_scrollable_panel :: (location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(0, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count));
    assert(interior_panel.rect_frame_count == frame.count);
    `defer pop_scrollable_panel();
    return *interior_panel, widget;
}

with_scrollable_panel :: (id: int, $reserve: int, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of scrollable_panels being created)");
    interior_panel : Panel = ---;
    widget := _scrollable_panel(id, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count, reserve));
    `defer pop_scrollable_panel();
    assert(interior_panel.rect_frame_count == frame.count);
    return *interior_panel, widget;
}

with_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: bool, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(scrollable_panel, location, flags, width, height, *interior_panel);
    assert(interior_panel.rect_frame_count == frame.count);
    `defer pop_scrollable_panel();
    return *interior_panel, widget;
}


get_index :: (scrollable_panel: *Scrollable_Panel) -> int {
    index := scrollable_panel - scrollable_panel_data.data;
    assert(0 <= index && index < scrollable_panel_data.count, "Called get_index with a user-allocated scrollable_panel");
    return index;
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


scrollable_panel_data : [] Scrollable_Panel;
#no_reset scrollable_panel_count := 0;

_scrollable_panel :: inline (id: int, location: *At_Location, flags: Flags, width: int, height: int, interior_panel: *Panel, $gui_index: int) -> *Scrollable_Panel {
    return _scrollable_panel(*scrollable_panel_data[gui_index + id], location, flags, width, height, interior_panel);
}

_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, location: *At_Location, flags: Flags, width: int, height: int, interior_panel: *Panel) -> *Scrollable_Panel {
    scrollable_panel.widget = widget(.SCROLLABLE_PANEL, location, "", flags | .USE_SCROLLWHEEL);
    scrollable_panel.width = width;
    scrollable_panel.height = height;
    scrollable_panel.panel = interior_panel;

    update_scrollable_panel(scrollable_panel);
    draw_scrollable_panel(scrollable_panel);

    last_widget_location = location.*;

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

    panel.parent = main_panel;
    panel.desired_box = box(horizontal_position,vertical_position, horizontal_position+width, vertical_position+height);
    calculate_rect(panel); // finalize panel for this frame, as its parent main_panel is about to disappear off the stack
    push_scissor(main_panel.calculated_rect, flags);
    push_panel(panel);
}