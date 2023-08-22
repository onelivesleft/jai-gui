Scrollable_Panel :: struct {
    #as using widget: Widget;

    width, height: int;
    panel: *Panel;

    scrollbars: [2] Scrollbar;
}


scrollable_panel :: (location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(0, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count));
    return *interior_panel, widget;
}

scrollable_panel :: (id: int, $reserve: int, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: *Panel, *Scrollable_Panel #expand #no_debug {
    assert(0 <= id && id < reserve, "id = %, but must be in the range 0 <= id < reserve (which should be set to the amount of scrollable_panels being created)");
    interior_panel : Panel = ---;
    widget := _scrollable_panel(id, location, flags, width, height, *interior_panel, #insert #run next(*scrollable_panel_count, reserve));
    return *interior_panel, widget;
}

scrollable_panel :: (scrollable_panel: *Scrollable_Panel, location: *At_Location, width: int, height: int, flags := Flags.NONE) -> panel: bool, *Scrollable_Panel #expand #no_debug {
    interior_panel : Panel = ---;
    widget := _scrollable_panel(scrollable_panel, location, flags, width, height, *interior_panel);
    return *interior_panel, widget;
}


get_index :: (scrollable_panel: *Scrollable_Panel) -> int {
    index := scrollable_panel - scrollable_panel_data.data;
    assert(0 <= index && index < scrollable_panel_data.count, "Called get_index with a user-allocated scrollable_panel");
    return index;
}


#scope_module


scrollable_panel_data : [] Scrollable_Panel;
#no_reset scrollable_panel_count := 0;

_scrollable_panel :: inline (id: int, location: *At_Location, flags: Flags, width: int, height: int, interior_panel: *Panel, $gui_index: int) -> *Scrollable_Panel {
    return _scrollable_panel(*scrollable_panel_data[gui_index + id], location, flags, width, height, interior_panel);
}

_scrollable_panel :: (scrollable_panel: *Scrollable_Panel, location: *At_Location, flags: Flags, width: int, height: int, interior_panel: *Panel) -> *Scrollable_Panel {
    scrollable_panel.widget = widget(location, "", flags);
    scrollable_panel.width = width;
    scrollable_panel.height = height;
    scrollable_panel.panel = interior_panel;

    update_scrollable_panel(scrollable_panel);
    draw_scrollable_panel(scrollable_panel);

    last_widget_location = location.*;

    return scrollable_panel;
}

update_scrollable_panel :: (using scrollable_panel: *Scrollable_Panel) {
    maybe_calculate_rect(scrollable_panel);

    main_panel, bottom_scrollbar_panel, right_scrollbar_panel: *Panel;
    w := cast(float) width;
    h := cast(float) height;
    has_vertical_scrollbar := scrollable_panel.rect.h < h;
    has_horizontal_scrollbar := scrollable_panel.rect.w < w;

    if has_vertical_scrollbar {
        if has_horizontal_scrollbar
            main_panel, bottom_scrollbar_panel, right_scrollbar_panel := split_scrollbars_bottom_right(scrollable_panel);
        else
            main_panel, right_scrollbar_panel := split_scrollbar_right(scrollable_panel);
    }
    else if has_horizontal_scrollbar {
        main_panel, bottom_scrollbar_panel := split_scrollbar_bottom(scrollable_panel);
    }
    else {
        main_panel = scrollable_panel;
    }

    vertical_position, horizontal_position: float;

    if has_vertical_scrollbar {
        handle_size := height / main_panel.rect.h;
        vertical_position = vertical_scrollbar(*scrollbars[0], right_scrollbar_panel, handle_size=handle_size);
    }

    if has_horizontal_scrollbar {
        handle_size := width / main_panel.rect.w;
        horizontal_position = horizontal_scrollbar(*scrollbars[1], bottom_scrollbar_panel, handle_size=handle_size);
    }

    panel.parent = main_panel;
    panel._box = box(horizontal_position,vertical_position, ord(horizontal_position, width), ord(vertical_position, height));
    maybe_calculate_rect(panel);
}