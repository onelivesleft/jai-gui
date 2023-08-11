theme := Theme.{};

Theme :: struct {
    padding := 4;

    background_color := Vector4.{0.2, 0.2, 0.2, 1.0};

    tooltip_background   := Vector4.{1.0, 1.0, 1.0, 1.0};
    tooltip_border_color := Vector4.{0.0, 0.0, 0.0, 1.0};
    tooltip_foreground   := Vector4.{0.0, 0.0, 0.0, 1.0};
    tooltip_border := 2;
    tooltip_offset := Vector2.{20, 20};
    tooltip_max_width := 500.0;
    tooltip_delay := 0.5;
    tooltip_text_size : s16 = 14;


    label_foreground := Vector4.{1.0, 1.0, 1.0, 1.0};
    label_text_size : s16 = 16;

    button_background        := Vector4.{0.55, 0.35, 0.35, 1.0};
    button_background_active := Vector4.{0.65, 0.45, 0.45, 1.0};
    button_background_hot    := Vector4.{0.75, 0.55, 0.55, 1.0};
    button_foreground        := Vector4.{1.0, 1.0, 1.0, 1.0};
    button_text_size : s16 = 16;

    checkbox_border := 2;
    checkbox_text_size : s16 = 16;

    scrollbar_groove_background        := Vector4.{0.35, 0.25, 0.25, 1.0};
    scrollbar_handle_background        := Vector4.{0.55, 0.35, 0.35, 1.0};
    scrollbar_handle_background_active := Vector4.{0.75, 0.55, 0.55, 1.0};
    scrollbar_handle_background_hot    := Vector4.{0.65, 0.45, 0.45, 1.0};
    scrollbar_size := 20;
}

alternate_theme := Theme.{
    padding = 4,

    background_color = Vector4.{0.2, 0.2, 0.2, 1.0},

    tooltip_background = Vector4.{0.55, 0.35, 0.35, 1.0},
    tooltip_foreground = Vector4.{1.0, 1.0, 1.0, 1.0},
    tooltip_offset = Vector2.{20, 20},
    tooltip_max_width = 500.0,
    tooltip_delay = 0.5,
    tooltip_text_size = 14,

    label_foreground = Vector4.{1.0, 1.0, 1.0, 1.0},
    label_text_size = 16,

    button_background        = Vector4.{0.35, 0.55, 0.35, 1.0},
    button_background_active = Vector4.{0.45, 0.65, 0.45, 1.0},
    button_background_hot    = Vector4.{0.55, 0.75, 0.55, 1.0},
    button_foreground        = Vector4.{1.0, 1.0, 1.0, 1.0},
    button_text_size = 16,

    checkbox_border = 2,
    checkbox_text_size = 16,

    scrollbar_groove_background        = Vector4.{0.25, 0.35, 0.25, 1.0},
    scrollbar_handle_background        = Vector4.{0.35, 0.55, 0.35, 1.0},
    scrollbar_handle_background_active = Vector4.{0.55, 0.75, 0.55, 1.0},
    scrollbar_handle_background_hot    = Vector4.{0.45, 0.65, 0.45, 1.0},
    scrollbar_size = 20,

};

locked_theme := Theme.{
    button_background        = Vector4.{0.4, 0.4, 0.4, 1.0},
    button_foreground        = Vector4.{0.9, 0.9, 0.9, 1.0},

    label_foreground = Vector4.{1.0, 1.0, 1.0, 1.0},

    scrollbar_groove_background        = Vector4.{0.3, 0.3, 0.3, 1.0},
    scrollbar_handle_background        = Vector4.{0.4, 0.4, 0.4, 1.0},
};

themes : [4] *type_of(theme) : .[*theme, *alternate_theme, *theme, *theme];


#scope_file;


Font :: Simp.Dynamic_Font;

font_sans_data ::  #run global_data("Montreal-Regular.ttf");
font_serif_data :: #run global_data("CharisSIL-R.ttf");
font_fixed_data :: #run global_data("FantasqueSansMono-Regular.ttf");
font_data :: string.[font_sans_data, font_sans_data, font_serif_data, font_fixed_data];

Font_Identifier :: struct {
    style: Font_Style;
    pixel_height: s16;

    #place style;
    hash: u32;
}

font_cache : Table(u32, *Font);

global_data :: (filename: string) -> (memory: string, success: bool) {
    compiler :: #import "Compiler";  // We are not currently restricting this to compile-time, hmm.
    file :: #import "File";      // We should do that somehow.

    full_name := tprint("%data/%", #filepath, filename);

    file_data, success := file.read_entire_file(full_name);
    if !success {
        compiler.compiler_report(tprint("Compile-time loading of '%' failed!\n", full_name), mode=.ERROR);
        return "", false;
    }

    return cast(string) file_data, true;
}

get_font :: (style: Font_Style, pixel_height: s16) -> *Font {
    id := Font_Identifier.{style, pixel_height};
    font, found := table_find(*font_cache, id.hash);

    if !found {
        font = Simp.get_font_at_size(cast([] u8)font_data[style], pixel_height);
        table_set(*font_cache, id.hash, font);
    }

    return font;
}

get_font :: (style: Font_Style, pixel_height: s16, text: string, fit_width := 0.0) -> *Font, width: float {
    font := get_font(style, pixel_height);
    width := cast(float) Simp.prepare_text(font, text);
    if !fit_width || width <= fit_width
        return font, width;

    min_pixel_height :: 4;
    low_size : s16 = min_pixel_height;
    high_size : s16 = pixel_height;

    while low_size + 1 < high_size {
        size : s16 = (low_size + high_size) / 2;
        font = get_font(style, size);
        width = cast(float) Simp.prepare_text(font, text);

        if width <= fit_width  low_size = size;
        else                   high_size = size;
    }

    if width > fit_width {
        font = get_font(style, low_size);
        width = cast(float) Simp.prepare_text(font, text);
    }

    return font, width;
}

default_text_baseline :: (font: *Font, height: float) -> float {
    if !font return 0;  // :NullFont Handle incomplete implementation via the user passing us null for a font.
    // Just a heuristic to try to line up fonts, kind of.
    // Could probably be better.
    active_height := font.character_height * 0.55;
    pad := height - active_height;

    return floor(pad * 0.5);
}

text_origin :: (alignment: Text_Alignment, font: *Font, r: Rect, text_width: float) -> (x: float, y: float) {
    if !font return 0, 0;  // :NullFont

    // theme.font is ignored, so that people can pass in a substituted font.
    // However, other properties like alignment, baseline, etc are used here.

    x := r.x;

    if #complete alignment == {
        case .DEFAULT; #through;
        case .LEFT;

        case .CENTER;
        x += (r.w - text_width) * 0.5;

        case .RIGHT;
        x += (r.w - text_width);
    }

    // y := text_baseline(font, y, y+r.h);
    vert := default_text_baseline(font, r.h);
    y := window_panel.rect.h - (r.y + r.h - vert);

    // Due to atlassed texture rendering, we draw text at integer coordinates currently.
    // If we wish to change this, don't round! (Or round to whatever subpixel resolution
    // we generate atlas alternatives at. etc.)
    x = floor(x + .5);
    y = floor(y + .5);
    return x, y;
}


gl_vec4 :: (rect: Rect) -> Vector4 {
    return .{rect.x, window_panel.rect.h - rect.y - rect.h, rect.x + rect.w, window_panel.rect.h - rect.y};
}

clamp_to_window :: (v: *Vector4) {
    Clamp(*v.x, 0, window_panel.rect.w);
    Clamp(*v.y, 0, window_panel.rect.h);
    Clamp(*v.z, v.x, window_panel.rect.w);
    Clamp(*v.w, v.y, window_panel.rect.h);
}


scissor_stack: [..] Rect;

set_scissor :: (rect: Rect) {
    v4 := gl_vec4(rect);
    clamp_to_window(*v4);
    Simp.set_scissor(xx v4.x, xx v4.y, xx v4.z, xx v4.w);
}

push_scissor :: (_rect: Rect) {
    rect := _rect;

    if scissor_stack {
        top := peek_pointer(scissor_stack);
        rect = intersect(top.*, rect);
    }

    set_scissor(rect);
    array_add(*scissor_stack, rect);
}

pop_scissor :: () {
    pop(*scissor_stack);

    if scissor_stack {
        r := peek(scissor_stack);
        set_scissor(r);
    } else {
        Simp.clear_scissor();
    }
}

scissor :: (rect: Rect) #expand {
    push_scissor(rect);
    `defer pop_scissor();
}

scissor :: (rect: Rect, flags: Widget_Flags) #expand {
    scissoring := !(flags & .OVERFLOW) || (flags & .CROP);
    if scissoring  push_scissor(rect);
    `defer if scissoring  pop_scissor();
}

draw_rect :: (rect: Rect, color: Vector4) {
    v4 := gl_vec4(rect);
    Simp.immediate_quad(v4.x, v4.y, v4.z, v4.w, color);
}

switch_theme :: () #expand {
    `theme := ifx `flags & .LOCKED then locked_theme else themes[theme_index(`flags)];
}

#scope_export


clear_window :: () {
    Simp.clear_render_target(theme.background_color.x, theme.background_color.y, theme.background_color.z, theme.background_color.w);

}

draw_tooltip :: (using widget: *Widget) {
    assert(rect_frame_count == frame_count);

    switch_theme();

    font, text_width := get_font(.SERIF, theme.tooltip_text_size, tooltip);
    width := min(theme.tooltip_max_width, text_width + theme.padding * 2);
    text_rect := Rect.{mouse_x + theme.tooltip_offset.x, mouse_y + theme.tooltip_offset.y, width, xx theme.tooltip_text_size };
    tooltip_rect := expand(text_rect, (theme.tooltip_border + theme.padding) * 2);
    if tooltip_rect.x + tooltip_rect.w > window_panel.rect.w
        tooltip_rect.x -= (tooltip_rect.w + theme.tooltip_offset.x);
    if tooltip_rect.y + tooltip_rect.h > window_panel.rect.h
        tooltip_rect.y -= tooltip_rect.h;

    Simp.set_shader_for_color();
    scissor(tooltip_rect);
    draw_rect(tooltip_rect, theme.tooltip_border_color);
    tooltip_rect = shrink(tooltip_rect, theme.tooltip_border);
    draw_rect(tooltip_rect, theme.tooltip_background);
    text_rect = shrink(tooltip_rect, theme.padding);

    scissor(text_rect);
    text_x, text_y := text_origin(.CENTER, font, text_rect, text_width);
    Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.tooltip_foreground);
}

draw_button :: (using button: *Button) {
    assert(rect_frame_count == frame_count);

    switch_theme();

    button_rect := shrink(rect, 1);
    scissor(button_rect, flags);
    Simp.set_shader_for_color();

    color := hot_active_else(button, theme.button_background_hot, theme.button_background_active, theme.button_background);
    draw_rect(button_rect, color);

    if text {
        text_rect := shrink(button_rect, theme.padding);
        font, text_width := get_font(sans_font(flags), theme.button_text_size, text, fit_width(text_rect, flags));

        text_x, text_y := text_origin(center_align(flags), font, text_rect, text_width);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.button_foreground);
    }
}

draw_label :: (using label: *Label) {
    assert(rect_frame_count == frame_count);
    if !text  return;

    switch_theme();

    label_rect := shrink(rect, 1);
    scissor(label_rect, flags);
    Simp.set_shader_for_color();

    font, text_width := get_font(sans_font(flags), theme.label_text_size, text, fit_width(label_rect, flags));

    text_x, text_y := text_origin(left_align(flags), font, label_rect, text_width);
    Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.label_foreground);
}

draw_scrollbar :: (using scrollbar: *Scrollbar) {
    assert(rect_frame_count == frame_count);

    switch_theme();

    Simp.set_shader_for_color();
    scissor(rect, flags);

    draw_rect(rect, theme.scrollbar_groove_background);

    _, handle_rect, _ : = get_scrollbar_rects(scrollbar);
    color := active_hot_else(scrollbar, theme.scrollbar_handle_background_active, theme.scrollbar_handle_background_hot, theme.scrollbar_handle_background);
    draw_rect(shrink(handle_rect, 1), color);
}

draw_checkbox :: (using checkbox: *Checkbox) {
    assert(rect_frame_count == frame_count);

    switch_theme();

    checkbox_rect := shrink(rect, 1);
    scissor(checkbox_rect, flags);
    Simp.set_shader_for_color();

    color := hot_active_else(checkbox, theme.button_background_hot, theme.button_background_active, theme.button_background);
    box_rect, text_rect : Rect = ---;
    if flags & .RIGHT
        text_rect, box_rect = split_left_right(checkbox_rect, -checkbox_rect.h);
    else
        box_rect, text_rect = split_left_right(checkbox_rect, checkbox_rect.h);

    draw_rect(box_rect, color);
    box_rect = shrink(box_rect, theme.checkbox_border);
    draw_rect(box_rect, theme.background_color);

    _value := ifx is_active(checkbox) && is_hot(checkbox) then !value else value;
    if _value {
        box_rect = shrink(box_rect, theme.checkbox_border);
        draw_rect(box_rect, color);
    }

    if text {
        text_rect = shrink(text_rect, theme.padding);
        font, text_width := get_font(sans_font(flags), theme.checkbox_text_size, text, fit_width(text_rect, flags));

        text_x, text_y := text_origin(left_align(flags), font, text_rect, text_width);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.button_foreground);
    }
}
