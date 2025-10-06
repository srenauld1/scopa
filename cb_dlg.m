
function cb_dlg(hfg, event, varargin)

cb.v = event.Source.String{event.Source.Value};
hfg.UserData = cb;

end