
function uikeypress(src, event)

eventkey = event.Key;
% if ispc && strcmpi(eventkey, '0')
%     eventkey = 'reutrn';
% end
% eventmod = event.Modifier;
% if ~isempty(eventmod) %right now callback cannot wait until key release, so not using modifier keys yet
%     src.UserData = [eventkey '_' eventmod];
% else
%     src.UserData = [eventkey];
% end
src.UserData = eventkey;
