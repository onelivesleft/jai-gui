#import "Basic";
#import "GUI";

main :: () {
    window := gui_create_window("GUI Test", 1024, 768);

    show_wheel := true;

    while gui_begin_frame() {
        defer gui_end_frame();

        _, button1 := button(window, place(         20,20, 0.5,40), "Hello");
        _, button2 := button(window, place(ord(0.5,40),20, -20,40), "World");

        left :=  panel(window,   0,100, 0.5,-100);
        right := panel(window, 0.5,100, 1.0,-100);

        buttons :: 20;
        for 0 .. buttons - 1 {
            height :: 30;
            //button(it, buttons, left,   place(0.3, it * height,  1.0, (it + 1) * height),  lorem[it % lorem.count], .LEFT | .SANS);
            button(it, buttons, right,  place(0.0, it * height,  0.7, (it + 1) * height),  lorem[it % lorem.count], .LEFT | .SERIF);
        }

        {
            value, scrollbar := vertical_scrollbar(left, place(100,100, 120,300), 0.5);
            label(scrollbar, place(ord(1.0,20),0.5, ord(1.0,20),0.5), tprint("%", value));
        }


        min :: -3;
        max :: +13;

        value, left_scrollbar := vertical_scrollbar(window, place(0,50, theme.scrollbar_size,ord(-50, 1.0)), 0, .{min, max}, .SMOOTH);
        label(window, place(50,0.0, 200,1.0), tprint("% % %", value, left_scrollbar.handle_size, left_scrollbar.handle_position), .LEFT);

        value=, right_scrollbar := vertical_scrollbar(window, place(-theme.scrollbar_size,50, 1.0,ord(-50, 1.0)), 1, .{min, max});
        label(window, place(-200,0.5, -50,0.5), tprint("%", value), .RIGHT);

        if label(window, place(-300,-30, -100,1.0), "Scroll Wheel:", .RIGHT | .INTERACTS)
            show_wheel = !show_wheel;

        if show_wheel {
            clicked, b := button(window, place(-100,-30, 1.0,1.0), tprint("%", mouse_scrollwheel));
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
            print("%\n", text);
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