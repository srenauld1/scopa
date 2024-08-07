
function pltexp_key_press_fcn(src, event)

eventkey = event.Key;
% if ispc && strcmpi(eventkey, '0')
%     eventkey = 'reutrn';
% end
eventmod = event.Modifier;
src.UserData = eventkey;

