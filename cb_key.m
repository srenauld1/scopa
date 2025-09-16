function cb_key(src, event, opt)

%{

callback function to capture keypress
keypress written to char vector in field UserData of src
if cbshort=0 (default) . . . 
    when there are modifiers keys pressed (shift, control, alt/option) along with non-modifiers (everything else), 
    src.UserData char vector concatenates all keys, delimited by hard-coded character set by variable 'delim'
    this function returns one char vector (rather than, for example, a struct with key and modifier fields) to simplify keypress interpretation (can use a single function, strcmp, to detect target keypress);
    regardless of the order in which the keys were pressed, output will be in the following order: order shift, control, alt/option, non-modifier    
    if only modifier keys are pressed, they appear on their own (they do not also appear as the non-modifier) we use plus symbol as delim because it is meaningful in this context (multiple keys pressed) 
    note: recommend not use an underscore as delim, because it needs to be escaped to print properly (or interpreter needs to be set to 'none');
    note: as of 2025, command key on mac has been problematic in this function, so carl has avoided using it  
if cbshort=1 . . . 
    callback keys are converted to their short name (if one exists); for example, 'shift+semicolon' is converted to 'colon'; 

%}

arguments
    src
    event
    opt.cbshort = 0
end
cbshort = opt.cbshort;

delim = '+';

tmpkey = event.Key; %copy to keytmp since event.Key is read only and we might have to change it below
if isempty(event.Modifier)
    tmpmod = '';
else
    tmpmod = event.Modifier;
end
if ispc && strcmp(tmpkey, '0')
    tmpkey = 'return';
end
if ismember(tmpkey, tmpmod)
    tmpkey = ''; %we don't care to repeat modifier as the non-modifier
end
if isempty(tmpmod)
    src.UserData = tmpkey; %expand all modifiers, precede with underscore to concatenate with main key
else
    src.UserData = [sprintf(['%s' delim], tmpmod{:}) tmpkey]; %expand all modifiers, precede with underscore to concatenate with main key
end
if endsWith(src.UserData, delim) %in case keytmp is empty/gets deleted
    src.UserData = src.UserData(1:end-1);
end
if cbshort %use full name if cbshort=0, or if short name is not defined in switch block below
    switch src.UserData %add to this as you need more keys (is there a function for doing this conversion already?)
        case 'comma'
            src.UserData = ',';
        case 'period'
            src.UserData = '.';
        case 'semicolon'
            src.UserData = ';';
        case 'shift+semicolon'
            src.UserData = ':';
        case 'shift+equals'
            src.UserData = '+';
        case 'hyphen'
            src.UserData = '-';
    end
end
