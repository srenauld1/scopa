function s = structrenm(s, renm, opt)

%{

rename struct fields at top level of struct (does not recurse yet, in case nested)
s is input (and output) struct to have fields renamed
input argument renm is renaming pattern
    must be string array or cell array (or character vector if only one field is being renamed); 
    format of each element of renm is "newname = oldnames", where newname is one fieldname, oldnames is comma separated list of fieldnames; 
    for each element, oldnames are all possible fieldnames to be renamed with newname; 
    for each element, if any of the oldnames exist, oldname gets name newname, and oldname is removed from struct; 
    for each element, if none of the oldnames exist, and forcenew=0, the newname is not included in output struct; 
    for each element, if none of the oldnames exist, and forcenew=1, s.(newname)=[]; 
    for each element, if you omit equals sign, or omit everything to right of equal sign (ie oldnames), or make newname same as oldname, fieldname matching newname will be unchanged; 
    names cannot appear multiple times in renm (will error if they do), with one exception: for a each element of renm, newname can be included in oldnames, in case field already has desired newname
name-value argument 'onlynew'
    0 to keep in output struct any fields unlisted in renm
    1 to remove from output struct any fields unlisted in renm
    2 to error if there are any fields unlisted in renm

TODO: allow regexp in renm
TODO: allow nested structs

%}

arguments
    s % struct to have fields renamed
    renm % renaming pattern; see docs above for details
    opt.onlynew = 0 % 1 to remove from output struct s any fields unlisted in renm, 2 to error if there are any unlisted fields, 0 to keep any unlisted fields
    opt.forcenew = 0 % 1 to include all newnames in output struct even if no corresponding oldnames are found in input struct s (in which case, s.newname=[])
    opt.delim_newold = '=' % delimiter separating newname from oldnames
    opt.delim_oldnames = ',' % delimiter separating oldnames from each other
end
onlynew = opt.onlynew;
forcenew = opt.forcenew;
delim_newold = opt.delim_newold;
delim_oldnames = opt.delim_oldnames;

if ~isstring(renm) && ~iscellstr(renm)
    if ischar(renm)
        numnewnames = numel(strfind(renm, '='));
        if numnewnames>1
            error("renm is a charcter vector (not in a cell), but has multiple renaming expressions (multiple newnames, equals signs")
        else
            renm = {renm};
        end
    else
        error("renm must be string array or cell array of character vectors, or character vector with a single renaming expression (one newname)")
    end
end
if isstring(renm)
    renm = convertStringsToChars(renm);
end


%%%% CHECK NAME FORMATTING IN renm AND ORGANIZE %%%%

nmold = cell(1, numel(renm));
nmnew = cell(1, numel(renm));
for k = 1:numel(renm)
    renmtmp = strsplit(renm{k}, delim_newold);
    if numel(renmtmp)>2
        error("each element of renm cannot have more than one equals sign")
    end
    nmnew{k} = strsplit(renmtmp{1}, ','); %make sure no commas in newname
    if ~isscalar(nmnew{k})
        error("nmnew must not have commas")
    end
    nmnew{k} = strtrim(nmnew{k});
    nmnew{k} = nmnew{k}{1};
    if isscalar(renmtmp) || isempty(renmtmp{2})
        nmold{k} = nmnew{k}; %include the newname in oldnames
    else
        nmold{k} = strsplit(renmtmp{2}, delim_oldnames);
        nmold{k} = strtrim(nmold{k});
        if ~ismember(nmnew{k}, nmold{k})
            nmold{k}{end+1} = nmnew{k}; %include the newname with oldnames if it's not already listed among the oldnames, in case field already has desired name 
        end
    end
end
if numel(unique(cellflat(nmold)))~=numel(cellflat(nmold))
    error("there are duplicate names in the union of renm oldnames and renm newnames")
end
if numel(unique(cellflat(nmnew)))~=numel(cellflat(nmnew))
    error("there are duplicate names in renm newnames")
end

fnold = fieldnames(s);

unlisted_fields = fnold(~ismember(fnold, cellflat(nmold)));

if onlynew && ~isempty(unlisted_fields)
    if isequal(onlynew,1)
        s = rmfield(s, unlisted_fields);
        fnold = fieldnames(s); %recompute in case some were removed
    elseif isequal(onlynew,2)
        error("name-value argument 'onlynew' equals 2, but not all fields of input s appear in renm oldnames")
    end
end


%%%% NOW RENAME %%%%

for k = 1:numel(nmnew)
    fnoldtmp = fnold(ismember(fnold, nmold{k}));
    if isempty(fnoldtmp)
        if forcenew
            for m = 1:numel(s)
                s(m).(nmnew{k}) = [];
            end
        end
    else
        if isscalar(fnoldtmp)
            fnoldtmp = fnoldtmp{1};
        else
            error("there are multiple oldname matches in struct s corresponding to newname " + nmnew{k})
        end
        if ~isequal(fnoldtmp, nmnew{k})
            for m = 1:numel(s)
                s(m).(nmnew{k}) = s(m).(fnoldtmp);
            end
            s = rmfield(s, fnoldtmp);
        end
    end
end


end

