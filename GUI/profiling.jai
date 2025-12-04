// TODO
// [ ] Background color
// [x] Pause
// [.] Keyboard Controls
// [.] Mouse Controls
// [ ] Window/Screen
// [x] Position it in the right place
// [ ] Fix text columns
// [x] Graph

#if is_iprof_attached {
    iprof_window: *Window;
    iprof_window_called_this_frame: bool;

    iprof_config := context._Iprof.Config.{
        line_spacing = 0,
        font_character_height = 0,
        draw_text = iprof_draw_text,
        text_width = iprof_text_width,
        draw_rectangle = iprof_draw_rectangle,
        graph_begin = iprof_graph_bookend_dummy,
        graph_end = iprof_graph_bookend_dummy,
        draw_line = iprof_draw_line,
        text_y_offset = -4,
        selected_bar_whiten_amount = 0.1,
    };

    iprof_font: *Simp.Dynamic_Font;
    iprof_show_graph := true;

    iprof_rect: Rect;
    iprof_widget_index := 0;
    iprof_clicked_widget_index := -1;
    iprof_warm_widget_index := -1;

    iprof_set_font_size :: (font_size: int, line_spacing := 0) {
        iprof_config.font_character_height = cast(s32) font_size;
        iprof_config.line_spacing = cast(s32) ifx line_spacing else font_size + 4;
        iprof_font = get_font(.FIXED, cast(s16) iprof_config.font_character_height);
    }

    iprof_update :: () {
        iprof_window_called_this_frame = false;
        context._Iprof.update(iprof_recording);
    }


    iprof_mode_cycle :: () {
        mode := (context._Iprof.displayed_quantity + 1) % .CALL_GRAPH;
        context._Iprof.set_report_mode(mode);
    }

    iprof_up :: () {
        context._Iprof.move_cursor(-1);
    }

    iprof_down :: () {
        context._Iprof.move_cursor(+1);
    }

    iprof_select :: () {
        context._Iprof.select();
    }

    iprof_back :: () {
        context._Iprof.select_parent();
    }

    iprof_recording := true;
    iprof_frame_lock :: () {
        iprof_recording = !iprof_recording;
    }

    iprof_prev_frame :: () {
        iprof_move_frame(-1);
    }

    iprof_next_frame :: () {
        iprof_move_frame(+1);
    }

    iprof_move_frame :: (delta: int) {
        context._Iprof.move_frame(delta);
    }

    iprof_graph_bookend_dummy :: (x: float, y: float, width: float, height: float) { }


    iprof_text_width :: (text: string) -> float {
        return cast(float) get_text_width(iprof_font, text);
    }

    iprof_convert :: (p: Vector2, flip_y := false) -> Vector2 {
        if flip_y  return .{iprof_rect.x + p.x, (application_panel.calculated_rect.h - iprof_rect.y) + p.y};
        else       return .{iprof_rect.x + p.x, iprof_rect.y + p.y};
    }

    // Iprof.draw_graph and Iprof.draw are not bound by the position given to them (they use it as a different corner origin,
    // and Iprof.draw draws its header on the other side of it) so we need to micromanage an offset to get it to draw where
    // we want. Hack!
    iprof_vertical_offset := 0;

    iprof_draw_rectangle :: (x0: float, y0: float, x1: float, y1: float, color: Color) {
        p0 := iprof_convert(Vector2.{min(x0, x1), min(y0, y1)});
        p1 := iprof_convert(Vector2.{max(x0, x1), max(y0, y1)});
        rect := Rect.{p0.x, p0.y, p1.x - p0.x, p1.y - p0.y};
        rect.y += iprof_vertical_offset;

        // To get input back out of iprof we make a widget whenever it draws a rect. After the call
        // to Iprof.draw, iprof_clicked_widget_index will be set to >= 0 if something was clicked.
        // 0 = main header, 1 = columns header, 2+ = a data row.
        // Fragile!
        iprof_widget_index += 1;
        row := widget(iprof_widget_index, at(*application_panel, rect));
        if is_warm(row)  iprof_warm_widget_index = iprof_widget_index;
        if was_clicked(row)  iprof_clicked_widget_index = iprof_widget_index;

        Simp.set_shader_for_color(true);
        draw_rect(rect, color);
    }

    iprof_draw_text :: (x: float, y: float, str: string, color: Color) {
        p := iprof_convert(.{x, y});
        Simp.prepare_text(iprof_font, str);
        Simp.draw_text(iprof_font, xx (iprof_rect.x + x), xx (application_panel.calculated_rect.h - y - iprof_rect.y) - iprof_vertical_offset, str, color);
    }

    iprof_draw_line :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, color: Color) {
        Simp.set_shader_for_color(true);
        draw_line(iprof_convert(p0, true), iprof_convert(p1, true), color);
        draw_line(iprof_convert(p1, true), iprof_convert(p2, true), color);
        draw_line(iprof_convert(p2, true), iprof_convert(p3, true), color);
        //draw_line(iprof_convert(p3), iprof_convert(p0), color);
    }


    iprof_draw_window :: (window: *Window) {
        iprof_rect = window.virtual_panel.calculated_rect;
        iprof_rect.w = window.calculated_rect.w;
        iprof_rect.h = 999999;

        if !iprof_font  iprof_set_font_size(12, 16);

        reset_iprof_widgets :: () #expand {
            iprof_widget_index = -1;
            iprof_warm_widget_index = -1;
            iprof_clicked_widget_index = -1;
        }

        {
            reset_iprof_widgets();
            iprof_vertical_offset = 2 + iprof_config.line_spacing;
            with_scissor(iprof_rect);
            context._Iprof.draw(0, 0, iprof_rect.w, iprof_rect.h, *iprof_config);

            if iprof_warm_widget_index >= 0  iprof_move_frame(mouse.scrollwheel);

            if      iprof_clicked_widget_index == 0  iprof_frame_lock(); // main header
            else if iprof_clicked_widget_index == 1  iprof_mode_cycle(); // columns header
            else if iprof_clicked_widget_index >= 2 {
                context._Iprof.set_cursor(iprof_clicked_widget_index - 2);
                iprof_select();
            }
        }

        /*
        if iprof_show_graph {
            reset_iprof_widgets();
            iprof_vertical_offset = xx iprof_rect.h;
            iprof_rect.y += iprof_rect.h; // Hacky way to fix graph drawing in weird place.
            with_scissor(iprof_rect);
            context._Iprof.draw_graph(0, 0, iprof_rect.w, iprof_rect.h, *iprof_config);
        }
        */
    }
}