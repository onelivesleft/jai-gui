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
#if OS == .WINDOWS  #import "Windows";