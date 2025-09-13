#import "ps5/mouse";

window_minimized := false;

Saved_Window_Info :: struct {

}

toggle_fullscreen :: (win: Window_Type, desire_fullscreen: bool, saved: *Saved_Window_Info) -> success: bool, width: s32, height: s32 {
    return false, 0, 0;
}

create_window :: (width: int, height: int, window_name: string, window_x := 0, window_y := 0, parent: Window_Type = null, background_color_rgb := DEFAULT_WINDOW_CREATION_COLOR, wanted_msaa := DEFAULT_MSAA) -> Window_Type {
    return cast(Window_Type) 1;
}

get_mouse_pointer_position :: (win: Window_Type, right_handed: bool) -> (x: int, y: int, success: bool) {
    state, success := get_mouse_state();
    if !success then
        return 0, 0, false;

    return state.position_x, state.position_y, true;
}

get_mouse_pointer_position :: inline (right_handed := false) -> x: int, y: int, success: bool {
    state, success := get_mouse_state();
    if !success then
        return 0, 0, false;

    return state.position_x, state.position_y, true;
}
