function o = oid(o, vbin, opt)

% python oex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% (so here we just do distribute, reduce, sort, unique, ID)

arguments
    o %options struct
    vbin = [] %vbin to recover id (and expand)
    opt.getonly = 0 %get ids only (cannot write to file or create new id)
end
getonly = opt.getonly;

user = glb('user');
if isempty(user)
    error("you have not set glb('user')")
end

id_capable_vbin = {'roi', 'mdl', 'bmp'}; %only these vbin can be distributed (odist) and mapped to id (since they are the most option-dependent, user-may want to explore options easily, and also their options can be set simply without requiring complex encoding/decoding between matlab/python, or into and out of txt file; vbin 'daq', for example, requires options that are arrays of strings, which would require some ugly ad hoc solution to maintain consistency across all vbin if it were included here)

if isempty(vbin)
    vbin = id_capable_vbin;
end

if ~iscell(vbin)
    vbin = {vbin};
end

pthscopa = getpathscopa();

callstack = dbstack();

tsgetcall = 0;
if strcmp(callstack(2).name, 'tsget')
    tsgetcall = 1;
end

if tsgetcall && ~getonly
    error("tsget should call oid with getonly=1")
end

if isempty(getfieldns(o, 'filled')) || any(cellfun(@isempty, getfieldns(o, 'filled'))) || any(cell2mat(getfieldns(o, 'filled'))~=1)
    if ~tsgetcall %input struct does not require true 'filled' field if oid is called from tsget
        error("options struct must be 'filled'; you may have removed final call to odf in oset with argument fill=1")
    end
end


for k = 1:numel(vbin)

    vbintmp = vbin{k};

    if ~any(strcmp(vbintmp, id_capable_vbin))
        error(sprintf("option module (vbin) " + vbintmp + " does not support mapping between options sets and option ids (oid)"))
    end

    %%%%%%%% FIND OPTIONS FILE (FOR THIS FILESYSTEM) FOR A SINGLE vbin %%%%%%%%

    pthoptpat = [pthscopa 'opt_' vbintmp '_' user '_*_.txt'];

    for m = 1:numel(o)

        if isfield(o(m), vbintmp)
            
            %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

            optexpall = odist(o(m), vbintmp); %optexpall structs (fields) are temporary names assigned during distribution

            optout = [];
            fntmp = fieldnames(optexpall);
            for p = 1:numel(fntmp)

                %%%%%%%% REDUCE OPTIONS %%%%%%%%

                [optred, optreturn] = ored(optexpall.(fntmp{p}), vbintmp); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, and without non-functional vbin (plotting vbin, temporarily held in optreturn); ored is written to file (if it wasn't already)


                %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) OPTID FOR REDUCED OPTIONS %%%%%%%%

                [opttmp, nmnew] = structfile(pthoptpat, s=optred, useprefix=1, getonly=getonly);


                %%%%%%%% PUT NON FUNCTIONAL VBIN BACK INTO OPTIONS STRUCT (after retrieving optid and possbily writing to file, return substructs (vbin) that have no functional effect (just for plotting) ); INDIVIDUAL sub FIELDS THAT HAVE NO FUNCTIONAL EFFECT ARE REMOVED IN ored??  %%%%%%%%

                if tsgetcall && ~iscell(opttmp)
                    opttmp = {opttmp};
                    nmnew = {nmnew};
                end

                fnr = fieldnames(optreturn);
                if iscell(opttmp)
                    if ~tsgetcall
                        error("opttmp cannot be cell if tsgetcall")
                    end
                    for k2 = 1:numel(opttmp)
                        if ~isempty(opttmp{k2})
                            for q = 1:numel(fnr)
                                opttmp{k2}.(fnr{q}) = optreturn.(fnr{q});
                            end
                            optout.(nmnew{k2}) = opttmp{k2};
                        end
                    end
                else
                    for q = 1:numel(fnr)
                        opttmp.(fnr{q}) = optreturn.(fnr{q});
                    end
                    if ~isfield(opttmp, 'optid') %if optid itself is not field (shouldn't ever be right?) add it here 
                        opttmp.optid = nmnew;
                    end
                    optout.(nmnew) = opttmp;
                end

            end

            o(m).(vbintmp) = optout;

        end
    end

end

o = structsort(o, vectype='row');








