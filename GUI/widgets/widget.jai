// Base struct for all widgets
Widget :: struct {
    #as using location: At_Location;

    type : enum { // Need to use an enum because the Type itself can be polymorphic, e.g. Data_Table($T)
        CUSTOM;
        WINDOW;
        WINDOW_DECORATION;

        BUTTON;
        CHECKBOX;
        DATA_TABLE;
        ICON;
        LABEL;
        SCROLLABLE_PANEL;
        SCROLLBAR;
        TEXT_BOX;
        TEXT_INPUT;
    }

    tooltip : string;
    flags : Flags;
}

// Custom Widget when user calls widget() to make their own widget without patching it into GUI.
// It's just a Widget with a *void data pointer attached.
Custom_Widget :: struct {
    #as using widget: Widget;
    type = .CUSTOM;

    data: *void;
}

widget :: (location: *At_Location, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Custom_Widget {
    return _widget(0, location, flags, tooltip, callsite_key(callsite));
}

widget :: (id: int, location: *At_Location, flags := Flags.NONE, tooltip := "", $callsite := #caller_location) -> *Custom_Widget {
    return _widget(id, location, flags, tooltip, callsite_key(callsite));
}

widget :: (widget: *Custom_Widget, location: *At_Location, flags := Flags.NONE, tooltip := "") -> *Custom_Widget {
    return _widget(widget, location, flags, tooltip);
}


#scope_file


custom_widget_data: Table(u64, Custom_Widget);


_widget :: inline (id: int, location: *At_Location, flags: Flags, tooltip: string, callsite_key: u64) -> *Custom_Widget {
    key := widget_key(id, currently_drawing_window, callsite_key);
    widget := find_or_add(*custom_widget_data, key);
    return _widget(widget, location, flags, tooltip);
}

_widget :: (widget: *Custom_Widget, location: *At_Location, flags: Flags, tooltip: string) -> *Custom_Widget {
    widget.widget = .{ location, .CUSTOM, tooltip, flags };
    last_widget_location = location.*;

    update_widget(widget);

    return widget;
}


#scope_export


widget_key :: (id: int, window: *Window, callsite_key: u64) -> u64 {
    data : struct {
        _id: int;
        _window_key: u64;
        _callsite_key: u64;
    } = .{id, ifx window then window.key, callsite_key};
    return fnv1a_hash(*data, size_of(type_of(data)));
}

callsite_key :: ($callsite: Source_Code_Location) -> u64 #expand {
    return #run fnv1a_hash(*callsite, size_of(Source_Code_Location));
}


widget_type :: (widget: *Widget) -> Type {
    #insert -> string {
        builder: String_Builder;
        for Widget_Types {
            info := cast(*Type_Info) it;
            type_name := tprint("%", it);
            enum_name := upper(tprint("%", it));
            print_to_builder(*builder, #string jai
                if widget.type == .%1  return %2%3;
            jai, enum_name, type_name, ifx info.runtime_size >= 0 then "" else "(void)");
        }
        append(*builder, #string jai
                assert(false, "Tried to look up a widget type for a non-existent index: %", widget.type);
            jai);
        return builder_to_string(*builder);
    }
    return Widget;
}

update_widget :: (using widget: *Widget) {
    maybe_calculate_rect(widget);
    calculate_drawn_widget_bounds(calculated_rect);

    scissor := peek_scissor();
    if scissor && !contains(scissor.*, mouse.x, mouse.y)
        return;

    is_mouse_over := contains(calculated_rect, mouse.x, mouse.y);
    if is_mouse_over
        tooltip_widget = widget;

    if is_locked(widget)
        return;

    if is_mouse_over && flags & .USE_SCROLLWHEEL
        request_scrollwheel(widget);

    if hot_widget && hot_widget != widget
        return;

    if is_mouse_over
        request_warmth(widget);

    if is_hot(widget) {
        if mouse.left_button_end {
            set_hot(widget, false);
            if is_mouse_over
                set_released(widget);
        }
    }

    if is_warm(widget) {
        if !is_mouse_over {
            set_warm(widget, false);
        }
        else if mouse.left_button_start {
            set_hot(widget, true);
            set_clicked(widget);
        }
    }
}

use_scrollwheel :: (using widget: *Widget) {
    if widget.type == {
        case .DATA_TABLE;        use_scrollwheel(*(cast(*Data_Table(void))widget).scrollbar);
        case .SCROLLABLE_PANEL;  use_scrollwheel(cast(*Scrollable_Panel) widget);
        case .SCROLLBAR;         use_scrollwheel(cast(*Scrollbar) widget);
        case .TEXT_BOX;          use_scrollwheel(*(cast(*Text_Box)widget).scrollbar);
        case .WINDOW;            use_scrollwheel(cast(*Window) widget);
    }
}

deplete_scrollwheel :: () {
    scrollwheel_widget = null;
}

