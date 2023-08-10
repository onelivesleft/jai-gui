Panel :: struct {
    parent : *Panel;
    placement : Place;
    rect : Rect;
    rect_frame_count : int;
}

// @Note We don't really *need* to store an array of panels, as they are only used for positioning.
//       However, by storing them me ensure the heirarchy is always valid and traversable (if it
//       included panels created on the stack this would not be the case).  This gives a cleaner
//       interface and disallows the user from an easy bug (should they be looking up the heirarchy
//       for some reason).

panel :: (parent: *Panel, tlx: $T, tly: $U, brx: $V, bry: $W) -> *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    panel := *panels[#insert #run next(*panels_count)];
    panel.* = .{ parent, .{ coord(tlx, tly), coord(brx, bry) }, .{}, 0};
    return panel;
}

panel :: (parent: *Panel, placement: Place) -> *Panel #expand #no_debug {
    panel := *panels[#insert #run next(*panels_count)];
    panel.* = .{ parent, placement, .{}, 0 };
    return panel;
}


get_index :: (panel: *Panel) -> int {
    index := panel - panels.data;
    assert(0 <= index && index < panels.count);
    return index;
}


#scope_module


panels : [] Panel;
#no_reset panels_count := 0;

