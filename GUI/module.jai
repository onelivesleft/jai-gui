#module_parameters (
    MANUAL_END_FRAME := false,  // Normally gui_begin_frame will call gui_end_frame for you; you can disable
                                // that with this (though you then *must* call gui_end_frame yourself!)

    FONT_SANS  := "Montreal-Regular.ttf",
    FONT_SERIF := "CharisSIL-R.ttf",
    FONT_FIXED := "FantasqueSansMono-Regular.ttf"
);

#load "GUI.jai";
#load "default_skin.jai";

#load "icons.jai";
#load "positioning.jai";

#import "Basic";
#import "Compiler";
#import "Hash_Table";
#import "Math";
#import "Sort";
#import "String";

Window_Creation :: #import "Window_Creation";
Simp :: #import "Simp";
Input :: #import "Input";
