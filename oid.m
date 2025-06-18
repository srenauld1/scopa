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

delim = '__';

user = glb('user');
if isempty(user)
    error("you have not set glb('user')")
end

ided_vbin = glb('ided_vbin');
if isempty(ided_vbin)
    error("ided_vbin must be defined in glb")
end
if isstring(ided_vbin)
    ided_vbin = convertStringsToChars(ided_vbin);
end

if isempty(vbin)
    vbin = ided_vbin;
end
if ~iscell(vbin)
    vbin = {vbin};
end

pthscopa = getpathscopa();

callstack = dbstack();

tsgetcall = 0;
if strcmp(callstack(2).name, 'tsget3')
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

    if ~any(strcmp(vbintmp, ided_vbin))
        error(sprintf("option module (vbin) " + vbintmp + " does not support mapping between options sets and option ids (oid)"))
    end

    %%%%%%%% FIND OPTIONS FILE (FOR THIS FILESYSTEM) FOR A SINGLE vbin %%%%%%%%

    pthoptpat = [pthscopa 'opt_' vbintmp '_' user '_*_.txt'];

    for m = 1:numel(o)

        if isfield(o(m), vbintmp)
            
            %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

            optdist = odist(o(m), vbintmp); %optdist substructs (fields) are temporary names assigned during distribution

            optout = [];
            fntmp = fieldnames(optdist);
            for p = 1:numel(fntmp)

                %%%%%%%% REDUCE OPTIONS %%%%%%%%

                [optred, optinert] = ored(optdist.(fntmp{p}), vbintmp, delim); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, and without non-functional vbin (plotting vbin, temporarily held in optinert); ored is written to file (if it wasn't already)


                %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) OPTID FOR REDUCED OPTIONS %%%%%%%%

                [opttmp, optid] = structfile(pthoptpat, s=optred, useprefix=1, getonly=getonly);


                %%%%%%%% PUT NON FUNCTIONAL VBIN BACK INTO OPTIONS STRUCT (after retrieving optid and possbily writing to file, return substructs (vbin) that have no functional effect (just for plotting); must be returned to struct because struct ciouod have changed withi ored; ); INDIVIDUAL sub FIELDS THAT HAVE NO FUNCTIONAL EFFECT ARE REMOVED IN ored??  %%%%%%%%

                
                if tsgetcall && ~iscell(opttmp)
                    opttmp = {opttmp};
                    optid = {optid};
                end

                fnr = fieldnames(optinert);
                if iscell(opttmp)
                    if ~tsgetcall
                        error("opttmp cannot be cell if tsgetcall")
                    end
                    for k2 = 1:numel(opttmp)
                        if ~isempty(opttmp{k2})
                            opttmp{k2} = structflat(opttmp{k2}, delim=delim);
                            fnor = fieldnames(opttmp{k2});
                            tghold = fnor(endsWith(fnor, ['tg' delim 'tg']));
                            opttmp{k2} = rmfield(opttmp{k2}, tghold);
                            for q = 1:numel(fnr)
                                opttmp{k2}.(fnr{q}) = optinert.(fnr{q});
                            end
                            opttmp{k2} = structunflat(opttmp{k2}, delim=delim);
                            optout.(optid{k2}) = opttmp{k2};
                        end
                    end
                else
                    opttmp = structflat(opttmp, delim=delim);
                    fnor = fieldnames(opttmp);
                    tghold = fnor(endsWith(fnor, ['tg' delim 'tg']));
                    opttmp = rmfield(opttmp, tghold); %remove the empty tg field you had to insert for json to write empty tg properly (hack needs top be fixed)
                    for q = 1:numel(fnr)
                        opttmp.(fnr{q}) = optinert.(fnr{q});
                    end
                    opttmp = structunflat(opttmp, delim=delim);
                    if ~isfield(opttmp, 'optid') %if optid itself is not field (shouldn't ever be right?) add it here 
                        opttmp.optid = optid;
                    end
                    optout.(optid) = opttmp;
                end

            end

            o(m).(vbintmp) = optout;

        end
    end

end

o = structsort(o, vectype='row');








