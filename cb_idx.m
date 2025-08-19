function [cbflag, inew, ttl, success, dmslash] = cb_idx(cbflag, inew, currkey, dmslash, n, maxn)

% process sequence of keypresses to create/output a numeric vector, inew, representing indices

arguments (Input)
    cbflag %struct holding callback flags (state switches)
    inew %original indices to be modified by this function
    currkey %current keypress
    dmslash %whether to average each stack dimension
    n %number elements in array we are making indices for
    maxn %max allowed length of inew
end
arguments (Output)
    cbflag %struct holding callback flags (state switches)
    inew % output indices, can be same as input inew, or different
    ttl %text showing current state of keypresses
    success %flag indicating index creation was successful
    dmslash %1 is flag to take mean of selected indices, 0 to not
end

persistent digitstr
persistent inewtmp
persistent colon_pressed
persistent hyphen_pressed
persistent slash_pressed
persistent prevkey
persistent prevkeyp
persistent ttltmp
persistent nm

if isstruct(cbflag) %in case we allow char nm someday
    nmtrue = cellfun(@(x) isequal(x,1), struct2cell(cbflag)); % find the one field of struct 'nm' that is true
    nm = fieldnames(cbflag);
    nm = nm(nmtrue);
    if isscalar(nm)
        nm = cell2mat(nm);
    else
        error("only one field of struct nm can be true")
    end
end

if strcmp(nm, 'z')
    context_keys = {'z', 'return', 'escape', 'slash', 'comma', 'semicolon_shift', 'hyphen'};
    dm = 3; %dimension of stack being modified
elseif strcmp(nm, 'p') %project onto specified z
    context_keys = {'p', 'return', 'escape', 'slash', 'comma', 'semicolon_shift', 'hyphen'};
    dm = 3; %dimension of stack being modified
elseif strcmp(nm, 't')
    context_keys = {'t', 'return', 'escape', 'slash', 'comma', 'semicolon_shift', 'hyphen'};
    dm = 4; %dimension of stack being modified
end

if isempty(slash_pressed)
    slash_pressed = 0; %can't be empty becaude it gets assigned to one index of dmslash
end
ttltmp2 = [];
success = 0;
clear_persistent_vars = 0;

currkeyp = keyprop(currkey, context_keys); %get currkey properties

if isequal(currkey, nm) %when you press init key to restart the sequence, clear all persistent variables (can't clear this from within calling function roidraw, matlab bug)

    clear_persistent_vars = 1;

else

    if currkeyp.isdigit
        digitstr = [digitstr currkey];
    elseif strcmpi(currkey, 'comma')
        if prevkeyp.isdigit && ~isequal(hyphen_pressed,1)
            inewtmp = [inewtmp str2double(digitstr)];
            if colon_pressed %ouch!
                [inewtmp, ttltmp2, colon_pressed, clear_persistent_vars, currkeyp] = colon_op(inewtmp, nm, currkeyp);
            end
            digitstr = [];
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'escape')
        clear_persistent_vars = 1;
        cbflag.(nm) = 0; %turn off flag
    elseif strcmpi(currkey, 'hyphen')
        if isequal(prevkey, nm) || isequal(prevkey, 'slash')
            hyphen_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'return')
        if isempty(inewtmp) && isempty(digitstr)
            if isempty(maxn) || n<=maxn || ~isempty(slash_pressed)
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
                [inewtmp, ttltmp2, colon_pressed, clear_persistent_vars, currkeyp] = colon_op(inewtmp, nm, currkeyp);
            end
        end
        if ~clear_persistent_vars
            inewtmp = indsmake(inewtmp, indsall=n);
            if ~isempty(maxn) && numel(inewtmp)>maxn && isempty(slash_pressed)
                ttltmp2 = ['YOU HAVE REQUESTED MORE ' nm ' INDICES (' num2str(numel(inewtmp)) ') THAN ALLOWED (' num2str(maxn) '), ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                currkeyp.isvalid = 0;
            elseif any(~ismember(inewtmp, 1:n))
                ttltmp2 = ['YOU HAVE REQUESTED ' nm ' INDICES OUTSIDE STACK RANGE, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                currkeyp.isvalid = 0;
            else %success
                inew = inewtmp;
                success = 1;
                clear_persistent_vars = 1;
                cbflag.(nm) = 0; %turn off flag
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
        if isequal(prevkey, nm) && ~isequal(prevkey, 'p')
            slash_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    end

end


if currkeyp.isvalid
    prevkey = currkey;
    prevkeyp = currkeyp;
    if strcmp(currkey, nm) %reset if you press init key
        if strcmp(nm, 'p')
            ttltmp = [nm '(z) '];
        else
            ttltmp = [nm ' '];
        end
    elseif strcmp(currkey, 'escape') %empty if you press escape
        ttltmp = [];
    else %otherwise concatenate current key with all previous keys 
        ttltmp = [ttltmp key2str(currkey, currkeyp)];
    end
end

if isempty(ttltmp2)
    ttl = ttltmp;
else
    ttl = ttltmp2;
end

dmslash(dm) = slash_pressed;

if clear_persistent_vars
    digitstr = [];
    inewtmp = [];
    colon_pressed = [];
    hyphen_pressed = [];
    slash_pressed = [];
    if ~isequal(currkey, nm) %in case currkey is init key (nm), persistent vars just got cleared, but you need to set these to the init key
        nm = [];
        prevkey = [];
        prevkeyp = [];
        ttltmp = [];
    end
end



end


function [inds, ttl2, colon_pressed, clear_persistent_vars, currkeyp] = colon_op(inds, nm, currkeyp)

ttl2 = '';
colon_pressed = 0;
clear_persistent_vars = 0;
if inds(end)<inds(end-1)
    ttl2 = ['SMALLER NUMBER FOLLOWED COLON, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
    currkeyp = keyprop('INVALIDDUMMYINPUTBLAH80', {});
    clear_persistent_vars = 1;
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
        case 'comma'
            x = ',';
        case 'hyphen'
            x = '- (NUM EQUIDISTANT INDICES) ';
        case 'slash'
            x = '/ (MEAN OF) ';
        case 'return'
            x = ' return '; %return with space before and after
    end
else
    x = ''; %redundant with if statement outside this function, but just in case
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
