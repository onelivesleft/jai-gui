// @Note GUI provides a simple but powerful layout engine to allow you to quickly and easily
//       describe your UI widget positions.  The two core concepts you need to understand
//       are the Ord, and the At_Location/Panel.
//
//       An Ord is a position along a single axis, formed of two parts: rel and abs.
//         rel: a float specifying the position relative to the widget's parent,
//              0.0 = left or top edge of parent
//              1.0 = right or bottom edge of parent
//         abs: a +/- pseudo-pixel offset from rel
//
//       Any time you need to specify an ord you can call an ord() constructor, but almost
//       all procs that take an ord (including the ord() constructor) will allow you to pass
//       in either an Ord, an int, or a float: if you pass in a float it will make .{f, 0},
//       if you pass in an int it will make either .{0.0, i) or .{1.0, i}, depending on whether
//       i is postive or negative.  i.e.  if you say `ord(-100)` you will get a .{1.0, -100},
//       something 100 pixels left of the right edge (or 100 pixels up from the bottom edge).
//       Two Ords bundled together form a Coord - an x/y pair.  Two Coords formed together form
//       a Box: a top-left Coord and a bottom-right Coord.
//
//       At_Location and Panel both refer to the same construct, which is a Box and a parent.
//       You can think of At_Location as the adjective, and Panel as the noun.  Whenever you
//       want to describe a location for your widget, you will use an At_Location (generally
//       by calling `at(...)`).  Sometimes you'll want to use a free-standing location as the
//       parent to other widgets: for this you will create a Panel.  This duality is just for
//       user-understanding, the two types are the same type.  Here is some code to demonstrate:
//
//          sidebar_panel, main_panel := split_left_right(window, 0.3);
//          label(at_top(sidebar_panel, 20), "The Program");
//          data_table(at(main_panel), my_array);
//
//      In the above, the `0.3` and the `20` are Ords (for a relative left/right partition and
//       an absolute label height, respectively).
//      `split_left_right` produces two Panels, while `at_top` and `at` produce an At_Location,
//      but all four entities do the same thing: describe a rectangular space inside your window.

// @Note All the positioning procs below are macros:  We want to treat widgets as Panels, so
//       everything in GUI works using a *At_Location/*Panel parameter.  In order for the procs
//       below (like `at` and `split_left_right`) to generate data on the stack but still return
//       a pointer they are all macros.


At_Location :: struct {
    parent: *At_Location;
    _box: Box;
    rect: Rect;
    rect_frame_count: int;
}

Panel :: At_Location;


is_implicit_ord :: inline (T) => (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);


at :: (parent: *At_Location) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, BOX_FILLED, .{}, 0 };
    return *location;
}

at :: (parent: *At_Location, tlx: $T, tly: $U, brx: $V, bry: $W) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W);
} {
    location := At_Location.{ parent, .{ coord(tlx, tly), coord(brx, bry) }, .{}, 0};
    return *location;
}

at :: (tlx: $T, tly: $U, brx: $V, bry: $W) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W);
} {
    return at(peek_panel(), tlx, tly, brx, bry);
}

at :: (parent: *At_Location, _box: Box) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, _box, .{}, 0 };
    return *location;
}

at :: (_box: Box) -> *At_Location #expand #no_debug {
    return at(peek_panel(), _box);
}

at :: (parent: *At_Location, auto_place: Placement) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, box(auto_place), .{}, 0 };
    return *location;
}

at :: (auto_place: Placement) -> *At_Location #expand #no_debug {
    return at(peek_panel(), auto_place);
}


at_top :: (parent: *At_Location, _ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(parent, 0,0, 1.0,ord(_ord));
}

at_top :: (_ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(peek_panel(), _ord);
}

at_bottom :: (parent: *At_Location, _ord: $T) -> *At_Location #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return at(parent, 0,ord(_ord), 1.0,1.0);
}

at_bottom :: (_ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(peek_panel(), _ord);
}


at_left :: (parent: *At_Location, _ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(parent, 0,0, ord(_ord),1.0);
}

at_left :: (_ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(peek_panel(), _ord);
}


at_right :: (parent: *At_Location, _ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(parent, ord(_ord),0, 1.0,1.0);
}

at_right :: (_ord: $T) -> *At_Location #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(peek_panel(), _ord);
}


split_left_right :: (location: *At_Location, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(location, box(0,0, partition_ord,1.0)), at(location, box(partition_ord,0, 1.0,1.0));
}

split_top_bottom :: (location: *At_Location, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    return at(location, box(0,0, 1.0,partition_ord)), at(location, box(0,partition_ord, 1.0,1.0));
}


split_left_middle_right :: (location: *At_Location, left_partition_ord: $T, right_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    return at(location, box(0,0, left_partition_ord,1.0)),
           at(location, box(left_partition_ord,0, right_partition_ord,1.0)),
           at(location, box(right_partition_ord,0, 1.0,1.0));
}

split_top_middle_bottom :: (location: *At_Location, top_partition_ord: $T, bottom_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    return at(location, box(0,0, 1.0,top_partition_ord)),
           at(location, box(0,top_partition_ord, 1.0,bottom_partition_ord)),
           at(location, box(0,bottom_partition_ord, 1.0,1.0));
}


split_scrollbar_left :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, box(0,0, theme.scrollbar_size,1.0)), at(location, box(theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_right :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, box(0,0, -theme.scrollbar_size,1.0)), at(location, box(-theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_top :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, box(0,0, 1.0,theme.scrollbar_size)), at(location, box(0,theme.scrollbar_size, 1.0,1.0));
}

split_scrollbar_bottom :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, box(0,0, 1.0,-theme.scrollbar_size)), at(location, box(0,-theme.scrollbar_size, 1.0,1.0));
}


split_quadrants :: (location: *At_Location, horizontal_partition_ord: $T, vertical_partition_ord: $U) -> top_left: *Panel, top_right: *Panel, bottom_left: *Panel, bottom_right: *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    return at(location, box(0,0, horizontal_partition_ord,vertical_partition_ord)),
           at(location, box(horizontal_partition_ord,0, 1.0,vertical_partition_ord)),
           at(location, box(0,vertical_partition_ord, horizontal_partition_ord,1.0)),
           at(location, box(horizontal_partition_ord,vertical_partition_ord, 1.0,1.0));
}


shrink :: (panel: *Panel, delta_ord: $T) -> *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T);
} {
    _box := shrink(panel._box, delta_ord);
    return at(panel.parent, _box);
}

shrink :: (panel: *Panel, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> *Panel #expand #no_debug
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    _box := shrink(panel._box, horizontal_delta_ord, vertical_delta_ord);
    return at(panel.parent, _box);
}



Ord :: struct {
    rel: float;
    abs: int;
}

ord :: inline (rel: float, abs: int) -> Ord #symmetric { return .{ rel, abs }; }
ord :: inline (rel: float) -> Ord { return .{ rel, 0 }; }
ord :: inline (abs: int) -> Ord { return ifx abs < 0 then Ord.{ 1.0, abs } else Ord.{ 0.0, abs }; }
ord :: inline (_ord: Ord) -> Ord { return _ord; };

operator - :: (a: Ord) -> Ord {
    return .{ 1.0 - a.rel, -a.abs };
}

operator - :: (a: Ord, b: Ord) -> Ord {
    return .{ a.rel - b.rel, a.abs - b.abs };
}

operator + :: (a: Ord, b: Ord) -> Ord {
    return .{ a.rel + b.rel, a.abs + b.abs };
}

parse_ord :: (s: string) -> Ord, bool {
    result: Ord;
    if contains(s, #char ":") {
        parts := split(s, ",");
        if parts.count > 2  return result, false;
        for parts {
            if contains(it, #char ".") {
                f, ok := parse_float(*it);
                if ok  result.rel = f;
                else   return result, false;
            }
            else {
                i, ok := parse_int(*it);
                if ok  result.abs = i;
                else   return result, false;
            }
        }
        return result, true;
    }
    else if contains(s, #char ".") {
        f, ok := parse_float(*s);
        if ok  return ord(f), true;
        else   return result, false;
    }
    else {
        i, ok := parse_int(*s);
        if ok  return ord(i), true;
        else   return result, false;
    }
}

ord_constructor :: (o: Ord) -> string {
    if o.rel {
        if o.abs  return tprint("ord(%, %)", formatFloat(o.rel, zero_removal=.NO), o.abs);
        else      return tprint("ord(%)", formatFloat(o.rel, zero_removal=.NO));
    }
    else {
        return tprint("ord(%)", o.abs);
    }
}


Coord :: struct {
    x: Ord;
    y: Ord;
}

coord :: inline (x: $T, y: $U) -> Coord
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    return .{ ord(x), ord(y) };
}


Box :: struct {
    tl: Coord;
    br: Coord;

    #place tl;
    tlx: Ord;
    tly: Ord;
    brx: Ord;
    bry: Ord;
}

BOX_FILLED :: #run box(0,0, 1.0,1.0);

box :: inline (tlx: $T, tly: $U, brx: $V, bry: $W) -> Box
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W);
} {
    return .{ coord(tlx, tly), coord(brx, bry) };
}


shrink :: (_box: Box, delta_ord: $T) -> Box
#modify {
    return is_implicit_ord(T);
} {
    _ord := ord(delta_ord);
    result := _box;
    result.tl.x += _ord;
    result.tl.y += _ord;
    result.br.x -= _ord;;
    result.br.y -= _ord;;
    return result;
}

shrink :: (_box: Box, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> Box
#modify {
    return is_implicit_ord(T) && is_implicit_ord(U);
} {
    horizontal_ord := ord(horizontal_delta_ord);
    vertical_ord := ord(vertical_delta_ord);
    result := _box;
    result.tl.x += horizontal_ord;
    result.tl.y += vertical_ord;
    result.br.x -= horizontal_ord;;
    result.br.y -= vertical_ord;;
    return result;
}


translate :: (_box: *Box, $$x: int, $$y: int) {
    _box.tl.x.abs += x;
    _box.br.x.abs += x;
    _box.tl.y.abs += y;
    _box.br.y.abs += y;
}

abs_width :: (_box: Box) -> int {
    assert(_box.tl.x.rel == _box.br.x.rel, "You can only calculate an absolute width if both x Coords use the same origin (i.e. have the same rel)");
    return _box.br.x.abs - _box.tl.x.abs;
}

abs_height :: (_box: Box) -> int {
    assert(_box.tl.y.rel == _box.br.y.rel, "You can only calculate an absolute height if both y Coords use the same origin (i.e. have the same rel)");
    return _box.br.y.abs - _box.tl.y.abs;
}


Placement :: enum {
    COPY_LEFT;
    COPY_RIGHT;
    COPY_UP;
    COPY_DOWN;
    FILL_LEFT;
    FILL_RIGHT;
    FILL_UP;
    FILL_DOWN;
    FILL;
    MIRROR_HORIZONTAL;
    MIRROR_VERTICAL;
}

Placement_Spacing :: struct {
    horizontal: int;
    vertical: int;
}

last_widget_location : At_Location;
placement_spacing : [..] Placement_Spacing;
placement_panel : [..] *Panel;
new_placement := false;

push_spacing :: (spacing: Placement_Spacing) {
    array_add(*placement_spacing, spacing);
}

push_spacing :: (horizontal: int, vertical: int) {
    array_add(*placement_spacing, .{horizontal, vertical});
}

push_spacing :: (spacing: int) {
    array_add(*placement_spacing, .{spacing, spacing});
}

pop_spacing :: () -> Placement_Spacing {
    assert(placement_spacing.count > 1, "No spacing to pop (you've tried to pop more than you've pushed!");
    return pop(*placement_spacing);
}

peek_spacing :: () -> Placement_Spacing {
    return peek(placement_spacing);
}

with_spacing :: (spacing: Placement_Spacing) #expand {
    push_spacing(spacing);
    `defer pop_spacing();
}

with_spacing :: (horizontal: int, vertical: int) #expand {
    push_spacing(.{horizontal, vertical});
    `defer pop_spacing();
}

with_spacing :: (spacing: int) #expand {
    push_spacing(.{spacing, spacing});
    `defer pop_spacing();
}



push_panel :: (panel: *Panel) {
    array_add(*placement_panel, panel);
}

pop_panel :: () -> *Panel {
    assert(placement_panel.count > 0, "No panel to pop (you've tried to pop more than you've pushed!");
    return pop(*placement_panel);
}

peek_panel :: () -> *Panel {
    if placement_panel  return peek(placement_panel);
    else                return *window_panel;
}

with_panel :: (panel: *Panel) #expand {
    push_panel(panel);
    `defer pop_panel();
}


begin_placing :: (location: *At_Location) {
    last_widget_location = location.*;
    new_placement = true;
}

box :: inline (auto_place: Placement) -> Box {
    if new_placement {
        new_placement = false;
        return last_widget_location._box;
    }
    else {
        return box(*last_widget_location, auto_place);
    }
}

box :: inline (location: *At_Location, auto_place: Placement) -> Box {
    return box(location._box, auto_place);
}

box :: (from_box: Box, auto_place: Placement) -> Box {
    result := from_box;
    spacing := peek_spacing();

    if #complete auto_place == {
        case .COPY_LEFT;
        translate(*result, -abs_width(from_box) - spacing.horizontal, 0);

        case .COPY_RIGHT;
        translate(*result, +abs_width(from_box) + spacing.horizontal, 0);

        case .COPY_UP;
        translate(*result, 0, -abs_height(from_box) - spacing.vertical);

        case .COPY_DOWN;
        translate(*result, 0, +abs_height(from_box) + spacing.vertical);

        case .FILL_LEFT;
        translate(*result, -abs_width(from_box) - spacing.horizontal, 0);
        result.tl.x = ord(0.0);

        case .FILL_RIGHT;
        translate(*result, +abs_width(from_box) + spacing.horizontal, 0);
        result.br.x = ord(1.0);

        case .FILL_UP;
        translate(*result, 0, -abs_height(from_box) - spacing.vertical);
        result.tl.y = ord(0.0);

        case .FILL_DOWN;
        translate(*result, 0, +abs_height(from_box) + spacing.vertical);
        result.br.x = ord(1.0);

        case .FILL;
        result = BOX_FILLED;

        case .MIRROR_HORIZONTAL;
        result.tl.x = -from_box.br.x;
        result.br.x = -from_box.tl.x;

        case .MIRROR_VERTICAL;
        result.tl.y = -from_box.br.y;
        result.br.y = -from_box.tl.y;
    }

    return result;
}


#scope_module


Rect :: struct {
    x, y: float;
    w, h: float;
}

contains :: inline (r: Rect, x: float, y: float) -> bool {
    return r.x <= x && x < r.x + r.w && r.y <= y && y < r.y + r.h;
}

intersect :: (a: Rect, b: Rect) -> Rect {
    x := max(a.x, b.x);
    y := max(a.y, b.y);

    w := max(min(a.x+a.w, b.x+b.w) - x, 0);
    h := max(min(a.y+a.h, b.y+b.h) - y, 0);

    return Rect.{x, y, w, h};
}

bound :: (a: Rect, b: Rect) -> Rect {
    x := min(a.x, b.x);
    y := min(a.y, b.y);

    x1 := max(a.x+a.w, b.x+b.w);
    y1 := max(a.y+a.h, b.y+b.h);

    return Rect.{x, y, x1-x, y1-y};
}

split_left_right :: (rect: Rect, partition: float) -> Rect, Rect {
    if partition < 0
        return .{ rect.x, rect.y, rect.w + partition, rect.h }, .{ rect.x + rect.w + partition, rect.y, -partition, rect.h };
    else
        return .{ rect.x, rect.y, partition, rect.h }, .{ rect.x + partition, rect.y, rect.w - partition, rect.h };
}

shrink :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x + delta, rect.y + delta, rect.w - delta * 2, rect.h - delta * 2 };
}

shrink :: (rect: Rect, horizontal_delta: int, vertical_delta: int) -> Rect {
    return .{ rect.x + horizontal_delta, rect.y + vertical_delta, rect.w - horizontal_delta * 2, rect.h - vertical_delta * 2 };
}

shrink :: (rect: Rect, left: int, top: int, right: int, bottom: int) -> Rect {
    return .{ rect.x + left, rect.y + top, rect.w - (left + right), rect.h - (top + bottom) };
}

expand :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x - delta, rect.y - delta, rect.w + delta * 2, rect.h + delta * 2 };
}

expand :: (rect: Rect, horizontal_delta: int, vertical_delta: int) -> Rect {
    return .{ rect.x - horizontal_delta, rect.y - vertical_delta, rect.w + horizontal_delta * 2, rect.h + vertical_delta * 2 };
}

expand :: (rect: Rect, left: int, top: int, right: int, bottom: int) -> Rect {
    return .{ rect.x - left, rect.y - top, rect.w + (left + right), rect.h + (top + bottom) };
}
