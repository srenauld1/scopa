
function pltexp_dlgcb_fcn(hfg, event, varargin)

ui.v = event.Source.String{event.Source.Value};
hfg.UserData = ui;

end