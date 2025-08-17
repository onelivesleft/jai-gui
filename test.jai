#import "GUI";
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
max_found_buttons :: 256;
buttons : [max_found_buttons] Button;

toast_text: string;
toast_pos: Vector2;
toast_speed: Vector2;
toast_start_time: Frame_Time;
toast_duration : Frame_Time : 2.0;
toast_gravity :: 200.0;
toast_up_speed :: 200.0;


main_pointer: *u64;

// @TODO remove these
print_call_stack :: () #expand {
    base_pointer: *u64;
    print("---\n");
    foo: u64;
    #asm {
        rbp: gpr === bp;
        mov foo, rbp;
    }
    base_pointer = xx foo;
    while base_pointer && base_pointer != main_pointer {
        print("%\n", base_pointer);
        base_pointer = xx base_pointer.*;
    }
}

get_rbp :: inline () -> *u64 {
    rbp: *u64;
    #asm {
        mov di: gpr === di, *rbp;
    }
    #bytes .[72, 137, 47]; // mov [rdi], rbp
    return rbp;
}


main :: () {
    //print("main rbp = 0x%\n", get_rbp());
    application_panel, application_window_handle := gui_create_application_window("GUI Test", 1280, 896, 3100, 40);

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
        if should_quit  break;

        label_window :=  show_window(draw_label_window,  "Label",  at(0.55, 0.05,  0.95, 0.45), initially_closed=true);
        icon_window :=   show_window(draw_icon_window,   "Icon",   at(0.05, 0.05,  0.25, 0.25), DEFAULT_WINDOW_FLAGS | .SCROLLBARS | .THEME_A, initially_closed=true);
        button_window := show_window(draw_button_window, "Button", at(0.55, 0.55,  0.95, 0.95), initially_closed=true);
        keyboard_window := show_window(draw_keyboard_window, "Keyboard", at(0.25, 0.25,  0.75, 0.75), initially_closed=false);

        for keyboard.keys  if it & .START  last_pressed_key_code = cast(Key_Code) it_index;

        top, middle, bottom := split_top_middle_bottom(application_panel, 100, -100);
        left, right := split_left_right(middle, 0.5);

        height :: 32;

        clicked, icon_button := button(at(top, 0.25,20, ord(0.25,height),20+height), icon_id);
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

        show_table := checkbox(at(top, 0.5,height, ord(0.5,200),height*2), "Show Wordcount");
        {
            with_spacing(1);
            checkbox(at(top, 0.7,height, ord(0.7,height),height*2), .TAG, *label_window.is_open);
            checkbox(at(.COPY_RIGHT),                               .EMOTICON_POOP, *icon_window.is_open);
            checkbox(at(.COPY_RIGHT),                               .BUTTON_POINTER, *button_window.is_open);
            checkbox(at(.COPY_RIGHT),                               .KEYBOARD, *keyboard_window.is_open);
        }

        if show_table {
            table_panel, _ := split_left_right(right, 0.7);
            clicked, table := data_table(at_top(table_panel, -50), word_count_ptr);
        }
        else {
            button_count :: 20;
            button_panel, _ := split_left_right(right, 0.7);
            begin_placing(at_top(button_panel, height));
            for 0 .. button_count - 1
                button(it, at(button_panel,  box(.COPY_DOWN)),  lorem[it % lorem.count], .LEFT | .SERIF);
        }

        clicked=, _text_box := text_box(at(bottom, 0.5,0.0, 0.8,ord(1.0,-20)), lorem_text, .SMOOTH);
        if clicked {
            using _text_box;
            start_toast(labels[clicked_row_index - first_visible_row_index].text);
        }

        text_input(shrink(at_top(left, height), 0.2, 0), "Hola");
        icon(at(.FILL_LEFT), .Z_WAVE, height, .RIGHT);

        s_min :: -3;
        s_max :: +13;

        search_instead_of_filter := false;
        search_criteria_changed := false;

        quadrant_button_flags : Flags;

        {
            with_panel(left);
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
            icon_search_panel := at(left, -size*13-theme.scrollbar_size-20,ord(0.5,-100), ord(1.0,-20),ord(0.5,+100));
            top, bottom := split_top_bottom(icon_search_panel, size);
            search_text, search_input := text_input(at_left(top, -size), "", .IMMEDIATE);
            if button(at_right(top, -size), .FILTER_REMOVE) {
                set_text(search_input, "");
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
            panel_width : int = xx icon_search_panel.calculated_rect.w - theme.scrollbar_size;
            icons_per_row : int = panel_width / size;
            panel_height : int = min(max_found_buttons, found_icons.count) / icons_per_row;
            panel, scrollable_panel := push_scrollable_panel(at(bottom), panel_width, size * panel_height);
                for found_icons {
                    if it_index >= max_found_buttons  break;
                    row := it_index / icons_per_row;
                    col := it_index % icons_per_row;
                    _button := *buttons[it_index];
                    if button(_button, at(panel, col*size,row*size, (col+1)*size,(row+1)*size), it, tooltip=icon_names[it]) {
                        start_toast(sprint(".%", it));
                        os_clipboard_set_text(toast_text);
                    }
                }
                if reset_scroll  scrollable_panel._vertical_scrollbar.float_value = 0;
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

        upper, lower := split_top_bottom(left, 0.66);

        quadrant_button_panel := push_scrollable_panel(shrink(lower, 0.1, 0), 1000, 100, maybe_lock | .FIT);
            draw_box(peek_panel(), .{0.5, 0.3, 0.2, 0.1});
            tl, tr, bl, br := split_quadrants(quadrant_button_panel, 0.5, 0.5);
            quadrant_button_flags |= maybe_lock;
            button(shrink(tl, 0.1), "Uno", .DICE_1, quadrant_button_flags | .LEFT, "One");
            button(shrink(tr, 0.1), "Dos", .DICE_2, quadrant_button_flags, "Two");
            button(shrink(bl, 0.1), "Tres", .DICE_3, quadrant_button_flags | .ICON_ON_RIGHT, "Three");
            button(shrink(br, 0.1), "Mas", .DICE_4, quadrant_button_flags | .ICON_ON_RIGHT | .RIGHT, "More");
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

        label(at(60,1.0, 50,-110), tprint("Last pressed key: % 0x%", last_pressed_key_code, cast(*void) last_pressed_key_code), flags=.FIXED);
        label(at(60,1.0, 50,-80),  tprint("Usable Area: %", icon_window.desired_box), flags=.FIXED);
        label(at(60,1.0, 50,-50),  tprint("Warm: %", warm_widget), flags=.FIXED);
        label(at(60,1.0, 50,-20),  tprint("Hot:  %", hot_widget), flags=.FIXED);
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
    key_widget(.BACKQUOTE, "`", at(10,10, 42,42));
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
    key_widget(.BACKSPACE, .BACKSPACE);

    key_widget(.TAB, .KEYBOARD_TAB, at(10,44, 58,74));
    key_widget(.Q, .ALPHA_Q, at(58,44, 90,74));
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

    key_widget(.ENTER, .KEYBOARD_RETURN);

    //key_widget(.CAPSLOCK, .KEYBOARD_CAPS, at(10,44, 58,74)); //@TODO
    key_widget(.A, .ALPHA_A, at(58,76, 90,106));
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

    key_widget(.LEFT_SHIFT, .APPLE_KEYBOARD_SHIFT, at(10,108, 58,138));
    key_widget(.BACKSLASH, "\\", at(58,108, 90,138));
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
    key_widget(.RIGHT_SHIFT, .APPLE_KEYBOARD_SHIFT);

    key_widget(.LEFT_CONTROL, "CTRL", at(10,140, 58,170));
    key_widget(.LEFT_ALT, "ALT");
    key_widget(.SPACE, " ");
    key_widget(.RIGHT_ALT, "ALT");
    key_widget(.RIGHT_CONTROL, "CTRL");

    key_widget(.SHIFT, "Shift", at(100,192, 200,224));
    key_widget(.CONTROL, "Ctrl");
    key_widget(.ALT, "Alt");
}

// Custom key widget

key_widget :: (key_code: Key_Code, text: string, icon_id: Icon_Id, location: *At_Location, $callsite := #caller_location) {
    key_widget := widget(location, callsite=callsite);
    Key_Widget_Data :: struct {
        from_color := Vector4.{0, 0, 0, 1.0};
        to_color := Vector4.{0, 0, 0, 1.0};
        time: Frame_Time;
    }
    if !key_widget.data  key_widget.data = New(Key_Widget_Data);
    key_widget_data := cast(*Key_Widget_Data) key_widget.data;

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
    draw_box(location, color);
    if icon_id  draw_icon(location, icon_id, .{1.0, 1.0, 1.0, 1.0});
    if text     draw_text(location, text, .{1.0, 1.0, 1.0, 1.0}, font_style=.FIXED);
}

key_widget :: inline  (key_code: Key_Code, icon_id: Icon_Id, location: *At_Location, $callsite := #caller_location) {
    key_widget(key_code, "", icon_id, location, callsite);
}

key_widget :: inline  (key_code: Key_Code, text: string, location: *At_Location, $callsite := #caller_location) {
    key_widget(key_code, text, .NONE, location, callsite);
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
