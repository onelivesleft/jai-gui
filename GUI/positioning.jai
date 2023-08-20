At_Location :: struct {
    parent: *At_Location;
    box: Box;
    rect: Rect;
    rect_frame_count: int;
}

Panel :: At_Location;



at :: (parent: *At_Location) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, BOX_FILLED, .{}, 0 };
    return *location;
}

at :: (parent: *At_Location, tlx: $T, tly: $U, brx: $V, bry: $W) -> *At_Location #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    location := At_Location.{ parent, .{ coord(tlx, tly), coord(brx, bry) }, .{}, 0};
    return *location;
}

at :: (tlx: $T, tly: $U, brx: $V, bry: $W) -> *At_Location #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    return at(peek_panel(), tlx, tly, brx, bry);
}

at :: (parent: *At_Location, box: Box) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, box, .{}, 0 };
    return *location;
}

at :: (box: Box) -> *At_Location #expand #no_debug {
    return at(peek_panel(), box);
}

at :: (parent: *At_Location, auto_place: Placement) -> *At_Location #expand #no_debug {
    location := At_Location.{ parent, get_box(auto_place), .{}, 0 };
    return *location;
}

at :: (auto_place: Placement) -> *At_Location #expand #no_debug {
    return at(peek_panel(), auto_place);
}


at_top :: (parent: *At_Location, _ord: $T) -> *At_Location #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return at(parent, 0,0, 1.0,ord(_ord));
}

at_top :: (_ord: $T) -> *At_Location #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return at(peek_panel(), _ord);
}

at_bottom :: (_ord: $T) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(0, ord(_ord)), coord(1.0, 1.0) };
}

at_left :: (_ord: $T) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(0, 0), coord(ord(_ord), 1.0) };
}

at_right :: (_ord: $T) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(ord(_ord), 0), coord(1.0, 1.0) };
}


split_left_right :: (location: *At_Location, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return at(location, get_box(0,0, partition_ord,1.0)), at(location, get_box(partition_ord,0, 1.0,1.0));
}

split_top_bottom :: (location: *At_Location, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return at(location, get_box(0,0, 1.0,partition_ord)), at(location, get_box(0,partition_ord, 1.0,1.0));
}


split_left_middle_right :: (location: *At_Location, left_partition_ord: $T, right_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return at(location, get_box(0,0, left_partition_ord,1.0)),
           at(location, get_box(left_partition_ord,0, right_partition_ord,1.0)),
           at(location, get_box(right_partition_ord,0, 1.0,1.0));
}

split_top_middle_bottom :: (location: *At_Location, top_partition_ord: $T, bottom_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return at(location, get_box(0,0, 1.0,top_partition_ord)),
           at(location, get_box(0,top_partition_ord, 1.0,bottom_partition_ord)),
           at(location, get_box(0,bottom_partition_ord, 1.0,1.0));
}


split_scrollbar_left :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, get_box(0,0, theme.scrollbar_size,1.0)), at(location, get_box(theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_right :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, get_box(0,0, -theme.scrollbar_size,1.0)), at(location, get_box(-theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_top :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, get_box(0,0, 1.0,theme.scrollbar_size)), at(location, get_box(0,theme.scrollbar_size, 1.0,1.0));
}

split_scrollbar_bottom :: (location: *At_Location) -> *Panel, *Panel #expand #no_debug {
    return at(location, get_box(0,0, 1.0,-theme.scrollbar_size)), at(location, get_box(0,-theme.scrollbar_size, 1.0,1.0));
}


split_quadrants :: (location: *At_Location, horizontal_partition_ord: $T, vertical_partition_ord: $U) -> top_left: *Panel, top_right: *Panel, bottom_left: *Panel, bottom_right: *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return at(location, get_box(0,0, horizontal_partition_ord,vertical_partition_ord)),
           at(location, get_box(horizontal_partition_ord,0, 1.0,vertical_partition_ord)),
           at(location, get_box(0,vertical_partition_ord, horizontal_partition_ord,1.0)),
           at(location, get_box(horizontal_partition_ord,vertical_partition_ord, 1.0,1.0));
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
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
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

BOX_FILLED :: #run get_box(0,0, 1.0,1.0);

get_box :: inline (tlx: $T, tly: $U, brx: $V, bry: $W) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    return .{ coord(tlx, tly), coord(brx, bry) };
}


translate :: (box: *Box, $$x: int, $$y: int) {
    box.tl.x.abs += x;
    box.br.x.abs += x;
    box.tl.y.abs += y;
    box.br.y.abs += y;
}

abs_width :: (box: Box) -> int {
    assert(box.tl.x.rel == box.br.x.rel, "You can only calculate an absolute width if both x Coords use the same origin (i.e. have the same rel)");
    return box.br.x.abs - box.tl.x.abs;
}

abs_height :: (box: Box) -> int {
    assert(box.tl.y.rel == box.br.y.rel, "You can only calculate an absolute height if both y Coords use the same origin (i.e. have the same rel)");
    return box.br.y.abs - box.tl.y.abs;
}

shrink :: (panel: *Panel, delta_ord: $T) -> *Panel
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    box := shrink(panel.box, delta_ord);
    return at(panel.parent, box);
}

shrink :: (box: Box, delta_ord: $T) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    _ord := ord(delta_ord);
    result := box;
    result.tl.x += _ord;
    result.tl.y += _ord;
    result.br.x -= _ord;;
    result.br.y -= _ord;;
    return result;
}


shrink :: (panel: *Panel, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> *Panel
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    box := shrink(panel.box, horizontal_delta_ord, vertical_delta_ord);
    return at(panel.parent, box);
}

shrink :: (box: Box, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> Box
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    horizontal_ord := ord(horizontal_delta_ord);
    vertical_ord := ord(vertical_delta_ord);
    result := box;
    result.tl.x += horizontal_ord;
    result.tl.y += vertical_ord;
    result.br.x -= horizontal_ord;;
    result.br.y -= vertical_ord;;
    return result;
}

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

get_box :: inline (auto_place: Placement) -> Box {
    if new_placement {
        new_placement = false;
        return last_widget_location.box;
    }
    else {
        return get_box(*last_widget_location, auto_place);
    }
}

get_box :: inline (location: *At_Location, auto_place: Placement) -> Box {
    return get_box(location.box, auto_place);
}

get_box :: (from_box: Box, auto_place: Placement) -> Box {
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
