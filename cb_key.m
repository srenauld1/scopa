
function cb_key(src, event)

% in case there are modifiers keys pressed (control, alt/option, shift) along with non-modifiers, src.UserData is in reverse order of keys pressed, with double underscore separating 

if ispc && strcmpi(event.Key, '0')
    event.Key = 'reutrn';
end
if ~isempty(event.Modifier) && ~isequal(event.Modifier, event.Key) 
    src.UserData = [event.Key sprintf('_%s' , event.Modifier{:})]; %expand all modifiers, precede with underscore to concatenate with main key 
else
    src.UserData = [event.Key];
end
