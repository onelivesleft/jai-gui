#import "GUI";
#import "Basic";

Word_Count :: struct {
    word: string; @Width(0.7) @Left;
    count: int; @Width(0.3) @Fixed;
}

word_count : [..] Word_Count;


main :: () {
    window, window_handle := gui_create_window("GUI Test", 1024, 768);

    show_wheel := true;
    maybe_lock : Flags;

    prev_hot_widget : *Widget;

    generate_word_count();

    while gui_begin_frame() {
        top, middle, bottom := split_top_middle_bottom(window, 100, -100);
        left, right := split_left_right(middle, 0.5);

        height :: 30;

        show_table := checkbox(top, get_box(0.5,20, ord(0.5,200),20+height), "Show Wordcount");

        if show_table {
            table_panel, _ := split_left_right(right, 0.7);
            clicked, table := data_table(table_panel, get_box(.FILL), word_count);
            if clicked {
                print("% %", table.clicked_header, table.clicked_item.*);
            }
        }
        else {
            button_count :: 20;
            button_panel, _ := split_left_right(right, 0.7);
            begin_placing(at_top(height));
            for 0 .. button_count - 1
                button(it, button_count, button_panel,  get_box(.COPY_DOWN),  lorem[it % lorem.count], .LEFT | .SERIF);
        }

        text_input(left, shrink(at_top(height), 0.2, 0), "Hola");

        min :: -3;
        max :: +13;

        quadrant_button_flags : Flags;

        {
            push_spacing(4);  defer pop_spacing();

            value, scrollbar := vertical_scrollbar(left, get_box(100,50, 120,200), 0.0, .{0.0, 0.2}, tooltip = "A vertical scrollbar" );
            label(at(left, get_box(.COPY_RIGHT)), tprint("% % %", value, scrollbar.handle_position, scrollbar.handle_size));

            value, scrollbar = horizontal_scrollbar(left, get_box(250,50, 450,70), tooltip = "A horizontal scrollbar");
            _, l := label(at(left, get_box(.COPY_LEFT)), value, Flags.RIGHT);

            i:, scrollbar = horizontal_scrollbar(left, get_box(scrollbar, .COPY_DOWN), min, .{min, max}, tooltip = "Another horizontal scrollbar");
            label(at(left, get_box(.COPY_LEFT)), i, Flags.RIGHT);

            volume:, scrollbar = horizontal_scrollbar(left, get_box(scrollbar, .COPY_DOWN), min, .{min, max}, .REVERSE_SCROLLWHEEL, "Volume control");
            label(at(left, get_box(.COPY_LEFT)), tprint("volume: %", volume), Flags.RIGHT);

            if checkbox(left, get_box(scrollbar, .COPY_DOWN), "Gromit the scrogs", tooltip = "They really need it") {
                quadrant_button_flags = .THEME_A;
            }

            checkbox(left, get_box(.COPY_DOWN), "Show Scroll Wheel", *show_wheel, .IMMEDIATE | maybe_lock, tooltip = "It might be hidden!");

            maybe_lock = ifx checkbox(left, get_box(.COPY_DOWN), "Lock it down", maybe_lock != 0, .RIGHT | .IMMEDIATE, "Not allowed")
                         then .LOCKED
                         else xx 0;
        }

        push_spacing(4);
        left_value, left_scrollbar := vertical_scrollbar(window, get_box(0,50, theme.scrollbar_size,ord(-50, 1.0)), 0, .{min, max}, .SMOOTH | maybe_lock,
                                                         "Look how smoothly it scrolls");

        right_value, right_scrollbar := vertical_scrollbar(window, get_box(.MIRROR_HORIZONTAL), 1, .{min, max}, maybe_lock,
                                                           "Watch it jump between values");
        label(at(window, get_box(left_scrollbar, .COPY_RIGHT)), tprint("% % %", left_value, left_scrollbar.handle_size, left_scrollbar.handle_position));
        label(at(window, get_box(right_scrollbar, .COPY_LEFT)), right_value, Flags.RIGHT);
        pop_spacing();

        text_box(left, get_box(0.5,ord(0.5, -50), -20,ord(0.5, +50)), lorem_text, .SMOOTH);

        upper, lower := split_top_bottom(left, 0.66);
        tl, tr, bl, br := split_quadrants(lower, 0.5, 0.5);
        quadrant_button_flags |= maybe_lock;
        button(tl, shrink(get_box(.FILL), 0.2), "Uno", quadrant_button_flags, "One");
        button(tr, shrink(get_box(.FILL), 0.2), "Dos", quadrant_button_flags, "Two");
        button(bl, shrink(get_box(.FILL), 0.2), "Tres", quadrant_button_flags, "Three");
        button(br, shrink(get_box(.FILL), 0.2), "Mas", quadrant_button_flags, "More");

        if label(at(window, get_box(-300,-30, -100,1.0)), "Scroll Wheel:", Flags.RIGHT | .INTERACTS, "Get it back")
            show_wheel = !show_wheel;

        if show_wheel {
            clicked, b := button(window, get_box(-100,-30, 1.0,1.0), tprint("%", mouse.scrollwheel), tooltip = "Teehee");
            if clicked
                show_wheel = false;

            if is_hot(b) {
                use_scrollwheel(left_scrollbar, true);
                use_scrollwheel(right_scrollbar, true);
            }
        }

        if hot_widget != prev_hot_widget {
            //print("New hot widget: %\n", hot_widget);
            prev_hot_widget = hot_widget;
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
            print("% : % = %\n", text, clicked_widget.box, clicked_widget.rect);
        }
    }
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
