
function cb_key(src, event)

% if ispc && strcmpi(event.Key, '0')
%     event.Key = 'reutrn';
% end
% eventmod = event.Modifier;
% if ~isempty(eventmod) %right now callback cannot wait until key release, so not using modifier keys yet
%     src.UserData = [event.Key '_' eventmod];
% else
%     src.UserData = [event.Key];
% end
src.UserData = event.Key;
