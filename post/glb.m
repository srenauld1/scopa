function outp = glb(inp)

%{

set globals in three ways
        1)   a=2; b=3; glb(v=a, w=b)
        2)   glb(v=2, w=3)
        3)   a.v=2; a.w=3; glb(a)

retrieve globals
    glb('v') will retrieve global variable v, if it's been set
    in all 3 set cases above, glb('v') will return 2 and glb('w') will return 3
    can only retrieve one global at a time
    unless you call glb('all'), which will return a struct of all globals

clear all globals by calling
    clear glb

you cannot set a global after it's already been set, unless you pass 1 for argument update, or clear glb first
    glb(1, v=99) will set global variable v to 99 (so will k.v=99; glb(1,k), for any struct k)
you can also use update argument to clear specific global variables
    glb(1, v=[]) will set global variable v to empty [] (not exactly the same as clearing it)

%}


arguments (Repeating)
    inp
end

persistent gset


change = 0;
if numel(inp)==1
    inp = inp{1};
elseif numel(inp)==2
    if isstruct(inp{2})
        change = inp{1};
        inp = inp{2};
    else
        if isequal(inp{1}, -1)
            change = inp{1};
            inp = inp{2};
        end
    end
elseif mod(numel(inp), 2)==1
    change = inp{1};
    inp = inp(2:end);
    if isequal(change, -1)
        error("you are attempting to remove global variable(s), but have passed them as name-value arguments; use a string, or a cell array of char to list globals for removal")
    end
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
                    strtmp = mat2str(inp{k+1});
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
                else
                    fprintf(msgstart + " global variable '" + char(inp{k}) + "' to " + strtmp + newline)
                end
                gset.(char(inp{k})) = inp{k+1};
            end
        else
            error(sprintf("you are trying to set global variable '" + char(inp{k}) + "' after it's already been set; \nmake first argument 1 to update global variable(s), \nor clear glb to clear all global variables before attempting to set"))
        end
    end
elseif ischar(inp) %retrieving globals
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
        fprintf("getting global variable '" + inp + "'" + newline)
    end
else
    fprintf("your input to 'glb' does nothing" + newline)
end

