#import "Basic";
#import "GUI";

main :: () {
    window, window_handle := gui_create_window("GUI Test", 1024, 768);

    show_wheel := true;
    maybe_lock : Widget_Flags;

    while gui_begin_frame() {

        top, middle, bottom := split_top_middle_bottom(window, 100, -100);
        left, right := split_left_right(middle, 0.5);

        button_count :: 20;
        height :: 30;
        button_panel, _ := split_left_right(right, 0.7);
        begin_placing(at_top(height));
        for 0 .. button_count - 1
            button(it, button_count, button_panel,  place(.COPY_DOWN),  lorem[it % lorem.count], .LEFT | .SERIF);

        min :: -3;
        max :: +13;

        quadrant_button_flags : Widget_Flags;

        {
            push_spacing(4);  defer pop_spacing();

            value, scrollbar := vertical_scrollbar(left, place(100,50, 120,200), 0.0, .{0.0, 0.2}, tooltip = "A vertical scrollbar" );
            label(left, place(.COPY_RIGHT), tprint("% % %", value.*, scrollbar.handle_position, scrollbar.handle_size));

            value, scrollbar = horizontal_scrollbar(left, place(250,50, 450,70), tooltip = "A horizontal scrollbar");
            _, l := label(left, place(.COPY_LEFT), value.*, .RIGHT);

            i:, scrollbar = horizontal_scrollbar(left, place(scrollbar, .COPY_DOWN), min, .{min, max}, tooltip = "Another horizontal scrollbar");
            label(left, place(.COPY_LEFT), i.*, .RIGHT);

            volume:, scrollbar = horizontal_scrollbar(left, place(scrollbar, .COPY_DOWN), min, .{min, max}, .REVERSE_SCROLLWHEEL);
            label(left, place(.COPY_LEFT), tprint("volume: %", volume.*), .RIGHT);

            if checkbox(left, place(scrollbar, .COPY_DOWN), "Gromit the scrogs", tooltip = "They really need it") {
                quadrant_button_flags = .THEME_A;
            }

            checkbox(left, place(.COPY_DOWN), "Show Scroll Wheel", *show_wheel, .IMMEDIATE | maybe_lock, tooltip = "It might be hidden!");

            maybe_lock = ifx checkbox(left, place(.COPY_DOWN), "Lock it down", maybe_lock != 0, .RIGHT | .IMMEDIATE, "Not allowed")
                         then .LOCKED
                         else xx 0;
        }

        push_spacing(4);
        left_value, left_scrollbar := vertical_scrollbar(window, place(0,50, theme.scrollbar_size,ord(-50, 1.0)), 0, .{min, max}, .SMOOTH | maybe_lock,
                                                         "Look how smoothly it scrolls");
        right_value, right_scrollbar := vertical_scrollbar(window, place(.MIRROR_HORIZONTAL), 1, .{min, max}, maybe_lock,
                                                           "Watch it jump between values");
        label(window, place(left_scrollbar, .COPY_RIGHT), tprint("% % %", left_value.*, left_scrollbar.handle_size, left_scrollbar.handle_position));
        label(window, place(right_scrollbar, .COPY_LEFT), right_value.*, .RIGHT);
        pop_spacing();

        upper, lower := split_top_bottom(left, 0.66);
        tl, tr, bl, br := split_quadrants(lower, 0.5, 0.5);
        quadrant_button_flags |= maybe_lock;
        button(tl, shrink(place(.FILL), 0.2), "Uno", quadrant_button_flags, "One");
        button(tr, shrink(place(.FILL), 0.2), "Dos", quadrant_button_flags, "Two");
        button(bl, shrink(place(.FILL), 0.2), "Tres", quadrant_button_flags, "Three");
        button(br, shrink(place(.FILL), 0.2), "Mas", quadrant_button_flags, "More");

        if label(window, place(-300,-30, -100,1.0), "Scroll Wheel:", .RIGHT | .INTERACTS, "Get it back")
            show_wheel = !show_wheel;

        if show_wheel {
            clicked, b := button(window, place(-100,-30, 1.0,1.0), tprint("%", mouse_scrollwheel), tooltip = "Teehee");
            if clicked
                show_wheel = false;

            if is_hot(b) {
                use_scrollwheel(left_scrollbar, true);
                use_scrollwheel(right_scrollbar, true);
            }
        }

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
            print("% : % = %\n", text, clicked_widget.placement, clicked_widget.rect);
        }
    }
}

lorem :: string.[
    "Lorem ipsum dolor sit amet,",
    "consectetur adipiscing elit,",
    "sed do eiusmod tempor incididunt",
    "ut labore et dolore magna aliqua.",
    "Ut enim ad minim veniam,",
    "quis nostrud exercitation ullamco",
    "laboris nisi ut aliquip ex ea commodo",
    "consequat.",
    "Duis aute irure dolor in reprehenderit",
    "in voluptate velit esse cillum dolore",
    "eu fugiat nulla pariatur.",
    "Excepteur sint occaecat cupidatat non",
    "proident,",
    "sunt in culpa qui officia deserunt",
    "mollit anim id est laborum.",
];