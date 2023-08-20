// @Note Panels are not widgets, and you cannot give them an ID; they are used exclusively for positioning
//       actual widgets.  Their lifetime is not guaranteed to be the frame, and they should only be used
//       locally.  i.e. if a panel is in a loop you should not refer to it outside the loop.
//       Consequently you cannot arbitrarily crawl back up the parents of a widget at the end of the frame.
//       (Well, you can, but if you go through a panel created in a loop it won't necessarily give you good results).


Panel :: struct {
    parent : *Panel;
    _box : Box;
    rect : Rect;
    rect_frame_count : int;
}


panel :: (parent: *Panel, tlx: $T, tly: $U, brx: $V, bry: $W) -> *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT)
        && (V == Ord || (cast(*Type_Info)V).type == .INTEGER || (cast(*Type_Info)V).type == .FLOAT)
        && (W == Ord || (cast(*Type_Info)W).type == .INTEGER || (cast(*Type_Info)W).type == .FLOAT);
}
{
    panel := Panel.{ parent, .{ coord(tlx, tly), coord(brx, bry) }, .{}, 0};
    return *panel;
}

panel :: (parent: *Panel, _box: Box) -> *Panel #expand #no_debug {
    panel := Panel.{ parent, _box, .{}, 0 };
    return *panel;
}

panel :: (parent: *Panel, auto_place: Auto_Place) -> *Panel #expand #no_debug {
    panel := Panel.{ parent, Box(auto_place), .{}, 0 };
    return *panel;
}



split_left_right :: (_panel: *Panel, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return panel(_panel, box(0,0, partition_ord,1.0)), panel(_panel, box(partition_ord,0, 1.0,1.0));
}

split_top_bottom :: (_panel: *Panel, partition_ord: $T) -> *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT);
}
{
    return panel(_panel, box(0,0, 1.0,partition_ord)), panel(_panel, box(0,partition_ord, 1.0,1.0));
}


split_left_middle_right :: (_panel: *Panel, left_partition_ord: $T, right_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return panel(_panel, box(0,0, left_partition_ord,1.0)),
           panel(_panel, box(left_partition_ord,0, right_partition_ord,1.0)),
           panel(_panel, box(right_partition_ord,0, 1.0,1.0));
}

split_top_middle_bottom :: (_panel: *Panel, top_partition_ord: $T, bottom_partition_ord: $U) -> *Panel, *Panel, *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return panel(_panel, box(0,0, 1.0,top_partition_ord)),
           panel(_panel, box(0,top_partition_ord, 1.0,bottom_partition_ord)),
           panel(_panel, box(0,bottom_partition_ord, 1.0,1.0));
}


split_scrollbar_left :: (_panel: *Panel) -> *Panel, *Panel #expand #no_debug {
    return panel(_panel, box(0,0, theme.scrollbar_size,1.0)), panel(_panel, box(theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_right :: (_panel: *Panel) -> *Panel, *Panel #expand #no_debug {
    return panel(_panel, box(0,0, -theme.scrollbar_size,1.0)), panel(_panel, box(-theme.scrollbar_size,0, 1.0,1.0));
}

split_scrollbar_top :: (_panel: *Panel) -> *Panel, *Panel #expand #no_debug {
    return panel(_panel, box(0,0, 1.0,theme.scrollbar_size)), panel(_panel, box(0,theme.scrollbar_size, 1.0,1.0));
}

split_scrollbar_bottom :: (_panel: *Panel) -> *Panel, *Panel #expand #no_debug {
    return panel(_panel, box(0,0, 1.0,-theme.scrollbar_size)), panel(_panel, box(0,-theme.scrollbar_size, 1.0,1.0));
}


split_quadrants :: (_panel: *Panel, horizontal_partition_ord: $T, vertical_partition_ord: $U) -> top_left: *Panel, top_right: *Panel, bottom_left: *Panel, bottom_right: *Panel #expand #no_debug
#modify {
    return (T == Ord || (cast(*Type_Info)T).type == .INTEGER || (cast(*Type_Info)T).type == .FLOAT)
        && (U == Ord || (cast(*Type_Info)U).type == .INTEGER || (cast(*Type_Info)U).type == .FLOAT);
}
{
    return panel(_panel, box(0,0, horizontal_partition_ord,vertical_partition_ord)),
           panel(_panel, box(horizontal_partition_ord,0, 1.0,vertical_partition_ord)),
           panel(_panel, box(0,vertical_partition_ord, horizontal_partition_ord,1.0)),
           panel(_panel, box(horizontal_partition_ord,vertical_partition_ord, 1.0,1.0));
}
