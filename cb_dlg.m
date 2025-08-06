
function cb_dlg(hfg, event, varargin)

ui.v = event.Source.String{event.Source.Value};
hfg.UserData = ui;

end