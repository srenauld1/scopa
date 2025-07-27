function o = oid(o, vbin, opt)

% python oex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% (so here we just do distribute, reduce, sort, unique, ID)

arguments
    o %options struct
    vbin = [] %vbin to recover id (and expand)
    opt.getonly = 0 %get ids only (cannot write to file or create new id)
    opt.scopausername = []
    opt.usegit = []
    opt.ided_vbin = []
end
opt = glboropt(opt); %get some arguments from glb or name-value
getonly = opt.getonly;
scopausername = opt.scopausername;
usegit = opt.usegit;
ided_vbin = opt.ided_vbin;

delim = '__';

if isstring(ided_vbin)
    ided_vbin = convertStringsToChars(ided_vbin);
end
if isempty(usegit)
    error("must set name-value argument usegit or glb('usegit')")
end
if isempty(vbin)
    vbin = ided_vbin;
end
if ~iscell(vbin)
    vbin = {vbin};
end
if getonly
    warning("NOTE: setting usegit to false because s is empty or getonly is true (meaning nothing will be written to file), so syncing filesystems with git is not necessary")
end

pthscopa = pathscopafind();

callstack = dbstack();

tsgetcall = 0;
if strcmp(callstack(2).name, 'tsget3')
    tsgetcall = 1;
end

if tsgetcall && ~getonly
    error("tsget should call oid with getonly=1")
end

if isempty(structfield(o, 'filled')) || any(cellfun(@isempty, structfield(o, 'filled'))) || any(cell2mat(structfield(o, 'filled'))~=1)
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

    pthoptpat = [pthscopa 'opt_' vbintmp '_' scopausername '_.txt'];

    for m = 1:numel(o)

        if isfield(o(m), vbintmp)
            
            %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

            optdist = odist(o(m), vbintmp); %optdist substructs (fields) are temporary names assigned during distribution

            optout = [];
            fntmp = fieldnames(optdist);
            for p = 1:numel(fntmp)

                %%%%%%%% REDUCE OPTIONS %%%%%%%%

                [optred, optinert] = ored(optdist.(fntmp{p}), vbintmp, delim); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, and without non-functional vbin (plotting vbin, temporarily held in optinert); ored is written to file (if it wasn't already)


                %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) AND WRITE TO FILE REDUCED OPTIONS AND THEIR OPTIDS %%%%%%%%

                [opttmp, optid] = structfile(pthoptpat, s=optred, usegit=usegit, getonly=getonly, dupe=0, dosort=1); %don't usegit in strucfile because you use it outside its enclosing loop (more efficient)


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










