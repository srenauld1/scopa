function o = opt2id(o, vbin)

% python optex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% (so here we just do distribute, reduce, sort, unique, ID)

arguments
    o %options struct
    vbin = [] %vbin to recover id (and expand)
end

user = glb('user');
if isempty(user)
    error("you have not set glb('user')")
end

% id_capable_vbin = {'roi', 'mf', 'bmp'}; %only these vbin can be distributed (optdist) and mapped to id (since they are the most option-dependent, user-may want to explore options easily, and also their options can be set simply without requiring complex encoding/decoding between matlab/python, or into and out of txt file; vbin 'daq', for example, requires options that are arrays of strings, which would require some ugly ad hoc solution to maintain consistency across all vbin if it were included here)
id_capable_vbin = {'roi'}; %only these vbin can be distributed (optdist) and mapped to id (since they are the most option-dependent, user-may want to explore options easily, and also their options can be set simply without requiring complex encoding/decoding between matlab/python, or into and out of txt file; vbin 'daq', for example, requires options that are arrays of strings, which would require some ugly ad hoc solution to maintain consistency across all vbin if it were included here)

if isempty(vbin)
    vbin = id_capable_vbin;
end

if ~iscell(vbin)
    vbin = {vbin};
end

pthscopa = getpathscopa();

if any(cellfun(@isempty, getfieldns(o, 'filled'))) || any(cell2mat(getfieldns(o, 'filled'))~=1)
    error("options struct must be 'filled'; you may have removed final call to odf in oset with argument fill=1")
end


for k = 1:numel(vbin)

    vbintmp = vbin{k};

    if ~any(strcmp(vbintmp, id_capable_vbin))
        error(sprintf("option module (vbin) " + vbintmp + " does not support mapping between options sets and option ids (opt2id)"))
    end

    %%%%%%%% FIND OPTIONS FILE (FOR THIS FILESYSTEM) FOR A SINGLE vbin %%%%%%%%

    pthoptpat = [pthscopa 'opt' vbintmp '_' user '_*_.txt'];

    for m = 1:numel(o)

        %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

        optexpall = optdist(o(m).(vbintmp)); %optexpall structs (fields) are temporary names assigned during distribution

        optout = [];
        fntmp = fieldnames(optexpall);
        for p = 1:numel(fntmp)

            oone = optexpall.(fntmp{p}); %single options set after distribution of cell arrays
            oone = structunflat(oone);


            %%%%%%%% REDUCE OPTIONS %%%%%%%%

            [optred, optreturn] = optreduce(oone, vbintmp); %options set without any redundancy, and without non-functional vbin (plotting vbin, temporarily held in optreturn); optred is written to file (if it wasn't already)

            
            %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) OPTID FOR REDUCED OPTIONS %%%%%%%%

            [opttmp, nmnew] = structfile(pthoptpat, s=optred, useprefix=1);
            

            %%%%%%%% RETURN NON FUNCTIONAL VBIN (after retrieving optid and possbily writing to file, return substructs (vbin) that have no functional effect (just for plotting) )  %%%%%%%%
            
            fnr = fieldnames(optreturn);
            for q = 1:numel(fnr)
                opttmp.(fnr{q}) = optreturn.(fnr{q}); 
            end
            optout.(nmnew) = opttmp;

        end

        o(m).(vbintmp) = optout;

    end

end

o = structsort(o, vectype='row');








