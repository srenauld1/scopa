function [cbflag, inew, ttl, dmslash] = cb_idx(currkey, n, maxn, dmslash)

% process sequence of keypress callbacks to create and output a numeric vector, inew
% if semicolon is included, inew is cell, otherwise ordinary array

arguments (Input)
    currkey %current keypress
    n %number elements in array we are making indices for
    maxn = [] %max allowed length of inew
    dmslash = [] %whether to average each stack dimension
end
arguments (Output)
    cbflag %struct holding callback flags (state switches)
    inew % output indices, can be same as input inew, or different
    ttl %text showing current state of keypresses
    dmslash %1 is flag to take mean of selected indices, 0 to not
end

persistent digitstr
persistent inewtmp
persistent inewtmp2
persistent colon_pressed
persistent hyphen_pressed
persistent slash_pressed
persistent prevkey
persistent prevkeyp
persistent ttltmp
persistent nm
persistent cbflagtmp
persistent context_keys
persistent dm

if isempty(prevkey)

    cbflagtmp = flagset(currkey, 1);
    nmtrue = cellfun(@(x) isequal(x,1), struct2cell(cbflagtmp)); % find the one field of struct 'nm' that is true
    nm = fieldnames(cbflagtmp);
    nm = nm(nmtrue);
    if isscalar(nm)
        nm = cell2mat(nm);
    else
        error("only one field of struct nm can be true")
    end

    dm = []; %empty by default
    context_keys = {nm, 'return', 'escape', 'comma', 'semicolon_shift', 'hyphen'};
    if strcmp(nm, 'c') %copy roi to specified iz (z indices)
        context_keys = cat(2, context_keys, {}); %nothing to add here yet
    elseif strcmp(nm, 't') %change it (t indices)
        context_keys = cat(2, context_keys, {'slash'}); %allow slash (averaging)
        dm = 4; %dimension of stack being modified
    elseif strcmp(nm, 'z') %change iz (z indices)
        context_keys = cat(2, context_keys, {'slash'}); %allow slash (averaging)
        dm = 3; %dimension of stack being modified
    elseif strcmp(nm, 'backspace') %delete {irsub,ir}, that is, {subroi index, roi index}
        context_keys = cat(2, context_keys, {'semicolon'}); %allow semicolon (multiple vectors, semicolon separates vectors)
    end

end

if isempty(slash_pressed)
    slash_pressed = 0; %can't be empty because it gets assigned an element of vector dmslash
end
inew = []; %empty unless successful exit
ttltmp2 = [];
exit_sequence = 0;
init_sequence = 0;

currkeyp = keyprop(currkey, context_keys); %get currkey properties

if currkeyp.isvalid

    if currkeyp.isdigit
        digitstr = [digitstr currkey];
    elseif isequal(currkey, nm) %when you press init key to restart the sequence, clear all persistent variables (can't clear this from within calling function roidraw, matlab bug)
        init_sequence = 1;
    elseif strcmpi(currkey, 'comma')
        if prevkeyp.isdigit && ~isequal(hyphen_pressed,1)
            inewtmp = [inewtmp str2double(digitstr)];
            if colon_pressed %ouch!
                [inewtmp, ttltmp2, colon_pressed, exit_sequence, currkeyp] = colon_op(inewtmp, nm, currkeyp);
            end
            digitstr = [];
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'semicolon')
        if prevkeyp.isdigit
            inewtmp = [inewtmp str2double(digitstr)];
            if colon_pressed %ouch!
                [inewtmp, ttltmp2, colon_pressed, exit_sequence, currkeyp] = colon_op(inewtmp, nm, currkeyp);
            end
            if isempty(inewtmp2)
                inewtmp2 = inewtmp;
            else
                inewtmp2 = {inewtmp2; inewtmp};
            end
            inewtmp = []; %reset inewtmp if making multiple vectors (if semicolon is allowed and used)
            digitstr = [];
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'escape')
        exit_sequence = 1;
        cbflagtmp = flagset(0);
    elseif strcmpi(currkey, 'hyphen')
        if isequal(prevkey, nm) || isequal(prevkey, 'slash')
            hyphen_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'return')
        if isempty(inewtmp) && isempty(digitstr)
            if isempty(maxn) || n<=maxn || slash_pressed
                ttltmp2 = ['YOU PRESSED return WITHOUT ENTERING ' nm  ' INDICES, USING ALL INDICES'];
                inewtmp = 1:n;
            else
                ttltmp2 = ['YOU PRESSED return WITHOUT ENTERING ' nm  ' INDICES, USING FIRST ' num2str(maxn) ' INDICES (DEFAULT)'];
                inewtmp = 1:maxn;
            end
        end
        if ~isempty(digitstr)
            if hyphen_pressed
                digitstr = ['-' digitstr];
            end
            inewtmp = [inewtmp str2double(digitstr)];
            if colon_pressed %ouch!
                [inewtmp, ttltmp2, colon_pressed, exit_sequence, currkeyp] = colon_op(inewtmp, nm, currkeyp);
            end
        end
        if ~exit_sequence
            inewtmp = indsmake(inewtmp, indsall=n);
            if isempty(inewtmp2)
                inewtmp2 = {inewtmp};
            else
                inewtmp2 = {inewtmp2; inewtmp};
            end
            if ~isempty(maxn) && numel(inewtmp2)>maxn && ~slash_pressed
                ttltmp2 = ['YOU HAVE REQUESTED MORE ' nm ' INDICES (' num2str(numel(inewtmp2)) ') THAN ALLOWED (' num2str(maxn) '), ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                currkeyp.isvalid = 0;
            elseif any(~ismember(inewtmp2, 1:n))
                ttltmp2 = ['YOU HAVE REQUESTED ' nm ' INDICES OUTSIDE STACK RANGE, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                currkeyp.isvalid = 0;
            else %success
                inew = inewtmp2;
                exit_sequence = 1;
                cbflagtmp = flagset(0);
            end
        end
    elseif strcmpi(currkey, 'semicolon_shift') %semicolon_shift is colon
        if prevkeyp.isdigit && ~isequal(hyphen_pressed,1)
            inewtmp = [inewtmp str2double(digitstr)];
            digitstr = [];
            colon_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'slash') %forward slash
        if isequal(prevkey, nm)
            slash_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    end

    prevkey = currkey;
    prevkeyp = currkeyp;

end

if isempty(ttltmp2) %ttletmp2 is for exit sequence messages
    if init_sequence %reset title if init_sequence
        ttltmp = [nm ' '];
    elseif exit_sequence %clear title if exit sequence
        ttltmp = [];
    else %otherwise concatenate current key with all previous keys
        ttltmp = erase(ttltmp, 'INVALID KEY');
        ttltmp = [ttltmp key2str(currkey, currkeyp)];
    end
else
    ttltmp = ttltmp2;
end

ttl = ttltmp;
cbflag = cbflagtmp;
if ~isempty(dmslash)
    dmslash(dm) = slash_pressed;
end

if exit_sequence || init_sequence %clear these after setting above output variables
    digitstr = [];
    inewtmp = [];
    inewtmp2 = [];
    colon_pressed = [];
    hyphen_pressed = [];
    slash_pressed = [];
    if exit_sequence
        prevkey = [];
        prevkeyp = [];
        ttltmp = [];
        nm = [];
        cbflagtmp = [];
        context_keys = [];
        dm = [];
    end
end

end


function [inds, ttl2, colon_pressed, exit_sequence, currkeyp] = colon_op(inds, nm, currkeyp)

ttl2 = '';
colon_pressed = 0;
exit_sequence = 0;
if inds(end)<inds(end-1)
    ttl2 = ['SMALLER NUMBER FOLLOWED COLON, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
    currkeyp = keyprop('INVALIDDUMMYINPUTBLAH80768678679787567', {});
    exit_sequence = 1;
else
    if numel(inds)==2
        inds = inds(1):inds(2);
    else
        inds = [inds(1:end-2) inds(end-1):inds(end)];
    end
end

end

function x = key2str(x, keyp) %translate keypress to string for display

if keyp.isvalid %if it's not a single digit or alphabetic character or return key, translate, otherwise no need
    switch x
        case 'semicolon_shift'
            x = ':';
        case 'semicolon'
            x = ';';
        case 'comma'
            x = ',';
        case 'hyphen'
            x = '- (NUM EQUISPACED INDICES) ';
        case 'slash'
            x = '/ (MEAN OF) ';
        case 'return'
            x = ' return '; %return with space before and after
    end
else
    x = 'INVALID KEY'; %redundant with if statement outside this function, but just in case
end

end

function keypr = keyprop(key, context_keys)

if isempty(key)
    keypr.isempty = true;
    keypr.isdigit = false;
    keypr.iscontext = false;
    keypr.isvalid = false;
else
    keypr.isempty = false;
    keypr.isdigit = ~isempty(regexp(key, '^[0-9]{1}$', 'once'));
    keypr.iscontext = ~isempty(regexp(key, sprintf('^%s$|', context_keys{:}), 'once'));
    keypr.isvalid = logical(keypr.isdigit + keypr.iscontext);
end

end
