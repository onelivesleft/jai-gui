#import "GUI";
#import "Basic";
#import "Math";
#import "Random";

initial_width :: 1024;
initial_height :: 1024;
initial_cell_size_index :: 4;
cell_sizes :: float.[2, 3, 4, 5, 6, 8, 10, 16, 24, 32, 48, 64, 96, 128];

cell_size := cell_sizes[initial_cell_size_index];
cell_size_index := initial_cell_size_index;

Cell :: enum_flags u8 {
    ODD_BIT_INDEX :: 0;
    EVEN_BIT_INDEX :: 1;
    ODD_STATE :: 1 << ODD_BIT_INDEX;
    EVEN_STATE :: 1 << EVEN_BIT_INDEX;
    EXTRA_BITS_MASK :: ~(ODD_STATE|EVEN_STATE);
};

cells: [] Cell;
cells_width: int;
cells_height: int;
active_cell_parity := Cell.ODD_BIT_INDEX;

life_running := true;
life_run_for_one_step := false;
wrap_world := true;
show_trail := true;
randomize_grid_on_startup := true;

mouse_is_drawing_alive_cells: bool;
temporary_pause := false;
cell_size_changed := false;
draw_offset: Vector2;

big_widget_size :: 32;
big_margin :: 5;

small_widget_size :: 16;
small_margin :: 2;

application_panel: *Panel;
should_quit := false;
application_has_focus := true;

main :: () {
    // Step 1.  Create OS window
    application_panel = gui_create_application_window("GUI Example", initial_width, initial_height);

    // Step 2.  Loop until quit
    while !should_quit {
        // Step 3.  Call gui_begin_frame at the start of every frame.
        should_quit, application_has_focus = gui_begin_frame();

        check_for_grid_resize();

        // Step 4.  If you want to have windows (that the user can drag, rearrange, etc.) then you make a window proc like this:
        draw_controls :: (window: *Window) {
            control_count :: 4;
            controls, settings := split_left_right(window, big_widget_size*control_count + big_margin*(control_count+1));

            {
                with_panel(controls);
                with_spacing(big_margin);

                play_pause_icon := ifx life_running then Icon_Id.PLAY else .PAUSE;
                checkbox(at_size(big_margin,big_margin, big_widget_size,big_widget_size), play_pause_icon, *life_running);

                step_icon := Icon_Id.STEP_FORWARD;
                if button(at(.COPY_RIGHT), step_icon)
                    life_run_for_one_step = true;


                random_fill_icon := Icon_Id.GRAIN;
                if button(at(.COPY_RIGHT), random_fill_icon)
                    random_fill_cells();

                clear_icon := Icon_Id.ERASER;
                if button(at(.COPY_RIGHT), clear_icon)
                    clear_cells();
            }

            {
                row := shrink_to_height(settings, small_widget_size);
                _, row, _ = split_left_middle_right(row, big_margin*2, -big_margin);
                checkbox(at(row, 0,0.0, 70,1.0), "Wrap", *wrap_world);
                checkbox(at(.COPY_RIGHT),        "Trail", *show_trail);

                if horizontal_scrollbar(at(.FILL_RIGHT), *cell_size_index, .{0, cell_sizes.count - 1}, .REVERSE_SCROLLWHEEL)
                    cell_size_changed = true;
            }
        }

        // Step 5.  This tells GUI to draw the window this frame, when you call gui_draw_windows (as long as its is_open bool is true).
        //          The code in draw_controls (above) doesn't run until then.
        controls_window := window(draw_controls, "Controls", at_size(10,-52, 400,42), flags=.CAN_MOVE); // Try removing the flags parameter to see the default window appearance.

        showing_gui := controls_window.is_open;  // We're going to hide the quit button when we hide the controls window.

        active_cell_parity = (Cell.ODD_BIT_INDEX + .EVEN_BIT_INDEX) - active_cell_parity;
        mouse_cell_x := wrap(cast(int) ((mouse.x - draw_offset.x) / cell_size), 0, cells_width);
        mouse_cell_y := wrap(cast(int) ((mouse.y - draw_offset.y) / cell_size), 0, cells_height);

        // Step 6.  To use the mouse the mouse in your game logic, first check its not being used by GUI:
        if !gui_has_mouse() {
            if was_clicked(mouse.left_button) {
                cell := get_cell(mouse_cell_x, mouse_cell_y);
                if cell  mouse_is_drawing_alive_cells = !is_alive(cell);
            }

            if mouse.left_button {
                temporary_pause = true;
                cell := get_cell(mouse_cell_x, mouse_cell_y);
                drawing_alive_cells := mouse_is_drawing_alive_cells;
                if mouse.right_button  drawing_alive_cells = !drawing_alive_cells;
                if cell  set_cell_life_this_frame(cell, drawing_alive_cells);
            }
            else {
                temporary_pause = false;
                if was_clicked(mouse.right_button)  controls_window.is_open = !controls_window.is_open;
            }

            if mouse.middle_button
                draw_offset += mouse.delta;

            cell_size_delta := mouse.scrollwheel;
            if was_clicked(mouse.x1_button)  cell_size_delta -= 1;
            if was_clicked(mouse.x2_button)  cell_size_delta += 1;

            if cell_size_delta {
                cell_size_index = clamp(cell_size_index + cell_size_delta, 0, cell_sizes.count - 1);
                cell_size_changed = true;
            }
        }

        // Same with the keyboard, make sure GUI isn't using it first.
        if !gui_has_keyboard() && was_clicked(keyboard.escape)  should_quit = true;

        do_simulate := (life_running || life_run_for_one_step) && application_has_focus;
        if life_run_for_one_step {
            life_running = false;
            life_run_for_one_step = false;
        }

        screen_width := application_panel.calculated_rect.w;
        screen_height := application_panel.calculated_rect.h;

        for x: 0 .. cells_width - 1 {
            for y: 0 .. cells_height - 1 {
                cell := get_cell(x, y);
                alive := is_alive(cell);
                neighbour_count := get_neighbour_count(x, y);
                alpha := 1.0;
                size := 1.0;

                if do_simulate && !temporary_pause {
                    if alive {
                        set_cell_life_next_frame(cell, neighbour_count == 2 || neighbour_count == 3);
                        fill_extra_bits(cell);
                    }
                    else {
                        set_cell_life_next_frame(cell, neighbour_count == 3);
                    }
                }
                else {
                    set_cell_life_next_frame(cell, alive);
                    if alive  fill_extra_bits(cell);
                }

                if !alive {
                    alpha = 0;
                    state, extra_value := get_cell_sections(cell);
                    if extra_value {
                        if do_simulate {
                            extra_value -= 1;
                            cell.* = state | (extra_value & .EXTRA_BITS_MASK);
                        }

                        if show_trail {
                            alpha = (cast(float) extra_value) / cast(float) (1 << 10);
                            size =  min(1.0, (cast(float) extra_value) / cast(float) (1 << 9));
                        }
                    }
                }

                grid_width := cells_width * cell_size;
                grid_height := cells_height * cell_size;

                screen_x := wrap(cast(float)x * cell_size + draw_offset.x, 0, grid_width);
                screen_y := wrap(cast(float)y * cell_size + draw_offset.y, 0, grid_height);

                if alpha {
                    color := Vector4.{1.0, 1.0, 1.0, alpha};
                    shrink := (1 - size) * cell_size / 4;
                    side_length := cell_size - 2*shrink - 1;
                    draw_box(Rect.{screen_x + shrink, screen_y + shrink, side_length, side_length}, color);

                    wrapped_x := screen_x - grid_width;
                    if -cell_size < wrapped_x && wrapped_x < 0
                        draw_box(Rect.{wrapped_x, screen_y, side_length, side_length}, color);

                    wrapped_y := screen_y - grid_height;
                    if -cell_size < wrapped_y && wrapped_y < 0
                        draw_box(Rect.{screen_x, wrapped_y, side_length, side_length}, color);

                    if -cell_size < wrapped_x && wrapped_x < 0 && -cell_size < wrapped_y && wrapped_y < 0
                        draw_box(Rect.{wrapped_x, wrapped_y, side_length, side_length}, color);
                }
            }
        }

        // Step 7.  You can add widgets directly without using a window; do it after you've drawn your game so they appear on top.
        //          (We could move this section to after gui_draw_windows to have it draw on top of them too!)
        if showing_gui {
            quit_icon := Icon_Id.CLOSE;
            if button(at_size(-big_widget_size-big_margin,big_margin, big_widget_size,big_widget_size), quit_icon)  should_quit = true;
        }

        // Step 8.  Call gui_draw_windows after you've drawn your scene to draw all your windows on top.
        gui_draw_windows();

        if !application_has_focus  sleep_milliseconds(100);  // Don't hog the CPU if we're not active.
    }
}

get_cell :: inline (x: int, y: int) -> *Cell {
    if x < 0 || x >= cells_width || y < 0 || y >= cells_height
        return null;

    index := x * cells_height + y;
    return *cells[index];
}

is_alive :: inline (cell: *Cell) -> bool {
    return (cell.* & cast(Cell)(1 << active_cell_parity)) != 0;
}

set_cell_life_this_frame :: (cell: *Cell, alive: bool) {
    bit := cast(Cell) 1 << active_cell_parity;
    if alive  cell.* |= bit;
    else      cell.* &= ~bit;
}

set_cell_life_next_frame :: (cell: *Cell, alive: bool) {
    bit := cast(Cell) 1 << (1 - active_cell_parity);
    if alive  cell.* |= bit;
    else      cell.* &= ~bit;
}

cell_exists_and_is_alive_count :: inline (x: int, y: int) -> int {
    if wrap_world {
        if x < 0 then x = cells_width - 1;
        else if x >= cells_width then x = 0;

        if y < 0 then y = cells_height - 1;
        else if y >= cells_height then y = 0;
    }
    cell := get_cell(x, y);
    return ifx cell && is_alive(cell) then 1 else 0;
}

get_neighbour_count :: (x: int, y: int) -> int {
    count := 0;
    count += cell_exists_and_is_alive_count(x-1, y-1);
    count += cell_exists_and_is_alive_count(x,   y-1);
    count += cell_exists_and_is_alive_count(x+1, y-1);
    count += cell_exists_and_is_alive_count(x-1, y  );
    count += cell_exists_and_is_alive_count(x+1, y  );
    count += cell_exists_and_is_alive_count(x-1, y+1);
    count += cell_exists_and_is_alive_count(x,   y+1);
    count += cell_exists_and_is_alive_count(x+1, y+1);
    return count;
}

fill_extra_bits :: inline (cell: *Cell) {
    cell.* |= .EXTRA_BITS_MASK;
}

get_cell_sections :: inline (cell: *Cell) -> state: Cell, extra_value: Cell {
    return cell.* & ~.EXTRA_BITS_MASK, cell.* & .EXTRA_BITS_MASK;
}

check_for_grid_resize :: () {
    if cell_size_changed {
        cell_size = cell_sizes[cell_size_index];
        cell_size_changed = false;
    }
    new_cells_width := cast(int) (application_panel.calculated_rect.w / cell_size) + 1;
    new_cells_height := cast(int) (application_panel.calculated_rect.h / cell_size) + 1;

    if new_cells_width != cells_width || new_cells_height != cells_height {
        new_cells := NewArray(new_cells_width * new_cells_height, Cell);
        if cells.data {
            max_width := min(cells_width, new_cells_width) - 1;
            max_height := min(cells_height, new_cells_height) - 1;
            for x: 0 .. max_width {
                for y: 0 .. max_height {
                    new_index := x * new_cells_height + y;
                    old_index := x * cells_height + y;
                    new_cells[new_index] = cells[old_index];
                }
            }
            free(cells.data);
        }
        cells = new_cells;
        cells_width = new_cells_width;
        cells_height = new_cells_height;

        if randomize_grid_on_startup {
            randomize_grid_on_startup = false;
            random_fill_cells();
        }
    }
}

clear_cells :: () {
    memset(cells.data, 0, cells.count);
}

random_fill_cells :: () {
    for x: 0 .. cells_width - 1 {
        for y: 0 .. cells_height - 1 {
            cell := get_cell(x, y);
            set_cell_life_next_frame(cell, random_get() % 2 != 0);
        }
    }
}

wrap :: (x: $T, min: T, limit: T) -> T
#modify {
    return (cast(*Type_Info)T).type == .FLOAT;
} {
    size := limit - min;
    x = fmod_cycling(x, size);
    x += min;
    return x;
}

wrap :: (x: $T, min: T, limit: T) -> T
#modify {
    return (cast(*Type_Info)T).type == .INTEGER;
} {
    size := limit - min;
    x -= min;
    x %= size;
    x += min;
    if x < min  x += size;
    return x;
}