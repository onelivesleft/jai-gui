#import "GUI";
#import "Basic";
#import "Math";
#import "Random";

initial_width :: 1024;
initial_height :: 1024;
initial_cell_size_index :: 4;
cell_sizes :: float.[2, 3, 4, 5, 6, 8, 10, 16, 24, 32, 48, 64, 96, 128];
cell_size := cell_sizes[initial_cell_size_index];

Cell :: enum_flags u8 {
    PARITY_0_BIT :: 0;
    PARITY_1_BIT :: 1;
    PARITY_0_STATE :: 1 << PARITY_0_BIT;
    PARITY_1_STATE :: 1 << PARITY_1_BIT;
    EXTRA_BITS_MASK :: ~(PARITY_0_STATE|PARITY_1_STATE);
};

cells: [] Cell;
cells_width: int;
cells_height: int;
active_cell_parity := Cell.PARITY_0_BIT;

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

main :: () {
    // Step 1.  Create OS window
    application_panel = gui_create_application_window("GUI Example", initial_width, initial_height);

    // Step 2.  Loop until quit
    while true {
        // Step 3.  Call gui_begin_frame at the start of every frame.
        should_quit := gui_begin_frame();

        if !gui_has_keyboard() && keyboard.escape  should_quit = true;
        if should_quit  break;

        check_for_grid_resize();

        draw_controls :: (window: *Window) {
            control_count :: 4;
            controls, settings := split_left_right(window, big_widget_size*control_count + big_margin*(control_count+1));

            {
                with_panel(controls);
                with_spacing(big_margin);

                play_pause_icon := ifx life_running then Icon_Id.PLAY else .PAUSE;
                checkbox(at(big_margin,big_margin, big_margin+big_widget_size,-big_margin), play_pause_icon, *life_running);

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

                cell_size_index, cell_size_scrollbar := horizontal_scrollbar(at(.FILL_RIGHT), initial_cell_size_index, .{0, cell_sizes.count - 1}, .REVERSE_SCROLLWHEEL);
                cell_size = cell_sizes[cell_size_index];
                if !gui_has_mouse()  use_scrollwheel(cell_size_scrollbar);
            }
        }
        controls_window := window(draw_controls, "Controls", at(10,10, 400,52), .CAN_MOVE);

        active_cell_parity = (Cell.PARITY_0_BIT + .PARITY_1_BIT) - active_cell_parity;

        mouse_cell_x := wrap(cast(int) ((mouse.x - draw_offset.x) / cell_size), 0, cells_width);
        mouse_cell_y := wrap(cast(int) ((mouse.y - draw_offset.y) / cell_size), 0, cells_height);

        if !gui_has_mouse() {
            if mouse.left_button_start {
                cell := get_cell(mouse_cell_x, mouse_cell_y);
                if cell  mouse_is_drawing_alive_cells = !is_alive(cell);
            }

            if mouse.left_button_held {
                temporary_pause = true;
                cell := get_cell(mouse_cell_x, mouse_cell_y);
                drawing_alive_cells := mouse_is_drawing_alive_cells;
                if mouse.right_button_held  drawing_alive_cells = !drawing_alive_cells;
                if cell  set_cell_life_this_frame(cell, drawing_alive_cells);
            }
            else {
                temporary_pause = false;
                if mouse.right_button_start  controls_window.is_open = !controls_window.is_open;
            }

            if mouse.middle_button_held {
                draw_offset.x += mouse.dx;
                draw_offset.y += mouse.dy;
            }
        }

        do_simulate := life_running || life_run_for_one_step;
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

                        if show_trail
                            alpha = (cast(float) extra_value) / cast(float) (1 << 10);
                    }
                }

                screen_x := wrap(cast(float)x * cell_size + draw_offset.x, 0, screen_width);
                screen_y := wrap(cast(float)y * cell_size + draw_offset.y, 0, screen_height);

                if alpha {
                    draw_box(Rect.{screen_x, screen_y, cell_size - 1, cell_size - 1}, .{1.0, 1.0, 1.0, alpha});
                    if screen_x > screen_width - cell_size
                        draw_box(Rect.{screen_x - screen_width, screen_y, cell_size - 1, cell_size - 1}, .{1.0, 1.0, 1.0, alpha});
                    if screen_y > screen_height - cell_size
                        draw_box(Rect.{screen_x, screen_y - screen_height, cell_size - 1, cell_size - 1}, .{1.0, 1.0, 1.0, alpha});
                    if screen_x > screen_width - cell_size && screen_y > screen_height - cell_size
                        draw_box(Rect.{screen_x - screen_width, screen_y - screen_height, cell_size - 1, cell_size - 1}, .{1.0, 1.0, 1.0, alpha});
                }
            }
        }

        // Step 4.  Call gui_draw_windows after you've drawn your scene to draw all your windows on top.
        gui_draw_windows();
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

wrap :: (x: $T, min: T, max: T) -> T {
    size := max - min;
    while x < min  x += size;
    while x > max  x -= size;
    return x;
}