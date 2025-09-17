// @Note GUI provides a simple but powerful layout engine to allow you to quickly and easily
//       describe your UI widget positions.  The two core concepts you need to understand
//       are the Ord and the Panel.
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
//       Panel is a Box positioned with a parent Panel (the root Panel is the application_panel;
//       the area defined by the OS window).
//       When you want to describe a location for your widget, you will use a Panel, usually
//       by calling `at(...)`).  Sometimes you'll want to use a free-standing panel as the
//       parent to other widgets.  Here is some code to demonstrate:
//
//          sidebar_panel, main_panel := split_left_right(window, 0.3);
//          label(at_top(sidebar_panel, 20), "The Program");
//          data_table(main_panel, my_array);
//
//      In the above, the `0.3` and the `20` are Ords (for a relative left/right partition and
//      an absolute label height, respectively).

// @Note We want to treat widgets as Panels, so everything in GUI works using a *Panel parameter.
//       Therefor, all the procs below return a pointer; the data itself is put on the
//       temp allocator (and thus is cleared every frame, so if you keep them around across
//       the frame boundary be wary of traversing up the hierarchy).


Panel :: struct {
    parent: *Panel;
    desired_box: Box;
    calculated_rect: Rect;
    calculated_rect_frame_index: int;
}

is_implicit_ord :: inline (T) => (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);

copy :: (panel: *Panel) -> *Panel {
    copy := New(Panel, false,, temp);
    copy.* = panel.*;
    return copy;
}

at :: (parent: *Panel) -> *Panel  {
    panel := New(Panel, false,, temp);
    panel.* = .{ parent, BOX_FILLED, .{}, 0 };
    return panel;
}

at :: (parent: *Panel, tlx: $T, tly: $U, brx: $V, bry: $W) -> *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W); }
{
    panel := New(Panel, false,, temp);
    panel.* = .{ parent, .{ coord(tlx, tly), coord(brx, bry) }, .{}, 0};
    return panel;
}

at :: (tlx: $T, tly: $U, brx: $V, bry: $W) -> *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W); }
{
    return at(peek_panel(), tlx, tly, brx, bry);
}

at_size :: (parent: *Panel, x: $T, y: $U, width: $V, height: $W) -> *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W); }
{
    panel := New(Panel, false,, temp);
    panel.* = .{ parent, .{ coord(x, y), coord(x + width, y + height) }, .{}, 0};
    return panel;
}

at_size :: (x: $T, y: $U, width: $V, height: $W) -> *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W); }
{
    return at_size(peek_panel(), x, y, width, height);
}


at :: (parent: *Panel, _box: Box) -> *Panel  {
    panel := New(Panel, false,, temp);
    panel.* = .{ parent, _box, .{}, 0 };
    return panel;
}

at :: (_box: Box) -> *Panel  {
    return at(peek_panel(), _box);
}

at :: (parent: *Panel, auto_place: Placement) -> *Panel  {
    panel := New(Panel, false,, temp);
    panel.* = .{ parent, box(auto_place), .{}, 0 };
    return panel;
}

at :: (auto_place: Placement) -> *Panel  {
    //if placement_panel // @TODO best behaviour is?
    //    return at(peek_panel(), auto_place);
    //else
    return at(last_widget_panel.parent, auto_place);
}


at_top :: (parent: *Panel, _ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(parent, 0,0, 1.0,ord(_ord));
}

at_top :: (_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(peek_panel(), _ord);
}

at_bottom :: (parent: *Panel, _ord: $T) -> *Panel
#modify { return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT); }
{
    return at(parent, 0,ord(_ord), 1.0,1.0);
}

at_bottom :: (_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(peek_panel(), _ord);
}


at_left :: (parent: *Panel, _ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(parent, 0,0, ord(_ord),1.0);
}

at_left :: (_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(peek_panel(), _ord);
}


at_right :: (parent: *Panel, _ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(parent, ord(_ord),0, 1.0,1.0);
}

at_right :: (_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(peek_panel(), _ord);
}


split_left_right :: (panel: *Panel, partition_ord: $T) -> *Panel, *Panel
#modify { return is_implicit_ord(T); }
{
    return at(panel, box(0,0, partition_ord,1.0)), at(panel, box(partition_ord,0, 1.0,1.0));
}

split_top_bottom :: (panel: *Panel, partition_ord: $T) -> *Panel, *Panel
#modify { return is_implicit_ord(T); }
{
    return at(panel, box(0,0, 1.0,partition_ord)), at(panel, box(0,partition_ord, 1.0,1.0));
}


split_left_middle_right :: (panel: *Panel, left_partition_ord: $T, right_partition_ord: $U) -> *Panel, *Panel, *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
    return at(panel, box(0,0, left_partition_ord,1.0)),
           at(panel, box(left_partition_ord,0, right_partition_ord,1.0)),
           at(panel, box(right_partition_ord,0, 1.0,1.0));
}

split_top_middle_bottom :: (panel: *Panel, top_partition_ord: $T, bottom_partition_ord: $U) -> *Panel, *Panel, *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
    return at(panel, box(0,0, 1.0,top_partition_ord)),
           at(panel, box(0,top_partition_ord, 1.0,bottom_partition_ord)),
           at(panel, box(0,bottom_partition_ord, 1.0,1.0));
}

split_quadrants :: (panel: *Panel, horizontal_partition_ord: $T, vertical_partition_ord: $U) -> top_left: *Panel, top_right: *Panel, bottom_left: *Panel, bottom_right: *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
    return at(panel, box(0,0, horizontal_partition_ord,vertical_partition_ord)),
           at(panel, box(horizontal_partition_ord,0, 1.0,vertical_partition_ord)),
           at(panel, box(0,vertical_partition_ord, horizontal_partition_ord,1.0)),
           at(panel, box(horizontal_partition_ord,vertical_partition_ord, 1.0,1.0));
}


split_for_left_scrollbar :: (panel: *Panel) -> scrollbar_panel: *Panel, *Panel  {
    return at(panel, box(0,0, theme.scrollbar_size,1.0)), at(panel, box(theme.scrollbar_size,0, 1.0,1.0));
}

split_for_right_scrollbar :: (panel: *Panel) -> *Panel, scrollbar_panel: *Panel  {
    return at(panel, box(0,0, -theme.scrollbar_size,1.0)), at(panel, box(-theme.scrollbar_size,0, 1.0,1.0));
}

split_for_top_scrollbar :: (panel: *Panel) -> scrollbar_panel: *Panel, *Panel  {
    return at(panel, box(0,0, 1.0,theme.scrollbar_size)), at(panel, box(0,theme.scrollbar_size, 1.0,1.0));
}

split_for_bottom_scrollbar :: (panel: *Panel) -> *Panel, scrollbar_panel: *Panel  {
    return at(panel, box(0,0, 1.0,-theme.scrollbar_size)), at(panel, box(0,-theme.scrollbar_size, 1.0,1.0));
}

split_for_bottom_and_right_scrollbars :: (panel: *Panel) -> main_area: *Panel, bottom_scrollbar: *Panel, right_scrollbar: *Panel  {
    tl, tr, bl, br := split_quadrants(panel, -theme.scrollbar_size, -theme.scrollbar_size);
    return tl, bl, tr;
}


shrink :: (panel: *Panel, delta_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(panel.parent, shrink(panel.desired_box, delta_ord));
}

shrink :: (panel: *Panel, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> *Panel
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
    return at(panel.parent, shrink(panel.desired_box, horizontal_delta_ord, vertical_delta_ord));
}

shrink_to_height :: (panel: *Panel, height_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    half_height := ord(height_ord) / 2;
    center_line, _ := split_top_bottom(panel, 0.5);
    center_line.desired_box.tl.y = center_line.desired_box.br.y;
    return at(panel, grow(center_line.desired_box, half_height, .UP|.DOWN));
}

shrink_to_width :: (panel: *Panel, width_ord: $T) -> *Panel
#modify { return is_implicit_ord(T); }
{
    half_width := ord(width_ord) / 2;
    center_line, _ := split_left_right(panel, 0.5);
    center_line.desired_box.tl.x = center_line.desired_box.br.x;
    return at(panel, grow(center_line.desired_box, half_width, .LEFT|.RIGHT));
}

grow :: (panel: *Panel, delta_ord: $T, direction := Direction.ALL) -> *Panel
#modify { return is_implicit_ord(T); }
{
    return at(panel.parent, grow(panel.desired_box, delta_ord, direction));
}

Ord :: struct {
    rel: float;
    abs: int;
}

ord :: inline (rel: float, abs: int) -> Ord #symmetric { return .{ rel, abs }; }
ord :: inline (rel: float) -> Ord { return .{ rel, 0 }; }
ord :: inline (abs: int) -> Ord { return ifx abs < 0 then Ord.{ 1.0, abs } else Ord.{ 0.0, abs }; }
ord :: inline (_ord: Ord) -> Ord { return _ord; };

operator == :: (a: Ord, b: Ord) -> bool {
    return a.abs == b.abs && a.rel == b.rel;
}

operator - :: (a: Ord) -> Ord {
    return .{ 1.0 - a.rel, -a.abs };
}

operator - :: (a: Ord, b: Ord) -> Ord {
    return .{ a.rel - b.rel, a.abs - b.abs };
}

operator + :: (a: Ord, b: Ord) -> Ord {
    return .{ a.rel + b.rel, a.abs + b.abs };
}

// @TODO rest of these
operator + :: (a: Ord, b: int) -> Ord #symmetric {
    return .{ a.rel, a.abs + b };
}

operator - :: (a: Ord, b: int) -> Ord #symmetric {
    return .{ a.rel, a.abs - b };
}

operator * :: (a: Ord, b: int) -> Ord #symmetric {
    return .{ a.rel*b, a.abs*b };
}

operator / :: (a: Ord, b: int) -> Ord #symmetric {
    return .{ a.rel/b, a.abs/b };
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
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
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
#modify { return is_implicit_ord(T) && is_implicit_ord(U) && is_implicit_ord(V) && is_implicit_ord(W); }
{
    return .{ coord(tlx, tly), coord(brx, bry) };
}


shrink :: (_box: Box, delta_ord: $T) -> Box
#modify { return is_implicit_ord(T); }
{
    _ord := ord(delta_ord);
    result := _box;
    result.tl.x += _ord;
    result.tl.y += _ord;
    result.br.x -= _ord;;
    result.br.y -= _ord;;
    return result;
}

shrink :: (_box: Box, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> Box
#modify { return is_implicit_ord(T) && is_implicit_ord(U); }
{
    horizontal_ord := ord(horizontal_delta_ord);
    vertical_ord := ord(vertical_delta_ord);
    result := _box;
    result.tl.x += horizontal_ord;
    result.tl.y += vertical_ord;
    result.br.x -= horizontal_ord;;
    result.br.y -= vertical_ord;;
    return result;
}

grow :: (_box: Box, delta_ord: $T, direction := Direction.ALL) -> Box
#modify { return is_implicit_ord(T); }
{
    _ord := ord(delta_ord);
    result := _box;
    if direction & .UP     result.tl.y -= _ord;
    if direction & .LEFT   result.tl.x -= _ord;
    if direction & .RIGHT  result.br.x += _ord;;
    if direction & .DOWN   result.br.y += _ord;;
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

Direction :: enum_flags {
    UP;
    DOWN;
    LEFT;
    RIGHT;
    ALL :: UP | DOWN | LEFT | RIGHT;
}

Placement :: enum {
    COPY_UP;
    COPY_DOWN;
    COPY_LEFT;
    COPY_RIGHT;
    FILL_UP;
    FILL_DOWN;
    FILL_LEFT;
    FILL_RIGHT;
    FILL;
    MIRROR_HORIZONTAL;
    MIRROR_VERTICAL;
}

Placement_Spacing :: struct {
    horizontal: int;
    vertical: int;
}

last_widget_panel : Panel;
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
    else                return *application_panel;
}

with_panel :: (panel: *Panel) #expand {
    push_panel(panel);
    `defer pop_panel();
}


begin_placing :: (panel: *Panel) {
    last_widget_panel = panel.*;
    new_placement = true;
}

box :: inline (auto_place: Placement) -> Box {
    if new_placement {
        new_placement = false;
        return last_widget_panel.desired_box;
    }
    else {
        return box(*last_widget_panel, auto_place);
    }
}

box :: inline (panel: *Panel, auto_place: Placement) -> Box {
    return box(panel.desired_box, auto_place);
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
        result.br.x = result.tl.x - spacing.horizontal;
        result.tl.x = ord(0.0);

        case .FILL_RIGHT;
        result.tl.x = result.br.x + spacing.horizontal;
        result.br.x = ord(1.0);

        case .FILL_UP;
        result.br.y = result.tl.y - spacing.vertical;
        result.tl.y = ord(0.0);

        case .FILL_DOWN;
        result.tl.y = result.br.y + spacing.vertical;
        result.br.y = ord(1.0);

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


Rect :: struct {
    x, y: float;
    w, h: float;

    #place x;
    position: Vector2;
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
