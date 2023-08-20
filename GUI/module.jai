#module_parameters (
    MANUAL_END_FRAME := false  // Normally gui_begin_frame will call gui_end_frame for you; you can disable
                               // that with this (though you then *must* call gui_end_frame yourself!)
);

#load "GUI.jai";
#load "default_skin.jai";

#load "positioning.jai";
#load "panel.jai";

#import "Hash_Table";
#import "Basic";
#import "Compiler";
#import "Math";
#import "Sort";
#import "String";

Window_Creation :: #import "Window_Creation";
Simp :: #import "Simp";
Input :: #import "Input";
