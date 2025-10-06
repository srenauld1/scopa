


function [out, cbflag, ttl_action, ttl_validkeys] = cb_array(currkey, opt)

% process sequence of keypress callbacks to create and output a numeric vector, out
% if semicolon is included, out is cell, otherwise ordinary array
% p suffix in variable name denotes persistent variables that also have non-persistent versions (same name without p suffix, often because the latter are output variables, which persistent cannot be)

arguments (Input)
    currkey %current keypress
    opt.keydict = []
    opt.superset = [] %out superset (ie if any element of out is not; if semicolon is listed in validkeys (ie out can be multiple vectors), superset can be nonscalar (cell or ordinary array), one element for each out vector; if superset is scalar, it is applied to all out vectors
    opt.numvec = [] %required number of vectors (separate each with semicolon); if empty, can be any number
    opt.veclen = [] %required length of each vector; if empty, can be any length
    opt.dounique = 0 % if 1, out = unique(out, 'stable'), if 0, repeats allowed
    opt.initkey = []
end
arguments (Output)
    out % output indices, can be same as input out, or different
    cbflag %struct holding callback flags (state switches)
    ttl_action %text showing current state of keypresses
    ttl_validkeys %valid context keys (digits are also valid
end
keydict = opt.keydict;
superset = opt.superset;
numvec = opt.numvec;
veclen = opt.veclen;
dounique = opt.dounique;
initkey = opt.initkey;

persistent digitstr
persistent outp
persistent outp2
persistent colon_pressed
persistent hyphen_pressed
persistent plus_pressed
persistent i_pressed
persistent slash_pressed %currently not using this but keeping the code for it
persistent prevkey
persistent ttl_actionp
persistent ttl_validkeysp
persistent initkeyp
persistent cbflagp
persistent validkeys
persistent validkeys_nmprint
persistent keydictp
persistent keylog

invalidstr = '  INVALID';
bookend_symbol = ' ||| '; %to bookend the printed callback record (shouldn't be any of the validkeys of course

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
if iscell(veclen)
    veclen = cell2mat(veclen);
end
elongate_superset = 0;
if isscalar(superset)
    if isempty(numvec)
        elongate_superset = 1;
    else
        superset = repelem(superset, numvec); %if numvec is specified, we can repeat scalar superset to match numvec length; if numvec is empty, superset gets elongated as vectors are added (ie with each semicolon, if semicolon is listed in validkeys)
    end
end
elongate_veclen = 0;
if isscalar(veclen)
    if isempty(numvec)
        elongate_veclen = 1;
    else
        veclen = repelem(veclen, numvec); %if numvec is specified, we can repeat scalar veclen to match numvec length; if numvec is empty, superset gets elongated as vectors are added (ie with each semicolon, if semicolon is listed in validkeys)
    end
end

if isempty(prevkey)

    if isempty(flagset)
        if isempty(initkey)
            error("if you have not set cb flags with flagset, you must pass in name-value argument 'initkeyp'")
        end
        cbflagp = flagset(initkey, [0,1], init=1, me=1);
        cbflagp = flagset(initkey, 1);
    else
        if ~isempty(initkey)
            error("if you already set cb flags with flagset, you cannot pass in name-value argument 'initkeyp'")
        end
        cbflagp = flagset(currkey, 1);
    end
    fntrue = cellfun(@(x) isequal(x,1), struct2cell(cbflagp)); % find the one field of struct 'initkeyp' that is true
    initkeyp = fieldnames(cbflagp);
    initkeyp = initkeyp(fntrue);
    if isscalar(initkeyp)
        initkeyp = cell2mat(initkeyp);
    else
        error("only one field of struct initkeyp can be true")
    end

    keydictdf = {  ... %default keydict; any passed in as name-value argument keydict must follow this pattern; cell vector, each element is itself a cell of length 1, 2, or 3, and each of these nested cells must contain a char vector (not a string, and not []); 1st element is key name (for code to identify the key pressed in callback); if present, 2nd element is key name for printing on a figure; if present, 3rd element is key function description (eg for printing on a figure); for example, {'comma', ',', 'separate elements'}; if 1 element, the key print name is given the key true name and key function description is omitted; if 2 elements, key function description is omitted; when printing, 3rd element is placed in parentheses by default
        {initkeyp, initkeyp, 'init'}, ...
        {'return', ' return ', 'finish'}, ...
        {'escape', ' escape ', 'exit'}, ...
        {'^(\d+):(\d+)$', 'x:y', 'range'}, ...
        };

    if isempty(keydict) %use default keydict if none passed in
        keydictp = keydictdf;
    else
        keydictp = keydict;
    end

    dict_incorrectly_formatted = any(~cellfun(@(x) isvector(x) & numel(x)>=1 & numel(x)<=3, keydictp), 'all');
    if dict_incorrectly_formatted || ~iscell(keydictp) || ~all(cellfun(@iscell, keydictp)) || ~isvector(keydictp) || ~all(cellfun(@ischar, cellflat(keydictp)))
        error("keydict must be cell vector (any length), each element a cell vector of length 1, 2, or 3")
    end

    for k = 1:numel(keydictp)
        if numel(keydictp{k})<3
            keydictp{k}{3} = '';
        end
        if isempty(keydictp{k}{2})
            keydictp{k}{2} = keydictp{k}{1};
        end
    end
    validkeys = cellfun(@(x) x{1}, keydictp, 'UniformOutput', false);
    validkeys_nmprint = cellfun(@(x) x{2}, keydictp, 'UniformOutput', false);
    ttl_validkeysp = cell(1, numel(keydictp));
    for k = 1:numel(keydictp)
        if isempty(keydictp{k}{3})
            ttl_validkeysp{k} = keydictp{k}{1};
        else
            ttl_validkeysp{k} = strcat(keydictp{k}{1}, ' (', keydictp{k}{3}, ')');
        end
    end
    ttl_validkeysp = sprintf('%s, ', ttl_validkeysp{:});
    ttl_validkeysp = ttl_validkeysp(1:end-2); %remove 2 because of trailing comma and whitespace
    ttl_validkeysp = ['VALID KEYS: ' ttl_validkeysp];

end


out = []; %empty unless successful exit
ttl_problem = [];
ttltmp_empty = [];
exit_sequence = 0;
init_sequence = 0;
init_vec_sequence = 0;

if isequal(currkey, initkeyp) %when you press init key to restart the sequence, clear all persistent variables (can't clear this from within calling function roidraw, matlab bug)
    init_sequence = 1;
    currkey_isvalid = 1;
elseif strcmpi(currkey, 'escape')
    exit_sequence = 1;
elseif strcmpi(currkey, 'return')

    keylog = erase(keylog, ' '); %remove all whitespace
    keylog = erase(keylog, ' '); %remove all whitespace
    if contains(keylog, ';')
        if ~startsWith(keylog, '{')
            keylog = ['{' keylog]; %put opening bracket in if omitted and contains semicolon
        end
        if ~endsWith(keylog, '{')
            keylog = [keylog '}']; %put closing bracket in if omitted and contains semicolon
        end
    end
    if ~isempty(regexp('{1]', '{(?=.*\]$)|[(?=.*\}$)'), 'once')
        ttl_problem = 'ARRAY BEGINS AND ENDS WITH DIFFERENT GROUPING SYMBOLS';
    end
    keylog = join(regexp(keylog, '{}', 'split'),'{[]}'); %insert [] between any '{}'
    keylog = join(regexp(keylog, '{;', 'split'),'{[];'); %insert [] between any '{;'
    keylog = join(regexp(keylog, ';}', 'split'),';[]}'); %insert [] between any ';}'
    keylog = join(regexp(keylog, ';;', 'split'),';[];'); %insert [] between any ';;'

    tmp = regexp(keylog, '{(.*)}', 'tokens');
    for k = 1:numel(tmp)
        tmp{k} = cellpr(tmp{k});
    end
    exit_sequence = 1;
else
    keylog = [keylog currkey];

    '^(\[|{)\d((:\s*|,\s*|;\s*)\d)*(\]|})$';

end



if isempty(ttl_problem) %ttl_problem is for problem messages
    if ~init_sequence
        ttl_actionp = erase(ttl_actionp, invalidstr);
    end
    if currkey_isvalid %cat current key with all previous (valid) keys
        nmprint = validkeys_nmprint(~cellfun(@isempty, cellfun(@(x) regexp(currkey, sprintf('^%s$|', x)), validkeys, 'UniformOutput', false))); %find which of validkeys currkey matches, and grab the corresponding nmprint (name for printing in figure)
        if numel(nmprint)~=1
            error("only one element from validkeys should match currkey")
        end
        nmprint = nmprint{1}; %it must be scalar so this is fine
        if currkey_isdigit
            nmprint = currkey;
        end
        if init_sequence
            nmprint = [nmprint bookend_symbol];
        else
            if endsWith(ttl_actionp, bookend_symbol)
                ttl_actionp = ttl_actionp(1:end-numel(bookend_symbol));
            end
        end

        ttl_actionp = [ttl_actionp ttltmp_empty nmprint bookend_symbol];
    else
        ttl_actionp = [ttl_actionp invalidstr];
    end

else
    ttl_actionp = [ttl_problem  ', ' initkeyp ' SELECTION EXITED WITHOUT CHANGE'];
end

if exit_sequence
    cbflagp = flagset(0); %set active flag to 0 (inactive) when exiting
end
ttl_action = ttl_actionp;
ttl_validkeys = ttl_validkeysp;
cbflag = cbflagp;

digitstr = [];

if exit_sequence || init_sequence || init_vec_sequence %depending on sequence state, clear different sets of persistent variables, but only after setting above output variables
    outp = [];
    colon_pressed = [];
    hyphen_pressed = [];
    slash_pressed = [];
    if exit_sequence || init_sequence
        outp2 = [];
        if exit_sequence
            prevkey = [];
            ttl_actionp = [];
            initkeyp = [];
            cbflagp = [];
            validkeys = [];
        end
    end
end

end


function [x, ttl_problem, exit_sequence] = colon_op(x)

if x(end)<x(end-1)
    ttl_problem = 'SMALLER NUMBER FOLLOWED COLON';
    exit_sequence = 1;
else
    if numel(x)==2
        x = x(1):x(2);
    else
        x = [x(1:end-2) x(end-1):x(end)];
    end
    ttl_problem = '';
    exit_sequence = 0;
end

end


function [x, ttl, exit_sequence] = matchargs(numvec_curr, x, elongate)

ttl = '';
exit_sequence = 0;
if ~isempty(x)
    if elongate %if x was scalar when input and numvec was empty
        if numel(x)~=numvec_curr
            x(end+1) = x;
        end
    else
        if numel(x)~=numvec_curr
            ttl = ['numel(' convertStringsToChars(inputname(2)) ') does not match number of vectors you made for out'];
            exit_sequence = 1;
        end
    end
end

end


function cellpr(s)
    tmp = regexp(s, '{(.*)}', 'tokens');
    for k = 1:numel(tmp)
        tmp{k} = cellpr(tmp{k});
    end
end