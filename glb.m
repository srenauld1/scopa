function outp = glb(inp)

%{

set globals in three ways
        1)   a=2; b=3; glb(v=a, w=b)
        2)   glb(v=2, w=3)
        3)   a.v=2; a.w=3; glb(a)

get globals
    glb('v') will output global variable v, if it's been set
    in all 3 set cases above, glb('v') will return 2 and glb('w') will return 3
    you can only get one global at a time
    unless you call glb('all'), which will output a struct of all globals

remove all globals by calling
    clear glb
remove specific globals using -1 as first argument, followed by variables to remove, in two ways  
    1) glb(-1, 'v', 'w')
    2) glb(-1, {'v', 'w'})

you cannot set a global after it's already been set, unless you pass 1 as first argument (or clear that global variable)
    glb(1, v=99) will set global variable v to 99 (so will k.v=99; glb(1,k), for any struct k)

in general, if you prefer to use string, rather than char, you can, as long as you don't mix them for the same purpose in a single command 

%}


arguments (Repeating)
    inp
end

persistent gset



%%%%%% PROCESS OPTIONAL 'change' ARGUMENT %%%%%%

idxchange = find(cellfun(@isnumeric, inp));
if ismember(1, idxchange)
    if isscalar(inp)
        error("a single numeric input to glb does nothing")
    end
    change = inp{1};
    inp = inp(2:end);
    if isequal(change, -1)
        if isscalar(inp)
            if isstring(inp) || (iscell(inp) && isstring(inp{1}))
                inp = cellstr(inp);
            elseif iscell(inp{1}) && isstring(inp{1}{1})
                inp = cellstr(inp{1});
            end
        else
            idxstr = find(cellfun(@isstring, inp));
            if isequal(idxstr, 1:numel(inp)) %if variables for removal were listed as separate positional string arguments, put them into one cell to make code cleaner below
                for k = 1:numel(inp)
                    inp{k} = char(inp{k});
                end
            else
                idxchar = find(cellfun(@ischar, inp));
                if ~isequal(idxchar, 1:numel(inp)) %if variables for removal were listed as separate positional char arguments, put them into one cell to make code cleaner below
                    error("if removing globals, all must be in one cell of char or string, or all must be passed as positional char or string arguments")
                end
            end
        end
    end
else
    change = 0;
end

if ~ismember(change, [-1, 0, 1])
    error("optional first argument 'change' can only be -1, 0, or 1")
end
if ~isequal(change, 0) && isempty(gset)
    error("you are attempting to remove or change a global variable but no global variables exist")
end
if isequal(change, -1)
    inc = 1;
else
    inc = 2;
end


%%%%%% FORMAT ARGUMENTS %%%%%%

if isscalar(inp)
    if isequal(change, -1)
        if iscell(inp)
            if isstring(inp{1})
                inp = char(inp{1});
            elseif iscell(inp{1}) && isstring(inp{1}{1})
                inp = char(inp{1}{1});
            elseif iscell(inp{1})
                inp = inp{1};
            end
        else
            error("must be cell here")
        end
    else
        inp = inp{1};
        if ~( ischar(inp) || isstring(inp) || isstruct(inp) )
            fprintf("passing a single positional input to glb does nothing, unless you are retrieving a global with a char or string input, or passing name-value arguments as a single struct, or removing variables with optional first input set to -1" + newline);
            return;
        end
        if isstruct(inp)
            if isequal(change, -1)
                error("you are attempting to remove global variable(s), but have passed them as name-value arguments; use a string, or a cell array of char to list globals for removal")
            end
            fn = fieldnames(inp);
            inptmp = struct2cell(inp);
            inp = cell(numel(inptmp)*2, 1);
            for k = 1:numel(inptmp)
                inp{k*2-1} = fn{k};
                inp{k*2} = inptmp{k};
            end
        elseif isstring(inp)
            inp = char(inp);
        end
    end
else
    if mod(numel(inp), 2)==0
        idxstr = find(cellfun(@isstring, inp));
        if ~all(ismember(idxstr, 1:numel(inp)))
            error("name-value arguments to glb must be passed in format name=value, not 'name', 'value'")
        end
        % if isequal(change, -1)
        %     error("you are attempting to remove global variable(s), but have passed them as name-value arguments; use a string, or a cell array of char to list globals for removal")
        % end
    elseif mod(numel(inp), 2)==1
        error("all arguments must be name-value pairs, except optional numeric first argument, and option to pass all arguments as a single struct")
    end
end



%%%%%% SET OR GET GLOBALS %%%%%%


if iscell(inp) %setting globals
    if isempty(gset)
        gset = struct;
    end
    if isempty(inp)
        fprintf("your input to 'glb' does nothing" + newline)
    end
    for k = 1:inc:numel(inp)
        if ~isvarname(char(inp{k}))
            error("'" + char(inp{k}) + "' is not a valid variable name")
        end
        if ~isfield(gset, char(inp{k})) || ~isequal(change, 0)
            if isequal(change, -1)
                if ~isfield(gset, char(inp{k}))
                    fprintf("you are attempting to remove global variable '" + char(inp{k}) + "' but it does not exist" + newline)
                else
                    gset = rmfield(gset, char(inp{k}));
                    fprintf("removing global variable '" + char(inp{k}) +  "'" + newline)
                end
            else
                if ~ischar(inp{k+1}) && ~isscalar(inp{k+1})
                    if iscell(inp{k+1})
                        tmpcl = inp{k+1};
                        strtmp = sprintf( '%s, ', tmpcl{:} );
                        strtmp = strtmp(1:end-2);
                    else
                        if ndims(inp{k+1})>2 || numel(inp{k+1})>30
                            strtmp = 'an array that is too long to be printed here';
                        else
                            strtmp = mat2str(inp{k+1});
                        end
                    end
                else
                    strtmp = inp{k+1};
                end
                if isequal(change, 0)
                    msgstart = 'setting';
                elseif isequal(change, 1)
                    msgstart = 'changing';
                end
                if isequal(char(inp{k}), 'all')
                    error("you are attempting to set a global variable named 'all' but you cannot use this name because it is reserved for retrieving all global variables" + newline)
                end
                if ischar(strtmp) && ~isstring(inp{k+1})
                    fprintf(msgstart + " global variable '" + char(inp{k}) + "' to '" + strtmp + "'" + newline)
                elseif isstruct(strtmp)
                    fprintf(msgstart + " global variable '" + char(inp{k}) + "' to the following struct: " + newline)
                    printstruct(strtmp, 'structname', char(inp{k}))
                else
                    fprintf(msgstart + " global variable '" + char(inp{k}) + "' to " + strtmp + newline)
                end
                gset.(char(inp{k})) = inp{k+1};
            end
        else
            error(sprintf("you are trying to set global variable '" + char(inp{k}) + "' after it's already been set; \nmake first argument 1 to update global variable(s)" + newline + "or clear glb to clear all global variables before attempting to set" + newline + "or clear global variable '" + char(inp{k}) + "' with first argument -1"))
        end
    end
    outp = gset;
elseif ischar(inp) %getting globals
    if isequal(inp,'all')
        if isempty(gset)
            fprintf("there are no global variables to retrieve" + newline)
        else
            outp = gset;
        end
    elseif ~isfield(gset,inp)
        fprintf("you are attempting to retrieve global variable '" + inp + "' but it has not yet been set" + newline)
        outp = [];
    else
        outp = gset.(inp);
        % fprintf("getting global variable '" + inp + "'" + newline)
    end
else
    fprintf("your input to 'glb' does nothing" + newline)
end

