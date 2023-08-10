Ord :: struct {
    rel: float;
    abs: int;
}

ord :: inline (rel: float, abs: int) -> Ord #symmetric { return .{ rel, abs }; }
ord :: inline (rel: float) -> Ord { return .{ rel, 0 }; }
ord :: inline (abs: int) -> Ord { return ifx abs < 0 then Ord.{ 1.0, abs } else Ord.{ 0.0, abs }; }
ord :: inline (_ord: Ord) -> Ord { return _ord; };


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

shrink :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x + delta, rect.y + delta, rect.w - delta * 2, rect.h - delta * 2 };
}

narrow :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x + delta, rect.y, rect.w - delta * 2, rect.h };
}

squash :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x, rect.y + delta, rect.w, rect.h - delta * 2 };
}

expand :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x - delta, rect.y - delta, rect.w + delta * 2, rect.h + delta * 2 };
}

widen :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x - delta, rect.y, rect.w + delta * 2, rect.h };
}

grow :: (rect: Rect, delta: int) -> Rect {
    return .{ rect.x, rect.y - delta, rect.w, rect.h + delta * 2 };
}

button_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
}
