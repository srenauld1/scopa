function out = glb(inp)

%{

set/get/store global variables

SET GLOBALS 
    you can set globals in three ways
            1)   glb(a=2, b=3)
            2)   glb('a', 2, 'b', 3) (use this method to set field within struct directly in glb; for example, glb('v.k', 99), since glb(v.k=99) will error
            3)   s.a=2; s.b=3; glb(s)

GET GLOBALS
    glb('v') will outut global variable v, if it's been set
    in all 3 set cases above, glb('v') will return 2 and glb('w') will return 3
    you can only get one global at a time, unless you call glb without any input arguments (that is, glb or glb()), which will outut a struct of all globals

REMOVE GLOBALS 
    remove all globals by calling
        clear glb
    remove specific globals using -1 as first argument, followed by variables to remove, in two ways  
        1) glb(-1, 'v', 'w')
        2) glb(-1, {'v', 'w'})
    if global you try to remove does not exist, it is ignored (no error)

CHANGE GLOBALS 
    you cannot set a global variable after it's already been set, unless you pass in 1 as first argument (or remove that global variable)
        for example, glb(1, v=99) will set global variable v to 99 (any of the above 3 "set globals" syntaxes are valid for changing global)
    if global you try to change does not exist, it is ignored (no error)

STRUCTS
    you can directly set and get fields of a struct (scalar or nonscalar) with glb('name', value) syntax; struct indexing follows normal rules (just in quotes); for example
        glb('a(4).b(2).c(3)', 3) sets 3rd element of c to 3 within 2nd element of nonscalar struct b within 4th element of nonscalar struct a
        and to retrieve that value, call 
            glb('a(4).b(2).c(3)')

TIPS
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
            if ~isequal(idxstr, 1:numel(inp)) %if variables for removal were listed as separate positional string arguments, put them into one cell to make code cleaner below
                idxchar = find(cellfun(@ischar, inp));
                if ~isequal(idxchar, 1:numel(inp)) %if variables for removal were listed as separate positional char arguments, put them into one cell to make code cleaner below
                    error("if removing globals, all of them must be in one cell array with each element a char vector or string, or all must be passed in as positional char arguments, or string arguments (not a mixture of char and string)")
                end
            end
            inpnew = {};
            for k = 1:numel(inp)
                inpnew{1}{k} = char(inp{k});
            end
            inp = inpnew;
        end
    end
else
    change = 0;
end

if ~ismember(change, [-1, 0, 1])
    error("optional first argument 'change' can only be -1, 0, or 1")
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
        if ~all(ismember(1:inc:numel(inp), idxstr))
            idxchar = find(cellfun(@ischar, inp));
            if all(ismember(1:inc:numel(inp), idxchar))
                for k = 1:inc:numel(inp)
                    inp{k} = string(inp{k}); %just for clarity, if name value arguments were passed in as char, rather than string or with equals sign, convert char names to string names (do nothing to their values)
                end
            else
                error("all name value arguments must be in format name=value, or 'name', value', or ""name"",""value"", but these format cannot be mixed in a single call to glb")
            end
        end
    elseif mod(numel(inp), 2)==1
        error("all arguments must be name-value pairs, except optional numeric first argument, and option to pass in all arguments as a single struct")
    end
end



%%%%%% SET OR GET GLOBALS %%%%%%

if isempty(inp)
    fprintf("you did not pass in any input to glb, returning all variables in glb" + newline)
    out = gset;
else
    if iscell(inp) %setting globals
        if isempty(gset)
            gset = struct;
        end
        for k = 1:inc:numel(inp)
            if ~isvarname(char(inp{k}))
                % error("'" + char(inp{k}) + "' is not a valid variable name")
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
                    if ischar(strtmp) && ~isstring(inp{k+1})
                        fprintf(msgstart + " global variable '" + char(inp{k}) + "' to '" + strtmp + "'" + newline)
                    elseif isstruct(strtmp)
                        fprintf(msgstart + " global variable '" + char(inp{k}) + "' to the following struct: " + newline)
                        structprint(strtmp, 'structname', char(inp{k}))
                    else
                        fprintf(msgstart + " global variable '" + char(inp{k}) + "' to " + strtmp + newline)
                    end
                    sind = structind(inp{k});
                    if ~isempty(gset) && ~isscalar(gset) %make sure before you change gset
                        error("glb struct cannot be nonscalar right now")
                    end
                    if isempty(inp{k+1})
                        gset = setfield(gset, sind{:}, 1); %if setting to empty, must create field with nonempty dummy value first
                    end
                    gset = setfield(gset, sind{:}, inp{k+1});
                end
            else
                error("you are trying to set global variable '" + char(inp{k}) + "' after it's already been set" + newline + "make first argument 1 to update global variable(s)" + newline + "or clear global variable '" + char(inp{k}) + "' with first argument -1, like this: glb(-1, '" + char(inp{k}) + "')" + newline + "or 'clear glb' to clear all global variables before attempting to set" + newline)
            end
        end
        out = gset;
    elseif ischar(inp) %getting globals
        sind = structind(inp);
        if ~isempty(gset) && ~isscalar(gset) %make sure before you access gset
            error("glb struct cannot be nonscalar right now")
        end
        try
            out = getfield(gset, sind{:});
        catch ME
            % fprintf(string(ME.message) + newline + "will output empty array" + newline)
            out = [];
        end
    end
end

end

