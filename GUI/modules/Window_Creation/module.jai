// Platform-independent window creation routines.
#module_parameters (DEFAULT_MSAA: s32 = 4);

#if OS == .WINDOWS {
    #load "windows.jai";
} else #if OS == .LINUX {
    #load "linux.jai";
} else #if OS == .MACOS {
    #load "osx.jai";
} else #if OS == .PS5 {
    #load "ps5.jai";
} else #if OS == .ANDROID {
    #load "android.jai";
} else {
    #assert(false);
}

#scope_module

#import "Basic";

DEFAULT_WINDOW_CREATION_COLOR :: float.[.15,.15,.2];

#scope_export

// @CompilerBug: There is some kind of name importation problem that keeps happening,
// for example, Window_Type doesn't go through unless we do this weird WT thing.
// -jblow, 25 February 2021
WT :: #import "Window_Type";  // Define this for the people.
Window_Type :: WT.Window_Type;
