#module_parameters (
    BACKGROUND_DRAGS_OS_WINDOW := false,

    FONT_SANS  := "Montreal-Regular.ttf",
    FONT_SERIF := "CharisSIL-R.ttf",
    FONT_FIXED := "FantasqueSansMono-Regular.ttf",
    FONT_SANS_ALTERNATE  := "",
    FONT_SERIF_ALTERNATE := "",
    FONT_FIXED_ALTERNATE := "",
    FONT_ICONS := ""
);

#load "GUI.jai";
use_better_skin :: false;

#if use_better_skin {
    #load "fancy_skin.jai";
}
else {
    #load "default_skin.jai";
}

#load "icons.jai";
#load "positioning.jai";


is_iprof_attached :: #run -> bool {
    struct_info := cast(*Type_Info_Struct) type_of(context);
    found_iprof := false;
    for member: struct_info.members {
        if member.name == "_Iprof" {
            found_iprof = true;
            break;
        }
    }
    return found_iprof;
}
#load "profiling.jai";

#import "Basic";
#import "Clipboard";
#import "Compiler";
#import "Flat_Pool";
#import "Hash";
#import "Hash_Table";
#import "Math";
#import "Sort";
#import "String";

Simp :: #import "Simp";
#import "GL";
Input :: #import,dir "modules/Input";
Window_Creation :: #import,dir "modules/Window_Creation";


#scope_module


#if OS == .WINDOWS {
    #import "Windows";
    user32 :: #system_library "user32";
}
