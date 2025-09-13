#scope_file

Android :: #import "Android";

#scope_export

Saved_Window_Info :: struct {}

// @Incomplete
// Fullscreen on android has some annoying minutiae.
// The below function sets the window to fullscreen mode which hides the "status bar" (icons at top of the screen).
// But:
// - if your phone has any "cut outs", eg if your camera is on the screen, then setting to fullscreen will draw
//   a black bar to cover this area. To get around this you either need to use java, or add
//   <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item> to a custom style and use the style.
//   See https://developer.android.com/develop/ui/views/layout/display-cutout.
// - This doesn't hide the "navigation bar" (the back/home buttons, or the gesture pill at bottom of screen).
//   To hide this you have to use java. So for now, while using straight NativeActivity this remains on screen. Sadge.
//
// Maybe "immersive mode" is the more common thing to want here? https://developer.android.com/develop/ui/views/layout/immersive
toggle_fullscreen :: (win: *Android.ANativeWindow, desire_fullscreen: bool, saved: *Saved_Window_Info) -> success: bool, width: s32, height: s32 {

    assert(context.android_app != null && context.android_app.activity != null);
    assert(saved == null, "Saved_Window_Info doesn't make sense on android");

    // Q: Where to do these kinds of window settings more generally?
    // window_flags: AWINDOW_FLAG = .FULLSCREEN | .LAYOUT_IN_SCREEN | .LAYOUT_NO_LIMITS | .LAYOUT_INSET_DECOR;
    window_flags: Android.AWINDOW_FLAG = .FULLSCREEN;
    if desire_fullscreen Android.ANativeActivity_setWindowFlags(context.android_app.activity, xx window_flags, 0);
    else                 Android.ANativeActivity_setWindowFlags(context.android_app.activity, 0, xx window_flags);

    _, _, width, height := get_dimensions(win, true);
    return true, width, height;
}

create_window :: (width: int, height: int, window_name: string, window_x := 0, window_y := 0, parent: Window_Type = null, background_color_rgb := DEFAULT_WINDOW_CREATION_COLOR, wanted_msaa := DEFAULT_MSAA) -> *Android.ANativeWindow {
    assert(context.android_app != null, "android_app is null!");
    return context.android_app.window;
}

get_dimensions :: (win: *Android.ANativeWindow, right_handed: bool) -> (x: s32, y: s32, width: s32, height: s32, success := true) {
    // @TODO For NativeActivity apps should we be using the contentRect?
    // Probably not, but probably we should be doing something. The content rect seems to be the area that is
    // not covered by the status bar, and navigation bar thing at bottom. So in general using full window
    // dimensions is correct, but to not render in those places we still need that info somewhere?
    width  := Android.ANativeWindow_getWidth(win);
    height := Android.ANativeWindow_getHeight(win);
    return 0, 0, width, height;
}

// @Hack Probably these shoudln't be stored here. Also they don't get cleared when you stop touching screen.
touch_x, touch_y : int;

// @TODO Is it worth having this just be touch? Or handling touch separately?
get_mouse_pointer_position :: (win: *Android.ANativeWindow, right_handed: bool) -> x: int, y: int, success: bool {
    return touch_x, touch_y, true;
}

get_mouse_pointer_position :: inline (right_handed := false) -> x: int, y: int, success: bool {
    return touch_x, touch_y, true;
}
