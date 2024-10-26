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


update = 0;
if numel(inp)==1
    inp = inp{1};
elseif numel(inp)==2
    if isstruct(inp{2})
        update = inp{1};
        inp = inp{2};
    end
elseif mod(numel(inp), 2)==1
    update = inp{1};
    inp = inp(2:end);
end

if isstruct(inp)
    fn = fieldnames(inp);
    inptmp = struct2cell(inp);
    inp = cell(numel(inptmp)*2, 1);
    for k = 1:numel(inptmp)
        inp{k*2-1} = fn{k};
        inp{k*2} = inptmp{k};
    end
end


if iscell(inp) %setting globals
    if isempty(gset)
        gset = struct;
    end
    for k = 1:2:numel(inp)
        if ~isfield(gset, char(inp{k})) || update
            gset.(char(inp{k})) = inp{k+1};
        else
            error(sprintf("you are trying to set global variable '" + char(inp{k}) + "' after it's already been set; \nmake first argument 1 to update global variable(s), \nor clear glb to clear all global variables before attempting to set"))
        end
    end
elseif ischar(inp) %retrieving globals
    if isequal(inp,'all')
        outp = gset;
    elseif ~isfield(gset,inp)
        fprintf("parameter " + inp + " has not yet been set as a global variable" + newline)
        outp = [];
    else
        outp = gset.(inp);
    end
end

