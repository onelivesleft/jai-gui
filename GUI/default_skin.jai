// @Note This is a very simple default skin.  If you want to make your own skin then
//       you must export a version of all the procs which this file exports - everything
//       after #scope_export below.  You must also export a Theme struct and the `themes`
//       array.  Your Theme struct does not have to include all the members this one does,
//       though it does need to include some of them: generally speaking, any colors or text
//       sizes in this theme are not required, but things which specify a default size
//       (like `padding`) likely will be.
//       It'll be easy to work out as the compiler will complain about any members you fail
//       to declare.


theme := Theme.{};

Theme :: struct {
    padding := 4;

    background_color := Color.{0.2, 0.2, 0.2, 1.0};

    window_background :=          Color.{0.3, 0.3, 0.3, 0.7};
    window_foreground_focussed := Color.{0.65, 0.65, 0.85, 1.0};
    window_foreground_warm :=     Color.{0.45, 0.45, 0.65, 1.0};
    window_draggable_border_size : s16 = 1;

    window_decoration_background :=         Color.{0.35, 0.35, 0.55, 1.0};
    window_decoration_background_clicked := Color.{0.65, 0.65, 0.85, 1.0};
    window_decoration_background_hot :=     Color.{0.55, 0.55, 0.75, 1.0};
    window_decoration_background_warm :=    Color.{0.45, 0.45, 0.65, 1.0};
    window_decoration_foreground :=         Color.{1.0, 1.0, 1.0, 1.0};
    window_decoration_scrollbar_groove_background :=      Color.{0.35, 0.25, 0.25, 1.0};
    window_decoration_scrollbar_handle_background :=      Color.{0.55, 0.35, 0.35, 1.0};
    window_decoration_scrollbar_handle_background_hot :=  Color.{0.75, 0.55, 0.55, 1.0};
    window_decoration_scrollbar_handle_background_warm := Color.{0.65, 0.45, 0.45, 1.0};
    window_decoration_scrollbar_size : s16 = 16;
    window_decoration_size : s16 = 32;
    window_decoration_text_size : s16 = 16;

    application_window_decoration_background :=         Color.{0.35, 0.55, 0.55, 1.0};
    application_window_decoration_background_clicked := Color.{0.65, 0.85, 0.85, 1.0};
    application_window_decoration_background_hot :=     Color.{0.55, 0.75, 0.75, 1.0};
    application_window_decoration_background_warm :=    Color.{0.45, 0.65, 0.65, 1.0};
    application_window_decoration_size : s16 = 32;

    tooltip_background :=   Color.{1.0, 1.0, 1.0, 1.0};
    tooltip_border_color := Color.{0.0, 0.0, 0.0, 1.0};
    tooltip_foreground   := Color.{0.0, 0.0, 0.0, 1.0};
    tooltip_border := 2;
    tooltip_offset := Vector2.{20, 20};
    tooltip_max_width := 500.0;
    tooltip_delay := 0.5;
    tooltip_text_size : s16 = 14;

    label_foreground := Color.{1.0, 1.0, 1.0, 1.0};
    label_text_size : s16 = 16;

    icon_color := Color.{1.0, 1.0, 1.0, 1.0};
    icon_size := 64;

    button_background :=         Color.{0.55, 0.35, 0.35, 1.0};
    button_background_clicked := Color.{0.85, 0.65, 0.65, 1.0};
    button_background_hot :=     Color.{0.75, 0.55, 0.55, 1.0};
    button_background_warm :=    Color.{0.65, 0.45, 0.45, 1.0};
    button_foreground :=         Color.{1.0, 1.0, 1.0, 1.0};
    button_text_size : s16 = 16;

    checkbox_border := 2;
    checkbox_text_size : s16 = 16;

    cursor_color := Color.{1.0, 1.0, 1.0, 1.0};
    selection_color := Color.{0.7, 0.7, 0.7, 1.0};

    input_line_border_color :=         Color.{0.55, 0.35, 0.35, 1.0};
    input_line_background :=           Color.{0.35, 0.25, 0.25, 1.0};
    input_line_background_read_only := Color.{0.15, 0.10, 0.10, 1.0};
    input_line_background_hot :=       Color.{0.45, 0.35, 0.35, 1.0};
    input_line_background_warm :=      Color.{0.45, 0.35, 0.35, 1.0};
    input_line_foreground :=           Color.{1.0, 1.0, 1.0, 1.0};
    input_line_foreground_read_only := Color.{1.0, 1.0, 1.0, 0.75};
    input_line_border := 2;
    input_line_text_size : s16 = 16;

    scrollbar_groove_background :=      Color.{0.35, 0.25, 0.25, 1.0};
    scrollbar_handle_background :=      Color.{0.55, 0.35, 0.35, 1.0};
    scrollbar_handle_background_hot :=  Color.{0.75, 0.55, 0.55, 1.0};
    scrollbar_handle_background_warm := Color.{0.65, 0.45, 0.45, 1.0};
    scrollbar_min_handle_size := 1.0 / 40;
    scrollbar_acceleration := 0.5;
    scrollbar_size := 20;

    input_box_text_size : s16 = 16;
    input_box_row_height := 20;

    data_table_background_warm := Color.{0.75, 0.55, 0.55, 1.0};
    data_table_foreground_warm := Color.{0.1, 0.1, 0.1, 1.0};
    data_table_row_height := 30;
}

alternate_theme := Theme.{
    padding = 4,

    background_color = Color.{0.2, 0.2, 0.2, 1.0},

    window_background =          Color.{0.4, 0.3, 0.3, 0.7},
    window_foreground_focussed = Color.{0.65, 0.65, 0.85, 1.0},
    window_foreground_warm =     Color.{0.45, 0.45, 0.65, 1.0},
    window_draggable_border_size = 2,

    window_decoration_background         = Color.{0.35, 0.55, 0.55, 1.0},
    window_decoration_background_clicked = Color.{0.65, 0.85, 0.85, 1.0},
    window_decoration_background_hot     = Color.{0.55, 0.75, 0.75, 1.0},
    window_decoration_background_warm    = Color.{0.45, 0.65, 0.65, 1.0},
    window_decoration_foreground         = Color.{1.0, 1.0, 1.0, 1.0},
    window_decoration_scrollbar_groove_background =      Color.{0.25, 0.35, 0.25, 1.0},
    window_decoration_scrollbar_handle_background =      Color.{0.35, 0.55, 0.35, 1.0},
    window_decoration_scrollbar_handle_background_hot =  Color.{0.55, 0.75, 0.55, 1.0},
    window_decoration_scrollbar_handle_background_warm = Color.{0.45, 0.65, 0.45, 1.0},
    window_decoration_scrollbar_size = 16,
    window_decoration_size = 32,
    window_decoration_text_size = 16,

    application_window_decoration_background =         Color.{0.35, 0.55, 0.55, 1.0},
    application_window_decoration_background_clicked = Color.{0.65, 0.85, 0.85, 1.0},
    application_window_decoration_background_hot =     Color.{0.55, 0.75, 0.75, 1.0},
    application_window_decoration_background_warm =    Color.{0.45, 0.65, 0.65, 1.0},
    application_window_decoration_size = 32,

    tooltip_background = Color.{0.55, 0.35, 0.35, 1.0},
    tooltip_foreground = Color.{1.0, 1.0, 1.0, 1.0},
    tooltip_offset = Vector2.{20, 20},
    tooltip_max_width = 500.0,
    tooltip_delay = 0.5,
    tooltip_text_size = 14,

    label_foreground = Color.{1.0, 1.0, 1.0, 1.0},
    label_text_size = 16,

    icon_color = Color.{1.0, 1.0, 1.0, 1.0},
    icon_size = 64,

    button_background =          Color.{0.35, 0.55, 0.35, 1.0},
    button_background_clicked =  Color.{0.65, 0.85, 0.65, 1.0},
    button_background_hot =      Color.{0.55, 0.75, 0.55, 1.0},
    button_background_warm =     Color.{0.45, 0.65, 0.45, 1.0},
    button_foreground =          Color.{1.0, 1.0, 1.0, 1.0},
    button_text_size = 16,

    checkbox_border = 2,
    checkbox_text_size = 16,

    cursor_color = Color.{1.0, 1.0, 1.0, 1.0},
    selection_color = Color.{0.7, 0.7, 0.7, 1.0},

    input_line_border_color =         Color.{0.55, 0.35, 0.35, 1.0},
    input_line_background =           Color.{0.35, 0.25, 0.25, 1.0},
    input_line_background_read_only = Color.{0.15, 0.10, 0.10, 1.0},
    input_line_background_hot =       Color.{0.45, 0.35, 0.35, 1.0},
    input_line_background_warm =      Color.{0.45, 0.35, 0.35, 1.0},
    input_line_foreground =           Color.{1.0, 1.0, 1.0, 1.0},
    input_line_foreground_read_only = Color.{1.0, 1.0, 1.0, 0.75},
    input_line_border = 2,
    input_line_text_size = 16,

    scrollbar_groove_background =      Color.{0.25, 0.35, 0.25, 1.0},
    scrollbar_handle_background =      Color.{0.35, 0.55, 0.35, 1.0},
    scrollbar_handle_background_hot =  Color.{0.55, 0.75, 0.55, 1.0},
    scrollbar_handle_background_warm = Color.{0.45, 0.65, 0.45, 1.0},
    scrollbar_min_handle_size = 1.0 / 40,
    scrollbar_acceleration = 1.0,
    scrollbar_size = 20,

    input_box_text_size = 16,
    input_box_row_height = 20,

    data_table_background_warm = Color.{0.75, 0.55, 0.55, 1.0},
    data_table_foreground_warm = Color.{0.1, 0.1, 0.1, 1.0},
    data_table_row_height = 30,
};

locked_theme := Theme.{
    window_decoration_background = Color.{0.5, 0.5, 0.5, 1.0},
    window_decoration_foreground = Color.{0.9, 0.9, 0.9, 1.0},

    button_background = Color.{0.4, 0.4, 0.4, 1.0},
    button_foreground = Color.{0.9, 0.9, 0.9, 1.0},

    label_foreground = Color.{1.0, 1.0, 1.0, 1.0},

    input_line_border_color = Color.{0.4, 0.4, 0.4, 1.0},
    input_line_background   = Color.{0.3, 0.3, 0.3, 1.0},

    scrollbar_groove_background = Color.{0.3, 0.3, 0.3, 1.0},
    scrollbar_handle_background = Color.{0.4, 0.4, 0.4, 1.0},
};

theme_b, theme_c : Theme;

themes : [4] *type_of(theme) : .[*theme, *alternate_theme, *theme_b, *theme_c];


#scope_module;


Font :: Simp.Dynamic_Font;

font_sans_data ::  #run global_data(FONT_SANS);
font_serif_data :: #run global_data(FONT_SERIF);
font_fixed_data :: #run global_data(FONT_FIXED);
font_sans_alternate_data ::  #run global_data(FONT_SANS_ALTERNATE);
font_serif_alternate_data :: #run global_data(FONT_SERIF_ALTERNATE);
font_fixed_alternate_data :: #run global_data(FONT_FIXED_ALTERNATE);
font_icons_data :: #run global_data(FONT_ICONS);
font_data :: string.[font_sans_data, font_sans_data, font_serif_data, font_fixed_data, font_sans_alternate_data, font_serif_alternate_data, font_fixed_alternate_data, font_icons_data];

Font_Identifier :: struct {
    style: Font_Style;
    pixel_height: s16;

    #place style;
    hash: u32;
}

font_cache : Table(u32, *Font);

global_data :: (filename: string) -> (memory: string, success: bool) #compile_time {
    if !filename  return "", true;

    compiler :: #import "Compiler";
    file :: #import "File";

    full_name := ifx contains(filename, "/")
                 then filename
                 else tprint("%data/%", #filepath, filename);

    file_data, success := file.read_entire_file(full_name);
    if !success {
        compiler.compiler_report(tprint("Compile-time loading of '%' failed!\n", full_name), mode=.ERROR);
        return "", false;
    }

    return cast(string) file_data, true;
}

#scope_export

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
    hot_height := font.character_height * 0.55;
    pad := height - hot_height;

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
    y := application_panel.calculated_rect.h - (r.y + r.h - vert);

    // Due to atlassed texture rendering, we draw text at integer coordinates currently.
    // If we wish to change this, don't round! (Or round to whatever subpixel resolution
    // we generate atlas alternatives at. etc.)
    x = floor(x + .5);
    y = floor(y + .5);
    return x, y;
}

#scope_file

find_glyph_index_in_simp_temporary_glyphs :: (font: *Simp.Dynamic_Font, point: Vector2) -> glyph_index: int {
    // Returns character index for edge nearest point.
    // So, left side of first char = index 0, right side of first char == lef size of second char == 1, etc.
    // If point is entirely left of text returns -1, if entirely right of text returns count+1 (since
    // right edge of last character will be count).

    // @TODO binary search

    convert_to_simp_point :: (point: Vector2) -> Vector2 {
        result : Vector2 = ---;
        result.x = point.x;
        result.y = application_panel.calculated_rect.h - point.y;
        return result;
    }

    simp_point := convert_to_simp_point(point);
    if !font.current_quads || simp_point.x < font.current_quads[0].p0.x
        return -1;

    for font.current_quads {
        bottom_left := it.p0;
        top_right := it.p2;
        mid_point := (bottom_left.x + top_right.x) / 2;
        if mid_point > simp_point.x
            return it_index;
    }

    last_quad := font.current_quads[font.current_quads.count - 1];
    if last_quad.p2.x >= simp_point.x  return font.current_quads.count;

    return font.current_quads.count + 1;
}

gl_vec4 :: (rect: Rect) -> Color {
    return .{rect.x, application_panel.calculated_rect.h - rect.y - rect.h, rect.x + rect.w, application_panel.calculated_rect.h - rect.y};
}

clamp_to_window :: (v: *Color) {
    Clamp(*v.x, 0, application_panel.calculated_rect.w);
    Clamp(*v.y, 0, application_panel.calculated_rect.h);
    Clamp(*v.z, v.x, application_panel.calculated_rect.w);
    Clamp(*v.w, v.y, application_panel.calculated_rect.h);
}


scissor_stack: [..] Rect;

set_scissor :: (rect: Rect) {
    v4 := gl_vec4(rect);
    clamp_to_window(*v4);
    Simp.set_scissor(xx v4.x, xx v4.y, xx v4.z, xx v4.w);
}

push_scissor :: (rect: Rect) {
    r := rect;

    if scissor_stack {
        top := peek_pointer(scissor_stack);
        r = intersect(top.*, r);
    }

    set_scissor(r);
    array_add(*scissor_stack, r);
}

pop_scissor :: () {
    Simp.immediate_flush();
    pop(*scissor_stack);

    if scissor_stack {
        r := peek(scissor_stack);
        set_scissor(r);
    } else {
        Simp.clear_scissor();
    }
}

draw_rect :: (rect: Rect, color: Color) {
    v4 := gl_vec4(rect);
    Simp.immediate_quad(v4.x, v4.y, v4.z, v4.w, color);
}


draw_triangles :: (position: Vector2, rotation: float, triangles: [] Triangle, color: Color) {
    c := cos(rotation);
    s := sin(rotation);
    t : Triangle;
    for triangle: triangles {
        for i: 0..2 {
            t.points[i].x = triangle.points[i].x * c - triangle.points[i].y * s + position.x;
            t.points[i].y = triangle.points[i].x * s + triangle.points[i].y * c + position.y;
        }
        immediate_triangle(t, color);
    }
}

immediate_triangle :: inline (triangle: Triangle, color: Color) {
    Simp.immediate_triangle(triangle.p0, triangle.p1, triangle.p2, color, color, color);
}

Triangle :: struct {
    p0: Vector3;
    p1: Vector3;
    p2: Vector3;

    #place p0;
    points : [3] Vector3;
}


switch_theme :: () #expand {
    `theme := ifx is_locked(`flags) then locked_theme else themes[theme_index(`flags)];
}


get_quad :: (r: Rect, snap_coordinates := false) -> (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) {
    v4 := gl_vec4(r);
    p0 := Vector2.{v4.x, v4.y};
    p1 := Vector2.{v4.z, v4.y};
    p2 := Vector2.{v4.z, v4.w};
    p3 := Vector2.{v4.x, v4.w};

    if snap_coordinates {
        p0.x = floor(p0.x + .5);
        p0.y = floor(p0.y + .5);
        p1.x = floor(p1.x + .5);
        p1.y = floor(p1.y + .5);
        p2.x = floor(p2.x + .5);
        p2.y = floor(p2.y + .5);
        p3.x = floor(p3.x + .5);
        p3.y = floor(p3.y + .5);
    }

    return p0, p1, p2, p3;
}


// @TODO Ideally we'd only bake in the icons we used, but we can't do that with #no_reset, and we
//       don't want to require a build metaprogram.  If #no_reset gets an upgrade we can revisit this.
//       For now we'll just bake in the entire icon atlas...

icon_bitmap_atlas : Simp.Bitmap;
icon_bitmap_atlas_bytes :: #run -> string {
    path := join(#filepath, "data/material_design_icons.png");
    file :: #import "File";
    file_data, ok := file.read_entire_file(path);
    assert(ok);
    return cast(string)file_data;
}

Icon_Bitmap_Bytes :: [ICON_SHEET_ICON_SIZE * ICON_SHEET_ICON_SIZE * 4] u8;

make_icon_bitmap :: (using bitmap: *Simp.Bitmap, bytes: *Icon_Bitmap_Bytes, icon_index: int) {
    width = ICON_SHEET_ICON_SIZE;
    height = ICON_SHEET_ICON_SIZE;
    stride = ICON_SHEET_ICON_SIZE * 4;
    format = .RGBA8;
    data.data = bytes.data;
    data.count = bytes.count;

    bytes_index := 0;
    size :: ICON_SHEET_ICON_SIZE * ICON_SHEET_ICON_SIZE;
    for i: 0 .. size - 1 {
        i_row := i / ICON_SHEET_ICON_SIZE;
        i_col := i % ICON_SHEET_ICON_SIZE;
        sheet_row := ICON_SHEET_ICON_SIZE * (icon_index / ICON_SHEET_COLUMN_COUNT) + i_row;
        sheet_col := ICON_SHEET_ICON_SIZE * (icon_index % ICON_SHEET_COLUMN_COUNT) + i_col;
        sheet_index := sheet_row * icon_bitmap_atlas.stride + sheet_col;
        bytes.*[bytes_index+0] = 0xff;
        bytes.*[bytes_index+1] = 0xff;
        bytes.*[bytes_index+2] = 0xff;
        bytes.*[bytes_index+3] = icon_bitmap_atlas.data[sheet_index];
        bytes_index += 4;
    }
}

get_icon_texture :: (icon_id: Icon_Id) -> *Simp.Texture {
    index := icon_index_from_icon_id[icon_id];
    texture : *Simp.Texture = ---;
    if index {
        texture = *icon_textures[index - 1];
    }
    else {
        texture = array_add(*icon_textures);
        icon_index_from_icon_id[icon_id] = xx icon_textures.count;
        bitmap : Simp.Bitmap;
        bytes : Icon_Bitmap_Bytes;
        make_icon_bitmap(*bitmap, *bytes, xx icon_id);
        Simp.texture_load_from_bitmap(texture, *bitmap);
        assert(texture != null);
    }
    return texture;
}

icon_textures: [..] Simp.Texture;
icon_index_from_icon_id : [#run enum_values_as_s64(Icon_Id).count] u16;


#scope_module


init_skin :: () {
    Simp.bitmap_load_from_memory(*icon_bitmap_atlas, xx icon_bitmap_atlas_bytes);
}


application_window_resize :: (new_width: int, new_height: int, old_width: int, old_height: int) { }


draw_window :: ($mode: enum { BACKGROUND; FOREGROUND; }) -> border: *Panel {
    window := currently_drawing_window;
    theme := ifx is_locked(window.flags) then locked_theme else themes[theme_index(window.flags)];

    border := at(window);
    if window.flags & (.CLOSE|.TITLE_BAR)  border = grow(border, theme.window_decoration_size, .UP);
    if window.flags & .SCROLLBARS          border = grow(border, theme.window_decoration_scrollbar_size, .RIGHT|.DOWN);

    #if mode == .BACKGROUND {
        border = grow(border, theme.window_draggable_border_size, .ALL);
        draw_box(border, theme.window_background);
    }
    else #if mode == .FOREGROUND {
        inherited_flags := window.flags & xx window_decoration_inherit_mask;

        title_bar_row, panel := split_top_bottom(border, theme.window_decoration_size);

        if window.flags & .CLOSE {
            title_bar_row=, close_button := split_left_right(title_bar_row, -theme.window_decoration_size);
            window_decoration(close_button, .CLOSE | inherited_flags);
        }

        if window.flags & .TITLE_BAR {
            window_decoration(title_bar_row, .TITLE_BAR | inherited_flags);
        }

        if window.flags & (.SCROLLBARS | .RESIZE) {
            _, tr, bl, br := split_quadrants(panel, -theme.window_decoration_scrollbar_size, -theme.window_decoration_scrollbar_size);

            if window.flags & .SCROLLBARS {
                window_decoration(bl, .SCROLLBAR_HORIZONTAL | inherited_flags);
                window_decoration(tr, .SCROLLBAR_VERTICAL | inherited_flags);
            }

            if window.flags & .RESIZE {
                window_decoration(br, .RESIZE | inherited_flags);
            }
        }

        border = grow(border, theme.window_draggable_border_size, .ALL);

        if window == warm_window || window == focussed_window {
            color := ifx window == focussed_window then theme.window_foreground_focussed else theme.window_foreground_warm;
            draw_outline(border, color, cast(float) theme.window_draggable_border_size);
        }
    }


    return border;
}

draw_window_decoration :: (using window_decoration: *Window_Decoration) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    if flags & .CLOSE {
        window_decoration_rect := shrink(calculated_rect, 0, 0, 0, 0);
        with_scissor(window_decoration_rect, flags);
        Simp.set_shader_for_color(true);

        color := ifx currently_drawing_window == focussed_window then theme.window_foreground_focussed else theme.window_foreground_warm;
        draw_rect(window_decoration_rect, color);

        texture := get_icon_texture(.CLOSE_OUTLINE);

        advance := window_decoration_rect.h - theme.padding;
        icon_rect := shrink(window_decoration_rect, theme.padding);
        if !(flags & .ICON_ON_RIGHT)
            window_decoration_rect.x += advance;
        window_decoration_rect.w -= advance;

        if flags & .ICON_ON_RIGHT
            icon_rect.x += icon_rect.w - icon_rect.h;
        else
            icon_rect.x += (icon_rect.h - icon_rect.w) / 2;
        icon_rect.w = icon_rect.h;

        p0, p1, p2, p3 := get_quad(icon_rect);
        Simp.set_shader_for_images(texture);
        Simp.immediate_quad(p0, p1, p2, p3, theme.icon_color);
        Simp.immediate_flush();
        return;
    }

    if flags & .TITLE_BAR {
        window_decoration_rect := shrink(calculated_rect, 0, 0, 0, 0);
        with_scissor(window_decoration_rect, flags);
        Simp.set_shader_for_color(true);

        color := ifx currently_drawing_window == focussed_window then theme.window_foreground_focussed else theme.window_foreground_warm;
        draw_rect(window_decoration_rect, color);

        if currently_drawing_window.text {
            text_rect := shrink(window_decoration_rect, theme.padding);
            font, text_width := get_font(sans_font(flags), theme.window_decoration_text_size, currently_drawing_window.text, fit_width(text_rect, flags));

            text_x, text_y := text_origin(center_align(flags), font, text_rect, text_width);
            Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.window_decoration_foreground);
        }

        return;
    }

    if flags & (.SCROLLBAR_HORIZONTAL | .SCROLLBAR_VERTICAL) {
        scrollbar := ifx flags & .SCROLLBAR_HORIZONTAL
                     then *currently_drawing_window._horizontal_scrollbar
                     else *currently_drawing_window._vertical_scrollbar;
        scrollbar.panel = window_decoration.panel;
        maybe_calculate_rect(scrollbar);

        Simp.set_shader_for_color(true);
        with_scissor(scrollbar.calculated_rect, flags);

        draw_rect(scrollbar.calculated_rect, theme.window_decoration_scrollbar_groove_background);

        _, handle_rect, _ : = get_scrollbar_rects(scrollbar);
        color := hot_warm_else(scrollbar, theme.window_decoration_scrollbar_handle_background_hot, theme.window_decoration_scrollbar_handle_background_warm, theme.window_decoration_scrollbar_handle_background);
        draw_rect(shrink(handle_rect, 1), color);

        return;
    }

    if flags & .RESIZE {
        window_decoration_rect := shrink(calculated_rect, 0, 0, 1, 1);
        with_scissor(window_decoration_rect, flags);
        Simp.set_shader_for_color(true);

        color := ifx was_clicked(window_decoration)
                 then theme.window_decoration_background_clicked
                 else warm_hot_else(window_decoration, theme.window_decoration_background_hot, theme.window_decoration_background_warm, theme.window_decoration_background);
        texture := get_icon_texture(.RESIZE_BOTTOM_RIGHT);

        p0, p1, p2, p3 := get_quad(window_decoration_rect);
        Simp.set_shader_for_images(texture);
        Simp.immediate_quad(p0, p1, p2, p3, theme.icon_color);
        Simp.immediate_flush();
        return;
    }

    if flags & .MOVE {
        window_decoration_rect := shrink(calculated_rect, 0, 0, 1, 1);
        with_scissor(window_decoration_rect, flags);
        Simp.set_shader_for_color(true);
        color := ifx was_clicked(window_decoration)
                 then theme.window_decoration_background_clicked
                 else warm_hot_else(window_decoration, theme.window_decoration_background_hot, theme.window_decoration_background_warm, theme.window_decoration_background);
        draw_rect(window_decoration_rect, color);
        return;
    }
}

draw_application_window_decoration :: (using application_window_decoration: *Application_Window_Decoration) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    application_window_decoration_rect := calculated_rect;
    with_scissor(application_window_decoration_rect, flags);
    Simp.set_shader_for_color(true);
    color := ifx was_clicked(application_window_decoration)
             then theme.application_window_decoration_background_clicked
             else warm_hot_else(application_window_decoration, theme.application_window_decoration_background_hot, theme.application_window_decoration_background_warm, theme.application_window_decoration_background);
    draw_rect(application_window_decoration_rect, color);
}

draw_tooltip :: (using widget: *Widget) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    font, text_width := get_font(.SERIF, theme.tooltip_text_size, tooltip);
    width := min(theme.tooltip_max_width, text_width + theme.padding * 2);
    text_rect := Rect.{mouse.x + theme.tooltip_offset.x, mouse.y + theme.tooltip_offset.y, width, xx theme.tooltip_text_size };
    tooltip_rect := expand(text_rect, (theme.tooltip_border + theme.padding) * 2);
    if tooltip_rect.x + tooltip_rect.w > application_panel.calculated_rect.w
        tooltip_rect.x -= (tooltip_rect.w + theme.tooltip_offset.x);
    if tooltip_rect.y + tooltip_rect.h > application_panel.calculated_rect.h
        tooltip_rect.y -= tooltip_rect.h;

    Simp.set_shader_for_color(true);
    with_scissor(tooltip_rect);
    draw_rect(tooltip_rect, theme.tooltip_border_color);
    tooltip_rect = shrink(tooltip_rect, theme.tooltip_border);
    draw_rect(tooltip_rect, theme.tooltip_background);
    text_rect = shrink(tooltip_rect, theme.padding);

    with_scissor(text_rect);
    text_x, text_y := text_origin(.CENTER, font, text_rect, text_width);
    Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.tooltip_foreground);
}

draw_button :: (using button: *Button) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    button_rect := shrink(calculated_rect, 0, 0, 1, 1);
    with_scissor(button_rect, flags);
    Simp.set_shader_for_color(true);

    color := ifx was_clicked(button)
             then theme.button_background_clicked
             else warm_hot_else(button, theme.button_background_hot, theme.button_background_warm, theme.button_background);
    draw_rect(button_rect, color);

    if icon_id {
        texture := get_icon_texture(icon_id);

        advance := button_rect.h - theme.padding;
        icon_rect := shrink(button_rect, theme.padding);
        if !(flags & .ICON_ON_RIGHT)
            button_rect.x += advance;
        button_rect.w -= advance;

        if flags & .ICON_ON_RIGHT
            icon_rect.x += icon_rect.w - icon_rect.h;
        else if !text
            icon_rect.x += (icon_rect.h - icon_rect.w) / 2;
        icon_rect.w = icon_rect.h;

        p0, p1, p2, p3 := get_quad(icon_rect);
        Simp.set_shader_for_images(texture);
        Simp.immediate_quad(p0, p1, p2, p3, theme.icon_color);
        Simp.immediate_flush();
    }

    if text {
        text_rect := shrink(button_rect, theme.padding);
        font, text_width := get_font(sans_font(flags), theme.button_text_size, text, fit_width(text_rect, flags));

        text_x, text_y := text_origin(center_align(flags), font, text_rect, text_width);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.button_foreground);
    }
}

draw_label :: (using label: *Label) {
    assert(calculated_rect_frame_index == frame.index);
    if !text  return;

    switch_theme();

    label_rect := shrink(calculated_rect, 0, 0, 1, 1);
    label_rect = shrink(label_rect, theme.padding);
    with_scissor(label_rect, flags);

    font, width := get_font(sans_font(flags), theme.label_text_size, text, fit_width(label_rect, flags));
    text_width = width;

    text_x, text_y := text_origin(left_align(flags), font, label_rect, text_width);
    Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.label_foreground);
}

draw_icon :: (using icon: *Icon) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    icon_rect := shrink(calculated_rect, 0, 0, 1, 1);
    icon_rect = shrink(icon_rect, theme.padding);
    with_scissor(icon_rect, flags);

    texture := get_icon_texture(icon.icon_id);

    if !(flags & .FIT) {
        size := ifx icon_size else theme.icon_size;
        icon_rect.y += icon_rect.h / 2;
        icon_rect.h = xx size;
        icon_rect.y -= icon_rect.h / 2;
        w := icon_rect.w;
        icon_rect.w = xx size;
        align := center_align(flags);
        if align == {
            case .CENTER;  icon_rect.x += (w - icon_rect.w) / 2;
            case .RIGHT;   icon_rect.x += w - icon_rect.w;
        }
    }

    p0, p1, p2, p3 := get_quad(icon_rect);
    Simp.set_shader_for_images(texture);
    Simp.immediate_quad(p0, p1, p2, p3, theme.icon_color);
    Simp.immediate_flush();
}

draw_scrollbar :: (using scrollbar: *Scrollbar) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    Simp.set_shader_for_color(true);
    with_scissor(calculated_rect, flags);

    draw_rect(calculated_rect, theme.scrollbar_groove_background);

    _, handle_rect, _ : = get_scrollbar_rects(scrollbar);
    color := hot_warm_else(scrollbar, theme.scrollbar_handle_background_hot, theme.scrollbar_handle_background_warm, theme.scrollbar_handle_background);
    draw_rect(shrink(handle_rect, 1), color);
}

draw_checkbox :: (using checkbox: *Checkbox) {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    checkbox_rect := shrink(calculated_rect, 0, 0, 1, 1);
    with_scissor(checkbox_rect, flags);
    Simp.set_shader_for_color(true);

    color := warm_hot_else(checkbox, theme.button_background_warm, theme.button_background_hot, theme.button_background);
    box_rect, text_rect : Rect = ---;
    if flags & .RIGHT
        text_rect, box_rect = split_left_right(checkbox_rect, -checkbox_rect.h);
    else
        box_rect, text_rect = split_left_right(checkbox_rect, checkbox_rect.h);

    draw_rect(box_rect, color);
    box_rect = shrink(box_rect, theme.checkbox_border);
    draw_rect(box_rect, theme.background_color);

    icon_rect := shrink(box_rect, theme.checkbox_border);
    if value  draw_rect(icon_rect, color);
    if icon_id  draw_icon(icon_rect, icon_id, theme.icon_color);

    if text {
        text_rect = shrink(text_rect, theme.padding);
        font, text_width := get_font(sans_font(flags), theme.checkbox_text_size, text, fit_width(text_rect, flags));

        text_x, text_y := text_origin(left_align(flags), font, text_rect, text_width);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.button_foreground);
    }
}

draw_input_line :: (using input_line: *Input_Line, $query_character_index := false, query_point := Vector2.{}) -> character_index: int {
    assert(calculated_rect_frame_index == frame.index);

    switch_theme();

    border_rect := shrink(calculated_rect, 0, 0, 1, 1);
    input_line_rect := shrink(border_rect, theme.input_line_border);
    with_scissor(border_rect, flags);

    character_index: int;

    Simp.set_shader_for_color(true);
    draw_rect(border_rect, theme.input_line_border_color);
    color := warm_hot_else(input_line, theme.input_line_background_warm, theme.input_line_background_hot, ifx flags & .READ_ONLY then theme.input_line_background_read_only else theme.input_line_background);
    draw_rect(input_line_rect, color);

    if !has_focus(input_line) {
        if !text  return 0;

        text_rect := shrink(input_line_rect, theme.padding);
        with_scissor(text_rect, flags);
        font, text_width := get_font(sans_font(flags), theme.input_line_text_size, text, fit_width(text_rect, flags));

        text_x, text_y := text_origin(left_align(flags), font, text_rect, text_width);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, ifx flags.READ_ONLY then theme.input_line_foreground_read_only else theme.input_line_foreground);
        #if query_character_index
            character_index = find_glyph_index_in_simp_temporary_glyphs(font, query_point);
        return character_index;
    }

    text_rect := shrink(input_line_rect, theme.padding);
    cursor_rect : Rect = ---;
    font, text_width := get_font(sans_font(flags), theme.input_line_text_size, text_edit.before_cursor, 0);
    {
        with_scissor(text_rect, flags);
        text_edit.cursor_x = ifx text_width < text_rect.w then text_width else text_rect.w / 2;

        left_rect, right_rect := split_left_right(text_rect, text_edit.cursor_x);
        cursor_rect = right_rect;
        text_x, text_y := text_origin(.RIGHT, font, left_rect, text_width);

        has_selection := text_edit_selection();
        if has_selection {
            s := text_edit.as_string;
            s.count = text_edit.select_anchor;
            _, selection_x := get_font(sans_font(flags), theme.input_line_text_size, s, 0);
            selection_x += text_x;

            selection_rect := right_rect;
            if selection_x > right_rect.x {
                selection_rect.w = selection_x - right_rect.x;
            }
            else {
                selection_rect.x = selection_x;
                selection_rect.w = right_rect.x - selection_x;
            }
            Simp.set_shader_for_color(true);
            draw_rect(selection_rect, theme.selection_color);
        }

        font, text_width = get_font(sans_font(flags), theme.input_line_text_size, text_edit.as_string, 0);
        Simp.draw_prepared_text(font, xx text_x, xx text_y, ifx flags.READ_ONLY then theme.input_line_foreground_read_only else theme.input_line_foreground);
        #if query_character_index
            character_index = find_glyph_index_in_simp_temporary_glyphs(font, query_point);
    }

    if !query_character_index { // If we're querying character index we don't know where the cursor is.
        cursor_rect.x -= 1;
        cursor_rect.w = 2;
        Simp.set_shader_for_color(true);
        draw_rect(cursor_rect, theme.cursor_color);
    }

    return character_index;
}

draw_data_table :: (using data_table: *Data_Table) {
    if !first_label_on_warm_row && !first_label_on_selected_row  return;

    switch_theme();

    with_scissor(data_table.calculated_rect);

    highlight_row :: (first_label_on_row: *Label, color: Color) #expand {
        if !first_label_on_row  return;
        last_label_on_row := first_label_on_row + visible_columns - 1;
        row_rect := first_label_on_row.calculated_rect;
        row_rect.w = last_label_on_row.calculated_rect.x + last_label_on_row.calculated_rect.w - first_label_on_row.calculated_rect.x;
        Simp.set_shader_for_color(true);
        draw_rect(row_rect, color);

        label := first_label_on_row;
        while label <= last_label_on_row {
            label_rect := shrink(label.calculated_rect, 0, 0, 1, 1);
            label_rect = shrink(label_rect, theme.padding);
            with_scissor(label_rect, label.flags);

            font, text_width := get_font(sans_font(label.flags), theme.label_text_size, label.text, fit_width(label_rect, label.flags));

            text_x, text_y := text_origin(left_align(label.flags), font, label_rect, text_width);
            Simp.draw_prepared_text(font, xx text_x, xx text_y, theme.data_table_foreground_warm);
            label += 1;
        }
    }

    if first_label_on_selected_row != first_label_on_warm_row
        highlight_row(first_label_on_selected_row, theme.selection_color);
    highlight_row(first_label_on_warm_row, theme.data_table_background_warm);
}

draw_scrollable_panel :: (using scrollable_panel: *Scrollable_Panel) { }

draw_input_box :: (using input_box: *Input_Box) { }


bite_text_line_for_width :: (text: string, default_font: Font_Style, size: s16, flags: Flags, width: int) -> line: string, remainder: string {
    if !text  return "", "";

    remainder := text;
    line := text;
    line.count = 1 + trailing_utf8_bytes[text[0]];
    if line[0] == #char "\n" {
        advance(*remainder, 1);
        return line, remainder;
    }

    font_style := font_style_from_flags(flags, default_font);
    font, text_width := get_font(sans_font(flags), size, text, 0);

    while line.count < text.count {
        c := text[line.count];

        if c == #char "\n" {
            line.count += 1;
            break;
        }

        if width && get_text_width(font, line) > width
            break;

        line.count += 1 + trailing_utf8_bytes[c];
    }

    if line.count > text.count
        line.count = text.count;
    advance(*remainder, line.count);

    return line, remainder;
}


widget_became_warm_time ::     (widget: *Widget, time: float64) { }
widget_lost_warm_time ::       (widget: *Widget, time: float64) { }
widget_became_hot_time ::      (widget: *Widget, time: float64) { }
widget_lost_hot_time ::        (widget: *Widget, time: float64) { }
widget_became_focussed_time :: (widget: *Widget, time: float64) { }
widget_lost_focus_time ::   (widget: *Widget, time: float64) { }
widget_was_clicked_time ::     (widget: *Widget, time: float64) { }
widget_was_released_time ::    (widget: *Widget, time: float64) { }
widget_was_changed_time ::     (widget: *Widget, time: float64) { }

window_became_warm_time ::     (window: *Window, time: float64) { }
window_lost_warm_time ::       (window: *Window, time: float64) { }
window_became_focussed_time :: (window: *Window, time: float64) { }
window_lost_focus_time ::   (window: *Window, time: float64) { }


#scope_export

with_scissor :: (panel: *Panel) #expand {
    maybe_calculate_rect(panel);
    push_scissor(panel.calculated_rect);
    `defer pop_scissor();
}

with_scissor :: (rect: Rect) #expand {
    push_scissor(rect);
    `defer pop_scissor();
}

with_scissor :: (rect: Rect, flags: Flags) #expand {
    do_scissor := should_scissor(flags);
    if do_scissor  push_scissor(rect);
    `defer if do_scissor  pop_scissor();
}

push_scissor :: (rect: Rect, flags: Flags) {
    do_scissor := should_scissor(flags);
    // @Note we always push something if the stack isn't empty, so the user can always unthinkingly pop
    if do_scissor
        push_scissor(rect);
    else if scissor_stack
        push_scissor(peek(scissor_stack));
}

maybe_pop_scissor :: () {
    if scissor_stack  pop_scissor();
}

peek_scissor :: () -> *Rect {
    if scissor_stack  return *scissor_stack[scissor_stack.count - 1];
    else              return null;
}

is_fully_visible :: (rect: Rect) -> bool {
    maybe_calculate_rect(*application_panel);
    r := intersect(application_panel.calculated_rect, rect);
    scissor := peek_scissor();
    if scissor  r = intersect(scissor.*, r);
    return r == rect;
}

is_fully_visible :: (panel: *Panel) -> bool {
    maybe_calculate_rect(panel);
    return inline is_fully_visible(panel.calculated_rect);
}

is_partially_visible :: (rect: Rect) -> bool {
    maybe_calculate_rect(*application_panel);
    r := intersect(application_panel.calculated_rect, rect);
    scissor := peek_scissor();
    if scissor  r = intersect(scissor.*, r);
    return r.w > 0 && r.h > 0;
}

is_partially_visible :: (panel: *Panel) -> bool {
    maybe_calculate_rect(panel);
    return inline is_partially_visible(panel.calculated_rect);
}

clear_window :: () {
    Simp.clear_render_target(theme.background_color.x, theme.background_color.y, theme.background_color.z, theme.background_color.w);

}


draw_box :: inline (panel: *Panel, color: Color) {
    rect := calculate_rect(panel);
    draw_box(rect, color);
}

draw_box :: (rect: Rect, color: Color) {
    Simp.set_shader_for_color(true);
    draw_rect(rect, color);
}

draw_outline :: inline (panel: *Panel, color: Color, size := 1.0, flags := Sides.ALL) {
    rect := calculate_rect(panel);
    draw_outline(rect, color, size, flags);
}

Sides :: enum_flags {
    TOP; LEFT; RIGHT; BOTTOM;
    ALL :: TOP|LEFT|RIGHT|BOTTOM;
}

draw_outline :: (rect: Rect, color: Color, size := 1.0, flags := Sides.ALL) {
    Simp.set_shader_for_color(true);
    if flags & .TOP     draw_rect(.{rect.x, rect.y, rect.w - size, size}, color);
    if flags & .RIGHT   draw_rect(.{rect.x + rect.w - size, rect.y, size, rect.h - size}, color);
    if flags & .LEFT    draw_rect(.{rect.x, rect.y + size, size, rect.h - size}, color);
    if flags & .BOTTOM  draw_rect(.{rect.x + size, rect.y + rect.h - size, rect.w - size, size}, color);
}

get_text_width :: (font: *Font, s: string) -> width: s64 {
    return Simp.prepare_text(font, s);
}

draw_text :: (panel: *Panel, text: string, color: Color, size : s16 = 0, align := Text_Alignment.CENTER, font_style := Font_Style.SANS) -> text_width: float {
    rect := calculate_rect(panel);
    return inline draw_text(rect, text, color, size, align, font_style);
}

draw_text :: (rect: Rect, text: string, color: Color, size : s16 = 0, align := Text_Alignment.CENTER, font_style := Font_Style.SANS) -> text_width: float {
    if !size  size = theme.label_text_size;
    font, text_width := get_font(font_style, size, text);
    text_x, text_y := text_origin(align, font, rect, text_width);
    Simp.draw_prepared_text(font, xx text_x, xx text_y, color);
    return text_width;
}

draw_icon :: (panel: *Panel, icon_id: Icon_Id, color: Color) {
    rect := calculate_rect(panel);
    inline draw_icon(rect, icon_id, color);
}

draw_icon :: (rect: Rect, icon_id: Icon_Id, color: Color) {
    texture := get_icon_texture(icon_id);
    p0, p1, p2, p3 := get_quad(rect);
    Simp.set_shader_for_images(texture);
    Simp.immediate_quad(p0, p1, p2, p3, color);
    Simp.immediate_flush();
}

draw_line :: (x0: $T, y0: T, x1: T, y1: T, color: Color) {
    triangles : [2] Triangle;
    stroke_width :: 2;
    triangles[0].p0 = Vector3.{x0, y0, 0};
    triangles[0].p1 = Vector3.{x1, y1, 0};
    triangles[0].p2 = Vector3.{x1 + stroke_width, y1 + stroke_width, 0};
    triangles[1].p0 = Vector3.{x0, y0, 0};
    triangles[1].p1 = Vector3.{x1, y1, 0};
    triangles[1].p2 = Vector3.{x0 + stroke_width, y0 + stroke_width, 0};
    draw_triangles(Vector2.{0, 0}, 0, triangles, color);
}

draw_line :: inline (p0: Vector2, p1: Vector2, color: Color) {
    draw_line(p0.x, p0.y, p1.x, p1.y, color);
}