CUSTOM_OS_WINDOW :: false;


#import "GUI"(BACKGROUND_DRAGS_OS_WINDOW=CUSTOM_OS_WINDOW);
#import "Basic";
#import "Clipboard";
#import "Math";


Word_Count :: struct {
    word: string; @Width(0.7) @Left;
    count: int; @Width(0.3) @Fixed;
}

word_count : [..] Word_Count;
word_count_ptr : [..] *Word_Count;

found_icons : [..] Icon_Id;
icon_names : [..] string;
max_found_buttons :: 8000;
buttons : [max_found_buttons] Button;
icon_scrollable_panel: *Scrollable_Panel;

toast_text: string;
toast_pos: Vector2;
toast_speed: Vector2;
toast_start_time: Frame_Time;
toast_duration : Frame_Time : 2.0;
toast_gravity :: 200.0;
toast_up_speed :: 200.0;

main :: () {
    application_window_flags := Application_Window_Flags.DEFAULT;
    #if CUSTOM_OS_WINDOW {
        application_window_flags &= ~.HAS_OS_DECORATIONS;
    }
    application_panel, application_window_handle := gui_create_application_window("GUI Test", 1280, 896, 3100, 40, application_window_flags);

    show_wheel := true;
    maybe_lock : Flags;

    prev_warm_widget : *Widget;

    generate_word_count();
    for * word_count  array_add(*word_count_ptr, it);

    icon_id := Icon_Id.ABACUS;
    previous_search_text := "-";

    for 0 .. Icon_Id.Z_WAVE {
        name := sprint("%", it);
        for 0 .. name.count - 1  name[it] = to_lower(name[it]);
        array_add(*icon_names, name);
    }

    /*
    os_dpi_init();
    {
        x, y, w, h := os_dpi_get_backing_coordinates(window_handle, 0, 0, 1280, 896);
        print("% % % %\n", x, y, w, h);
    }
    */

    last_pressed_key_code: Key_Code;

    while true {
        should_quit := gui_begin_frame();
        should_quit |= was_clicked(keyboard.escape) && !focussed_widget;
        if should_quit  break;

        label_window :=    window(draw_label_window,    "Label",    at(0.55, 0.05,  0.95, 0.45), initially_closed=true);
        icon_window :=     window(draw_icon_window,     "Icon",     at(0.05, 0.05,  0.25, 0.25), DEFAULT_WINDOW_FLAGS | .SCROLLBARS | .THEME_A, initially_closed=true);
        button_window :=   window(draw_button_window,   "Button",   at(0.55, 0.55,  0.95, 0.95), initially_closed=true);
        keyboard_window := window(draw_keyboard_window, "Keyboard", at(0.25, 0.25,  0.75, 0.75), initially_closed=true);

        array_reset(*on_screen_log);

        for keyboard.keys  if it & .START  last_pressed_key_code = cast(Key_Code) it_index;

        #if CUSTOM_OS_WINDOW {
            application_window_decoration_size :: 8;
            {
                s :: application_window_decoration_size;
                application_window_decoration(at(application_panel, s*2,0, -s*2,s), .TITLE_BAR);

                application_window_decoration(at(application_panel, 0,0, s,s), .RESIZE_NW);
                application_window_decoration(at(application_panel, -s,0, 1.0,s), .RESIZE_NE);
                application_window_decoration(at(application_panel, 0,-s, s,1.0), .RESIZE_SW);
                application_window_decoration(at(application_panel, -s,-s, 1.0,1.0), .RESIZE_SE);

                application_window_decoration(at(application_panel, 0,s*2, s/2,-s*2), .RESIZE_W);
                application_window_decoration(at(application_panel, -s/2,s*2, 1.0,-s*2), .RESIZE_E);
                application_window_decoration(at(application_panel, s*2,-s/2, -s*2,1.0), .RESIZE_S);

                application_window_decoration(at(application_panel, s*2,s*2, s*3,s*3), .CLOSE);
                application_window_decoration(at(application_panel, s*4,s*2, s*5,s*3), .MAXIMIZE);
                application_window_decoration(at(application_panel, s*6,s*2, s*7,s*3), .MINIMIZE);
            }

            inner_application_panel := shrink(application_panel, application_window_decoration_size);
            push_panel(inner_application_panel);
            header, main_panel, footer := split_top_middle_bottom(inner_application_panel, 100, -100);
        }
        else {
            header, main_panel, footer := split_top_middle_bottom(application_panel, 100, -100);
        }

        left_panel, right_panel := split_left_right(main_panel, 0.5);

        height :: 32;

        clicked, icon_button := button(at(header, 0.25,20, ord(0.25,height),20+height), icon_id);
        if clicked {
            icon_id += 1;
        }
        if mouse.scrollwheel && is_warm(icon_button) && !scrollwheel_widget {
            deplete_scrollwheel();
            new_id := cast(int)icon_id + mouse.scrollwheel;
            if new_id < 0  new_id += xx Icon_Id.Z_WAVE;
            if new_id > xx Icon_Id.Z_WAVE  new_id -= xx Icon_Id.Z_WAVE;
            icon_id = xx new_id;
        }
        {
            w, h := Simp.get_render_dimensions(application_window_handle);
            label(at(.COPY_RIGHT), tprint("% %", w, h));
        }

        show_table := checkbox(at(header, 0.5,height, ord(0.5,200),height*2), "Show Wordcount");
        {
            with_spacing(1);
            checkbox(at(header, 0.7,height, ord(0.7,height),height*2), .TAG, *label_window.is_open);
            checkbox(at(.COPY_RIGHT),                                  .EMOTICON_POOP, *icon_window.is_open);
            checkbox(at(.COPY_RIGHT),                                  .BUTTON_POINTER, *button_window.is_open);
            checkbox(at(.COPY_RIGHT),                                  .KEYBOARD, *keyboard_window.is_open);
        }

        if show_table {
            table_panel, _ := split_left_right(right_panel, 0.7);
            clicked, table := data_table(at_top(table_panel, -50), word_count_ptr);
        }
        else {
            button_count :: 20;
            button_panel, _ := split_left_right(right_panel, 0.7);
            begin_placing(at_top(button_panel, height));
            for 0 .. button_count - 1
                button(it, at(button_panel,  box(.COPY_DOWN)),  lorem[it % lorem.count], .LEFT | .SERIF);
        }

        clicked=, _input_box := input_box(at(footer, 0.5,0.0, 0.8,ord(1.0,-20)), lorem_text, .SMOOTH);
        if clicked {
            using _input_box;
            start_toast(labels[clicked_row_index - first_visible_row_index].text);
        }

        input_line(shrink(at_top(left_panel, height), 0.2, 0), "Hola", .READ_ONLY);
        icon(at(.FILL_LEFT), .Z_WAVE, height, .RIGHT);

        s_min :: -3;
        s_max :: +13;

        search_instead_of_filter := false;
        search_criteria_changed := false;

        quadrant_button_flags : Flags;

        {
            with_panel(left_panel);
            with_spacing(4);

            value, scrollbar := vertical_scrollbar(at(100,50, 120,200), 0.0, .{0.0, 0.2}, tooltip = "A vertical scrollbar" );
            label(at(.COPY_RIGHT), tprint("% % %", value, scrollbar.handle_position, scrollbar.handle_size));

            value, scrollbar = horizontal_scrollbar(at(250,50, 450,70), tooltip = "A horizontal scrollbar");
            _, l := label(at(.COPY_LEFT), value, Flags.RIGHT);

            i:, scrollbar = horizontal_scrollbar(at(box(scrollbar, .COPY_DOWN)), s_min, .{s_min, s_max}, tooltip = "Another horizontal scrollbar");
            label(at(.COPY_LEFT), i, Flags.RIGHT);

            volume:, scrollbar = horizontal_scrollbar(at(box(scrollbar, .COPY_DOWN)), s_min, .{s_min, s_max}, .REVERSE_SCROLLWHEEL, "Volume control");
            label(at(.COPY_LEFT), tprint("volume: %", volume), Flags.RIGHT);

            if checkbox(at(box(scrollbar, .COPY_DOWN)), "Gromit the scrogs", tooltip = "They really need it") {
                quadrant_button_flags = .THEME_A;
            }

            checkbox(at(.COPY_DOWN), "Show Scroll Wheel", *show_wheel, maybe_lock, tooltip = "It might be hidden!");

            maybe_lock = ifx checkbox(at(.COPY_DOWN), "Lock it down", maybe_lock != 0, .RIGHT, "Not allowed")
                         then .LOCKED;

            search_instead_of_filter=, search_instead_of_filter_checkbox := checkbox(at(.COPY_DOWN), "Search instead of filter", flags=.OVERFLOW);
            if was_changed(search_instead_of_filter_checkbox)
                search_criteria_changed = true;
        }

        {
            size :: 32;
            icon_search_panel := at(left_panel, -size*13-theme.scrollbar_size-20,ord(0.5,-100), ord(1.0,-20),ord(0.5,+100));
            top, bottom := split_top_bottom(icon_search_panel, size);
            search_text, search_input := input_line(at_left(top, -size), "", .IMMEDIATE);
            if button(at_right(top, -size), .FILTER_REMOVE) {
                set_text(search_input, "");
                focus(search_input);
            }
            reset_scroll := false;
            if search_text != previous_search_text || search_criteria_changed {
                previous_search_text = search_text;
                reset_scroll = true;
                if search_instead_of_filter && search_text {
                    array_reset(*found_icons);
                    found := false;
                    for Icon_Id.ABACUS .. Icon_Id.Z_WAVE {
                        if icon_names[it] == search_text
                            found = true;
                        if found
                            array_add(*found_icons, it);
                    }
                }
                else {
                    array_reset(*found_icons);
                    for Icon_Id.ABACUS .. Icon_Id.Z_WAVE {
                        if search_text == "" {
                            array_add(*found_icons, it);
                        }
                        else if contains(icon_names[it], search_text) {
                            array_add(*found_icons, it);
                        }
                    }
                }
            }
            virtual_width : int = xx icon_search_panel.calculated_rect.w - theme.scrollbar_size;
            icons_per_row : int = virtual_width / size;
            total_row_count : int = min(max_found_buttons, found_icons.count) / icons_per_row + 1;
            virtual_height := total_row_count * size;
            panel_location := at(bottom);
            calculate_rect(panel_location);
            visible_row_count := cast(int)(panel_location.calculated_rect.h / size) + 2;
            scrollable_row_count := total_row_count - visible_row_count + 1;
            drawn_count := 0;
            panel, icon_scrollable_panel := push_scrollable_panel(panel_location, virtual_width, virtual_height);
                first_row := cast(int)(icon_scrollable_panel._vertical_scrollbar.float_value * scrollable_row_count);
                first_icon := clamp(first_row * icons_per_row, 0, found_icons.count - 1);
                last_icon := clamp(first_icon + visible_row_count * icons_per_row, first_icon, found_icons.count - 1);
                if found_icons  for index: first_icon .. last_icon {
                    icon := found_icons[index];
                    drawn_count += 1;
                    row := index / icons_per_row;
                    col := index % icons_per_row;
                    _button := *buttons[index];
                    if button(_button, at(panel, col*size,row*size, (col+1)*size,(row+1)*size), icon, tooltip=icon_names[icon]) {
                        start_toast(sprint(".%", icon));
                        os_clipboard_set_text(toast_text);
                    }
                }
                if reset_scroll  icon_scrollable_panel._vertical_scrollbar.float_value = 0;
            pop_scrollable_panel();
        }

        push_spacing(4);
            left_value, left_scrollbar := vertical_scrollbar(at(0,50, theme.scrollbar_size,ord(-50, 1.0)), 0, .{s_min, s_max}, .SMOOTH | maybe_lock,
                                                             "Look how smoothly it scrolls");

            right_value, right_scrollbar := vertical_scrollbar(at(.MIRROR_HORIZONTAL), 1, .{s_min, s_max}, maybe_lock,
                                                               "Watch it jump between values");
            label(at(box(left_scrollbar, .COPY_RIGHT)), tprint("% % %", left_value, left_scrollbar.handle_size, left_scrollbar.handle_position));
            label(at(box(right_scrollbar, .COPY_LEFT)), right_value, Flags.RIGHT);
        pop_spacing();

        upper, lower := split_top_bottom(left_panel, 0.66);

        quadrant_button_panel := push_scrollable_panel(shrink(lower, 0.1, 0), 1000, 100, maybe_lock | .FIT);
            draw_box(peek_panel(), .{0.5, 0.3, 0.2, 0.1});
            tl, tr, bl, br := split_quadrants(quadrant_button_panel, 0.5, 0.5);
            quadrant_button_flags |= maybe_lock;
            button(shrink(tl, 0.1), "Uno",  .DICE_1, quadrant_button_flags | .LEFT, "One");
            button(shrink(tr, 0.1), "Dos",  .DICE_2, quadrant_button_flags, "Two");
            button(shrink(bl, 0.1), "Tres", .DICE_3, quadrant_button_flags | .ICON_ON_RIGHT, "Three");
            button(shrink(br, 0.1), "Mas",  .DICE_4, quadrant_button_flags | .ICON_ON_RIGHT | .RIGHT, "More");
        pop_scrollable_panel();

        if label(at(-300,-30, -100,1.0), "Scroll Wheel:", Flags.RIGHT | .INTERACTS, "Get it back")
            show_wheel = !show_wheel;

        if show_wheel {
            clicked, b := button(at(-100,-30, 1.0,1.0), tprint("%", mouse.scrollwheel), tooltip = "Teehee");
            if clicked
                show_wheel = false;

            if is_warm(b) {
                use_scrollwheel(left_scrollbar);
                use_scrollwheel(right_scrollbar);
            }
        }

        if warm_widget != prev_warm_widget
            prev_warm_widget = warm_widget;

        if clicked_widget {
            t := widget_type(clicked_widget);
            text: string;
            if t == Label {
                label := cast(*Label)clicked_widget;
                text = label.text;
            }
            else if t == Button {
                button := cast(*Button)clicked_widget;
                text = button.text;
            }
            else {
                text = tprint("%", t);
            }
            print("% : % = %\n", text, clicked_widget.desired_box, clicked_widget.calculated_rect);
        }

        update_toast();

        gui_draw_windows();

        log("Last pressed key: % 0x%", last_pressed_key_code, cast(*void) last_pressed_key_code);
        log("Usable Area: %", icon_window.desired_box);
        log("Warm: %", warm_widget);
        log("Hot:  %", hot_widget);
        log("Focussed Window: %", focussed_window);
        log("Warm Window:     %", warm_window);
        {
            step :: 30;
            y := -20;
            for on_screen_log {
                label(at(60,1.0, 50,y), it, flags=.FIXED);
                y -= step;
            }
        }
    }
}

draw_label_window :: (window: *Window) {
    label(at(0.4,0.4, 0.6,0.6), "Hello");
}

draw_icon_window :: (window: *Window) {
    with_spacing(10);

    icon(at(20,20, 100,100), .WATER_BOILER_OFF, flags=.FIT);
    icon(at(.COPY_RIGHT),    .AIRPLANE_MARKER,  flags=.FIT);
    icon(at(.COPY_DOWN),     .BANK,             flags=.FIT);
    icon(at(.COPY_LEFT),     .BLUR_RADIAL,      flags=.FIT);

    add_margin_to_drawn_widget_bounds(20);
}

draw_button_window :: (window: *Window) {
    button(at(0.3,0.3, 0.7,0.7), "World", tooltip="Mundis");
}

draw_keyboard_window :: (window: *Window) {
    left_edge := 10;
    top_edge :: 10;
    size :: 32;
    spacing :: 2;
    with_spacing(spacing);

    row_top := top_edge;
    next_row :: () #expand { row_top += size + spacing; }

    key_widget(.ESCAPE, "ESC", at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(.F1, "F1", at(left_edge+1*size+spacing+1*size/2,row_top, left_edge+2*size+spacing+1*size/2,row_top+size));
    key_widget(.F2, "F2");
    key_widget(.F3, "F3");
    key_widget(.F4, "F4");
    key_widget(.F5, "F5", at(left_edge+5*size+spacing+2*size/2,row_top, left_edge+6*size+spacing+2*size/2,row_top+size));
    key_widget(.F6, "F6");
    key_widget(.F7, "F7");
    key_widget(.F8, "F8");
    key_widget(.F9, "F9", at(left_edge+9*size+spacing+3*size/2,row_top, left_edge+10*size+spacing+3*size/2,row_top+size));
    key_widget(.F10, "F10");
    key_widget(.F11, "F11");
    key_widget(.F12, "F12");

    next_row();
    row_top += spacing * 2;

    key_widget(.BACKQUOTE, "`", at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(._1, .NUMERIC_1);
    key_widget(._2, .NUMERIC_2);
    key_widget(._3, .NUMERIC_3);
    key_widget(._4, .NUMERIC_4);
    key_widget(._5, .NUMERIC_5);
    key_widget(._6, .NUMERIC_6);
    key_widget(._7, .NUMERIC_7);
    key_widget(._8, .NUMERIC_8);
    key_widget(._9, .NUMERIC_9);
    key_widget(._0, .NUMERIC_0);
    key_widget(.MINUS, .MINUS);
    key_widget(.EQUALS, .EQUAL);

    backspace := at(.COPY_RIGHT);

    next_row();

    key_widget(.TAB, .KEYBOARD_TAB, at(left_edge,row_top, left_edge+size+14,row_top+size));
    key_widget(.Q, .ALPHA_Q, at(left_edge+size+14+spacing,row_top, left_edge+2*size+14+spacing,row_top+size));
    key_widget(.W, .ALPHA_W);
    key_widget(.E, .ALPHA_E);
    key_widget(.R, .ALPHA_R);
    key_widget(.T, .ALPHA_T);
    key_widget(.Y, .ALPHA_Y);
    key_widget(.U, .ALPHA_U);
    key_widget(.I, .ALPHA_I);
    key_widget(.O, .ALPHA_O);
    key_widget(.P, .ALPHA_P);
    key_widget(.LEFT_BRACKET, "[");
    key_widget(.RIGHT_BRACKET, "]");

    left_of_return := at(.COPY_RIGHT);
    left_of_return.desired_box.br.x -= 22;
    key_widget(.ENTER, "", left_of_return);

    next_row();

    key_widget(.CAPSLOCK, .KEYBOARD_CAPS, at(left_edge,row_top, left_edge+size+24,row_top+size)); //@TODO
    key_widget(.A, .ALPHA_A, at(left_edge+size+24+spacing,row_top, left_edge+2*size+24+spacing,row_top+size));
    key_widget(.S, .ALPHA_S);
    key_widget(.D, .ALPHA_D);
    key_widget(.F, .ALPHA_F);
    key_widget(.G, .ALPHA_G);
    key_widget(.H, .ALPHA_H);
    key_widget(.J, .ALPHA_J);
    key_widget(.K, .ALPHA_K);
    key_widget(.L, .ALPHA_L);
    key_widget(.SEMICOLON, ";");
    key_widget(.QUOTE, "'");
    key_widget(.HASH, "#");

    right_of_return := at(.COPY_RIGHT);
    right_of_return.desired_box.tl.y -= 34;
    right_of_main := right_of_return.desired_box.br.x;
    key_widget(.ENTER, .KEYBOARD_RETURN, right_of_return);

    backspace.desired_box.br.x = right_of_main;
    key_widget(.BACKSPACE, .BACKSPACE, backspace);

    next_row();

    key_widget(.LEFT_SHIFT, .APPLE_KEYBOARD_SHIFT, at(left_edge,row_top, left_edge+size+14,row_top+size));
    key_widget(.BACKSLASH, "\\", at(left_edge+size+14+spacing,row_top, left_edge+2*size+14,row_top+size));
    key_widget(.Z, .ALPHA_Z);
    key_widget(.X, .ALPHA_X);
    key_widget(.C, .ALPHA_C);
    key_widget(.V, .ALPHA_V);
    key_widget(.B, .ALPHA_B);
    key_widget(.N, .ALPHA_N);
    key_widget(.M, .ALPHA_M);
    key_widget(.COMMA, ",");
    key_widget(.PERIOD, ".");
    key_widget(.SLASH, "/");

    right_shift := at(.COPY_RIGHT);
    right_shift.desired_box.br.x = right_of_main;
    key_widget(.RIGHT_SHIFT, .APPLE_KEYBOARD_SHIFT, right_shift);

    next_row();

    key_widget(.LEFT_CONTROL, "CTRL", at(left_edge,row_top, left_edge+size+16,row_top+size));
    left_alt := at(.COPY_RIGHT);
    right_ctrl := copy(left_alt);
    key_widget(.LEFT_ALT, "ALT", left_alt);
    left_of_space := at(.COPY_RIGHT);

    delta := right_shift.desired_box.br.x - right_ctrl.desired_box.br.x;
    right_ctrl.desired_box.tl.x += delta;
    right_ctrl.desired_box.br.x += delta;
    key_widget(.RIGHT_CONTROL, "CTRL", right_ctrl);
    key_widget(.APPLICATION, "APP", at(.COPY_LEFT));
    key_widget(.RIGHT_ALT, "ALT", at(.COPY_LEFT));

    space := at(.COPY_LEFT);
    space.desired_box.tl.x = left_of_space.desired_box.tl.x;
    key_widget(.SPACE, " ", space);

    //key_widget

    next_row();
    next_row();

    key_widget(.SHIFT, "Shift", at(100,row_top, 200,row_top+size));
    key_widget(.CONTROL, "Ctrl");
    key_widget(.ALT, "Alt");


    row_top = top_edge;
    left_edge = right_of_main.abs + size / 2;

    key_widget(.PRINT, .FIT_TO_SCREEN, at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(.SCROLLLOCK, .ARROW_VERTICAL_LOCK);
    key_widget(.PAUSE, .PAUSE);

    next_row();
    row_top += spacing * 2;

    key_widget(.INSERT, "INS", at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(.HOME, "HOME");
    key_widget(.PAGEUP, "PGUP");
    next_row();
    key_widget(.DELETE, "DEL", at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(.END, "END");
    key_widget(.PAGEDOWN, "PGDN");
    next_row();
    next_row();
    key_widget(.UP, .ARROW_UP_THIN, at(left_edge+size+spacing,row_top, left_edge+2*size+spacing,row_top+size));
    next_row();
    key_widget(.LEFT, .ARROW_LEFT_THIN, at(left_edge,row_top, left_edge+size,row_top+size));
    key_widget(.DOWN, .ARROW_DOWN_THIN);
    key_widget(.RIGHT, .ARROW_RIGHT_THIN);

}

// Custom key widget

key_widget :: (key_code: Key_Code, text: string, icon_id: Icon_Id, panel: *Panel, $callsite := #caller_location) {
    Key_Widget_Data :: struct {
        from_color := Vector4.{0, 0, 0, 1.0};
        to_color := Vector4.{0, 0, 0, 1.0};
        time: Frame_Time;
    }

    key_widget, key_widget_data := widget(Key_Widget_Data, panel, callsite=callsite);

    key_state := keyboard.keys[key_code];
    fade_duration :: 0.2;

    if was_clicked(key_state, ignore_repeat=true) {
        key_widget_data.from_color = .{1.0, 0.0, 0.0, 1.0};
        key_widget_data.to_color = .{0.0, 0.0, 1.0, 1.0};
        key_widget_data.time = frame.time;
    }
    else if was_released(key_state) {
        key_widget_data.from_color = .{0.0, 1.0, 0.0, 1.0};
        key_widget_data.to_color = .{0.0, 0.0, 0.0, 1.0};
        key_widget_data.time = frame.time;
    }
    t := cast(float) ((frame.time - key_widget_data.time) / fade_duration);
    color := lerp(key_widget_data.from_color, key_widget_data.to_color, t);

    if is_hot(key_widget) then color = .{1.0, 0.0, 1.0, 1.0};
    else if is_warm(key_widget) then color = .{1.0, 0.0, 1.0, 0.75};

    Simp.set_shader_for_color();
    draw_box(panel, color);
    size := cast(int) min(panel.calculated_rect.w, panel.calculated_rect.h) / 2;
    panel = at(panel, ord(0.5,-size),ord(0.5,-size), ord(0.5,+size),ord(0.5,+size));
    if icon_id  draw_icon(panel, icon_id, .{1.0, 1.0, 1.0, 1.0});
    text_size : s16 = cast,trunc(s16) ifx text.count > 2 then 14 else 16;
    if text     draw_text(panel, text, .{1.0, 1.0, 1.0, 1.0}, text_size, font_style=.FIXED);
}

key_widget :: inline  (key_code: Key_Code, icon_id: Icon_Id, panel: *Panel, $callsite := #caller_location) {
    key_widget(key_code, "", icon_id, panel, callsite);
}

key_widget :: inline  (key_code: Key_Code, text: string, panel: *Panel, $callsite := #caller_location) {
    key_widget(key_code, text, .NONE, panel, callsite);
}

key_widget :: inline  (key_code: Key_Code, icon_id: Icon_Id, $callsite := #caller_location) {
    key_widget(key_code, "", icon_id, at(.COPY_RIGHT), callsite);
}

key_widget :: inline  (key_code: Key_Code, text: string, $callsite := #caller_location) {
    key_widget(key_code, text, .NONE, at(.COPY_RIGHT), callsite);
}

start_toast :: (text: string) {
    if toast_text  free(toast_text);
    toast_text = copy_string(text);
    toast_pos = Vector2.{mouse.x, mouse.y};
    toast_speed = Vector2.{0.0, -toast_up_speed};
    toast_start_time = frame.time;
}

update_toast :: () {
    if !toast_start_time  return;
    t := 1.0 - cast(float)((frame.time - toast_start_time) / toast_duration);
    if t < 0 {
         toast_start_time = 0;
         return;
    }
    if t > 0.5  t = 1.0;
    else t *= 2;
    if toast_start_time < frame.time {
        color := Vector4.{0.0, 0.0, 0.0, t};
        rect := Rect.{toast_pos.x, toast_pos.y - 20, 200, 40};
        draw_text(rect, toast_text, color);
    }
    toast_pos += toast_speed * frame.dt;
    toast_speed.y += toast_gravity * frame.dt;
    color := Vector4.{1.0, 1.0, 1.0, t};
    rect := Rect.{toast_pos.x, toast_pos.y - 20, 200, 40};
    draw_text(rect, toast_text, color);
}

generate_word_count :: () {
    #import "String";
    for line: lorem {
        words := split(line, " ");
        for word: words {
            for * word_count {
                if it.word == word {
                    it.count += 1;
                    continue word;
                }
            }
            array_add(*word_count, .{word, 1});
        }
    }
}


lorem_text :: #string __
Lorem ipsum dolor sit amet,
consectetur adipiscing elit,
sed do eiusmod tempor incididunt
ut labore et dolore magna aliqua.
Ut enim ad minim veniam,
quis nostrud exercitation ullamco
laboris nisi ut aliquip ex ea commodo
consequat.
Duis aute irure dolor in reprehenderit
in voluptate velit esse cillum dolore
eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non
proident,
sunt in culpa qui officia deserunt
mollit anim id est laborum.
__;

lorem :: #insert -> string {
    builder : String_Builder;
    append(*builder, #string jai
        string.[
    jai);
    lines := split(lorem_text, "\n");
    for lines  if it  print_to_builder(*builder, #string jai
            "%",
    jai, it);
    append(*builder, #string jai
        ];
    jai);
    return builder_to_string(*builder);
}


on_screen_log: [..] string;

log :: (format_string: string, args: .. Any) {
    array_add(*on_screen_log, tprint(format_string, ..args));
}
