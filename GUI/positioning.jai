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


Place :: struct {
    tl: Coord;
    br: Coord;

    #place tl;
    tlx: Ord;
    tly: Ord;
    brx: Ord;
    bry: Ord;
}

place :: inline (tlx: $T, tly: $U, brx: $V, bry: $W) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    return .{ coord(tlx, tly), coord(brx, bry) };
}

at_top :: (_ord: $T) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(0, 0), coord(1.0, ord(_ord)) };
}

at_bottom :: (_ord: $T) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(0, ord(_ord)), coord(1.0, 1.0) };
}

at_left :: (_ord: $T) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(0, 0), coord(ord(_ord), 1.0) };
}

at_right :: (_ord: $T) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return .{ coord(ord(_ord), 0), coord(1.0, 1.0) };
}

translate :: (place: *Place, $$x: int, $$y: int) {
    place.tl.x.abs += x;
    place.br.x.abs += x;
    place.tl.y.abs += y;
    place.br.y.abs += y;
}

abs_width :: (place: Place) -> int {
    assert(place.tl.x.rel == place.br.x.rel, "You can only calculate an absolute width if both x Coords use the same origin (i.e. have the same rel)");
    return place.br.x.abs - place.tl.x.abs;
}

abs_height :: (place: Place) -> int {
    assert(place.tl.y.rel == place.br.y.rel, "You can only calculate an absolute height if both y Coords use the same origin (i.e. have the same rel)");
    return place.br.y.abs - place.tl.y.abs;
}

shrink :: (place: Place, delta_ord: $T) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    _ord := ord(delta_ord);
    result := place;
    result.tl.x += _ord;
    result.tl.y += _ord;
    result.br.x -= _ord;;
    result.br.y -= _ord;;
    return result;
}

shrink :: (place: Place, horizontal_delta_ord: $T, vertical_delta_ord: $U) -> Place
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    horizontal_ord := ord(horizontal_delta_ord);
    vertical_ord := ord(vertical_delta_ord);
    result := place;
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

expand :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x - delta, rect.y - delta, rect.w + delta * 2, rect.h + delta * 2 };
}

expand :: (rect: Rect, horizontal_delta: int, vertical_delta: int) -> Rect {
    return .{ rect.x - horizontal_delta, rect.y - vertical_delta, rect.w + horizontal_delta * 2, rect.h + vertical_delta * 2 };
}


Auto_Place :: enum {
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

Auto_Place_Spacing :: struct {
    horizontal: int;
    vertical: int;
}

last_widget_placement : Place;
auto_place_spacing : [..] Auto_Place_Spacing;
new_auto_place := false;

push_spacing :: (spacing: Auto_Place_Spacing) {
    array_add(*auto_place_spacing, spacing);
}

push_spacing :: (horizontal: int, vertical: int) {
    array_add(*auto_place_spacing, .{horizontal, vertical});
}

push_spacing :: (spacing: int) {
    array_add(*auto_place_spacing, .{spacing, spacing});
}

pop_spacing :: () -> Auto_Place_Spacing {
    assert(auto_place_spacing.count > 1, "No spacing to pop (you've tried to pop more than you've pushed!");
    return pop(*auto_place_spacing);
}

peek_spacing :: () -> Auto_Place_Spacing {
    return peek(auto_place_spacing);
}

begin_placing :: (placement: Place) {
    last_widget_placement = placement;
    new_auto_place = true;
}

begin_placing :: inline (tlx: $T, tly: $U, brx: $V, bry: $W)
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    begin_placing(place(tlx, tly, brx, bry));
}

place :: inline (auto_place: Auto_Place) -> Place {
    if new_auto_place {
        new_auto_place = false;
        return last_widget_placement;
    }
    else {
        return place(last_widget_placement, auto_place);
    }
}

place :: inline (_panel: *Panel, auto_place: Auto_Place) -> Place {
    return place(_panel.placement, auto_place);
}

place :: (from_placement: Place, auto_place: Auto_Place) -> Place {
    result := from_placement;
    spacing := peek_spacing();

    if #complete auto_place == {
        case .COPY_LEFT;
        translate(*result, -abs_width(from_placement) - spacing.horizontal, 0);

        case .COPY_RIGHT;
        translate(*result, +abs_width(from_placement) + spacing.horizontal, 0);

        case .COPY_UP;
        translate(*result, 0, -abs_height(from_placement) - spacing.vertical);

        case .COPY_DOWN;
        translate(*result, 0, +abs_height(from_placement) + spacing.vertical);

        case .FILL_LEFT;
        translate(*result, -abs_width(from_placement) - spacing.horizontal, 0);
        result.tl.x = ord(0.0);

        case .FILL_RIGHT;
        translate(*result, +abs_width(from_placement) + spacing.horizontal, 0);
        result.br.x = ord(1.0);

        case .FILL_UP;
        translate(*result, 0, -abs_height(from_placement) - spacing.vertical);
        result.tl.y = ord(0.0);

        case .FILL_DOWN;
        translate(*result, 0, +abs_height(from_placement) + spacing.vertical);
        result.br.x = ord(1.0);

        case .FILL;
        result = .{ coord(0, 0), coord(1.0, 1.0) };

        case .MIRROR_HORIZONTAL;
        result.tl.x = -from_placement.br.x;
        result.br.x = -from_placement.tl.x;

        case .MIRROR_VERTICAL;
        result.tl.y = -from_placement.br.y;
        result.br.y = -from_placement.tl.y;
    }

    return result;
}

