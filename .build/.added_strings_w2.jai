// Workspace: Target Program
//
// #insert text. Generated from c:/repos/jai-gui/./GUI/GUI.jai:173.
//
                if widget >= xx panel_data.data && widget < xx (panel_data.data + panel_data.count)  return Panel;
                if widget >= xx button_data.data && widget < xx (button_data.data + button_data.count)  return Button;
                if widget >= xx checkbox_data.data && widget < xx (checkbox_data.data + checkbox_data.count)  return Checkbox;
                if widget >= xx label_data.data && widget < xx (label_data.data + label_data.count)  return Label;
                if widget >= xx scrollbar_data.data && widget < xx (scrollbar_data.data + scrollbar_data.count)  return Scrollbar;

//
// #insert text. Generated from c:/repos/jai-gui/./GUI/GUI.jai:50.
//
                panel_data = NewArray(panel_count, Panel);
                button_data = NewArray(button_count, Button);
                checkbox_data = NewArray(checkbox_count, Checkbox);
                label_data = NewArray(label_count, Label);
                scrollbar_data = NewArray(scrollbar_count, Scrollbar);
