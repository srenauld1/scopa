function cb_key(src, event)

%{
callback function to capture keypress
keypress written to char vector in field UserData of src
in case there are modifiers keys pressed (shift, control, alt/option) along with non-modifiers (everything else), 
src.UserData char vector is in reverse order of keys pressed, with modifier_delimiter separating all keys; 
we do this (rather than making callback a struct with event and modifier fields) to simplify interpretation outside this function;
we use plus symbol as modifier_delimiter because it is meaningful in this context, and also underscore needs to be escaped to print properly (or make interpreter 'none');
%}

modifier_delimiter = '+';  

if ispc && strcmpi(event.Key, '0')
    event.Key = 'reutrn';
end
if ~isempty(event.Modifier) && ~isequal(event.Modifier, event.Key) 
    src.UserData = [event.Key sprintf([modifier_delimiter '%s'] , event.Modifier{:})]; %expand all modifiers, precede with underscore to concatenate with main key 
else
    src.UserData = [event.Key];
end
