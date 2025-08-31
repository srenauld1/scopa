function [cbflag, inew, ttl, dm, domean] = cb_idx(currkey, opt)

% process sequence of keypress callbacks to create and output a numeric vector, inew
% if semicolon is included, inew is cell, otherwise ordinary array

arguments (Input)
    currkey %current keypress
    opt.superset %inew superset (ie if any element of inew is not; if semicolon is listed in context_keys (ie inew can be multiple vectors), superset can be nonscalar (cell or ordinary array), one element for each inew vector; if superset is scalar, it is applied to all inew vectors
    opt.numvec = [] %required number of vectors; if empty, can be any number
    opt.veclen = [] %required length of each vector; if empty, can be any number
    opt.veclenmax = [] %max allowed length of inew; if semicolon is listed in context_keys (ie inew can be multiple vectors), veclenmax can be nonscalar (cell or ordinary array), one element for each inew vector; if veclenmax is scalar, it is applied to all inew vectors
end
arguments (Output)
    cbflag %struct holding callback flags (state switches)
    inew % output indices, can be same as input inew, or different
    ttl %text showing current state of keypresses
    dm %dimension inew belongs to
    domean %1 is flag to take mean of selected indices, 0 to not
end
numvec = opt.numvec;
superset = opt.superset;
veclen = opt.veclen;
veclenmax = opt.veclenmax;

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
persistent dmtmp


if iscell(superset)
    if any(~cellfun(@isvector, superset) & ~cellfun(@isempty, superset))
        error("if superset is cell, each element must be vector or empty")
    end
else
    if ~isvector(superset) && ~isempty(superset)
        error("if superset is not cell, it must be vector or empty")
    end
    superset = {superset};
end
if iscell(veclenmax)
    veclenmax = cell2mat(veclenmax);
end
if iscell(veclen)
    veclen = cell2mat(veclen);
end
elongate_superset = 0;
if isscalar(superset)
    if isempty(numvec)
        elongate_superset = 1;
    else
        superset = repelem(superset, numvec); %if numvec is specified, we can repeat scalar superset to match numvec length; if numvec is empty, superset gets elongated as vectors are added (ie with each semicolon, if semicolon is listed in context_keys)
    end
end
elongate_maxn = 0;
if isscalar(veclenmax)
    if isempty(numvec)
        elongate_maxn = 1;
    else
        veclenmax = repelem(veclenmax, numvec); %if numvec is specified, we can repeat scalar veclenmax to match numvec length; if numvec is empty, superset gets elongated as vectors are added (ie with each semicolon, if semicolon is listed in context_keys)
    end
end
elongate_veclen = 0;
if isscalar(veclen)
    if isempty(numvec)
        elongate_veclen = 1;
    else
        veclen = repelem(veclen, numvec); %if numvec is specified, we can repeat scalar veclenmax to match numvec length; if numvec is empty, superset gets elongated as vectors are added (ie with each semicolon, if semicolon is listed in context_keys)
    end
end


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

    dmtmp = []; %empty by default
    context_keys = {nm, 'return', 'escape', 'comma', 'semicolon_shift', 'hyphen'};
    if strcmp(nm, 'c') %copy roi to specified iz (z indices)
        context_keys = cat(2, context_keys, {}); %nothing to add here yet
    elseif strcmp(nm, 't') %change it (t indices)
        context_keys = cat(2, context_keys, {'slash'}); %allow slash (averaging)
        dmtmp = 4; %dimension inew belongs to
    elseif strcmp(nm, 'z') %change iz (z indices)
        context_keys = cat(2, context_keys, {'slash'}); %allow slash (averaging)
        dmtmp = 3; %dimension inew belongs to
    elseif strcmp(nm, 'backspace') %delete {irsub,ir}, that is, {subroi index, roi index}
        context_keys = cat(2, context_keys, {'semicolon'}); %allow semicolon (multiple vectors, semicolon separates vectors)
    end

end

if isempty(slash_pressed)
    slash_pressed = 0; %can't be empty because it gets assigned an element of vector
end
inew = []; %empty unless successful exit
ttltmp2 = [];
exit_sequence = 0;
init_sequence = 0;
init_vec_sequence = 0;

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
    elseif strcmpi(currkey, 'escape')
        exit_sequence = 1;
        cbflagtmp = flagset(0);
    elseif strcmpi(currkey, 'hyphen')
        if isequal(prevkey, nm) || isequal(prevkey, 'slash')
            hyphen_pressed = 1;
        else
            currkeyp.isvalid = 0;
        end
    elseif strcmpi(currkey, 'return') || strcmpi(currkey, 'semicolon')
        numvec_curr = numel(inewtmp2)+1;
        superset = matchargs(numvec_curr, superset, elongate_superset);
        veclenmax = matchargs(numvec_curr, veclenmax, elongate_maxn);
        veclen = matchargs(numvec_curr, veclen, elongate_veclen);
        if isempty(inewtmp) && isempty(digitstr)
            if isempty(veclenmax) || numel(superset{end})<=veclenmax(end) || slash_pressed
                ttltmp2 = 'EMPTY (ALL)';
                inewtmp = superset{end};
            else
                ttltmp2 = ['EMPTY (FIRST ' num2str(veclenmax(end)) ' INDICES, ie MAX ALLOWED)'];
                inewtmp = 1:veclenmax(end);
            end
            if strcmpi(currkey, 'semicolon')
                ttltmp2 = cat(2, ttltmp2, '; ');
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
        if ~exit_sequence %if exit_sequence wasn't triggered with error, begin exit_sequence here
            inewtmp = idxmake(inewtmp, superset=superset{end});
            if ~isempty(veclenmax) && numel(inewtmp)>veclenmax(end) && ~slash_pressed
                if numvec_curr==1
                    ttltmp2 = ['YOU HAVE REQUESTED MORE ' nm ' INDICES (' num2str(numel(inewtmp)) ') THAN ALLOWED (' num2str(veclenmax(end)) '), ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                else
                    ttltmp2 = ['IN VECTOR ' num2str(numvec_curr) ' YOU HAVE REQUESTED MORE ' nm ' INDICES (' num2str(numel(inewtmp)) ') THAN ALLOWED (' num2str(veclenmax(end)) '), ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                end
                currkeyp.isvalid = 0;
            elseif any(~ismember(inewtmp, superset{end}))
                if numvec_curr==1
                    ttltmp2 = ['YOU HAVE REQUESTED ' nm ' INDICES OUTSIDE RANGE, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                else
                    ttltmp2 = ['IN VECTOR ' num2str(numvec_curr) ' YOU HAVE REQUESTED ' nm ' INDICES OUTSIDE RANGE, ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                end
                currkeyp.isvalid = 0;
            else %success
                if ~isempty(veclen) && numel(inewtmp)~=veclen(end)
                    ttltmp2 = ['IN VECTOR ' num2str(numvec_curr) ' VECTOR LENGTH (' num2str(numel(inewtmp)) ') DOES NOT MATCH VECLEN (' num2str(veclen(end)) ') '  nm ' SELECTION EXITED WITHOUT CHANGE'];
                    exit_sequence = 1;
                end
                if ~exit_sequence %if exit_sequence wasn't triggered with error,
                    if isempty(inewtmp2)
                        inewtmp2 = {inewtmp};
                    else
                        inewtmp2 = cat(1, inewtmp2, inewtmp);
                    end
                    if strcmpi(currkey, 'semicolon')
                        init_vec_sequence = 1;
                    elseif strcmpi(currkey, 'return')
                        if ~isempty(numvec) && numel(inewtmp2)~=numvec
                            ttltmp2 = ['NUMBER VECTORS DOES NOT MATCH NUMVEC (' num2str(numvec) ') ' nm ' SELECTION EXITED WITHOUT CHANGE'];
                            currkeyp.isvalid = 0;
                        else
                            if isscalar(inewtmp2)
                                inewtmp2 = cell2mat(inewtmp2);
                            end
                            inew = inewtmp2;
                            cbflagtmp = flagset(0);
                        end
                        exit_sequence = 1;
                    end
                end
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
domean = slash_pressed;
dm = dmtmp;

if exit_sequence || init_sequence || init_vec_sequence %depending on sequence state, clear different sets of persistent variables, but only after setting above output variables
    digitstr = [];
    inewtmp = [];
    colon_pressed = [];
    hyphen_pressed = [];
    slash_pressed = [];
    if exit_sequence || init_sequence
        inewtmp2 = [];
        if exit_sequence
            prevkey = [];
            prevkeyp = [];
            ttltmp = [];
            nm = [];
            cbflagtmp = [];
            context_keys = [];
            dmtmp = [];
        end
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


function x = matchargs(numvec_curr, x, elongate)

if ~isempty(x)
    if elongate %if x was scalar when input and numvec was empty
        if numel(x)~=numvec_curr
            x(end+1) = x;
        end
    else
        if numel(x)~=numvec_curr
            error("numel(" + inputname(2) + ") does not match number of vectors you made for inew")
        end
    end
end

end
