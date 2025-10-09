function opt = oid(opt, obin, opt2)

% python oex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% so here we just do distribute, reduce, sort, unique, ID

arguments
    opt %options struct
    obin = [] %obin to recover id (and expand)
    opt2.getonly = 0 %get ids only (cannot write to file or create new id)
    opt2.scopausername = []
    opt2.usegit = []
    opt2.obin_ided = []
    opt2.delimflat = []
end

try

    opt2 = glboropt(opt2); %get some arguments from glb or name-value
    getonly = opt2.getonly;
    scopausername = opt2.scopausername;
    usegit = opt2.usegit;
    obin_ided = opt2.obin_ided;
    delimflat = opt2.delimflat;

    pthscopa = pthscopaget();
    pthopt = [pthscopa 'optdf.txt'];

    if isfile(pthopt)
        dall = structld(pthopt, nocells=1, dosort=0);
        otree = dall.otree;
    else
        error("cannot find default options file: " + pthopt + newline + "run 'odf()' to create it")
    end

    if isempty(obin_ided)
        % obin_ided = glb('otree');
        obin_ided = [ "sld", "daq", "roi", "bmp", "mdl", "fmf"];
    end

    if isstring(obin_ided)
        obin_ided = convertStringsToChars(obin_ided);
    end
    if isempty(usegit)
        error("must set name-value argument usegit or glb('usegit')")
    end
    if isempty(obin)
        obin = obin_ided;
    end
    if ~iscell(obin)
        obin = {obin};
    end
    if getonly
        warning("NOTE: setting usegit to false because s is empty or getonly is true (meaning nothing will be written to file), so syncing filesystems with git is not necessary")
    end

    callstack = dbstack();
    tsgetcall = 0;
    if ismember('tsget', {callstack.name})
        tsgetcall = 1;
    end

    if tsgetcall && ~getonly
        error("tsget should call oid with getonly=1")
    end

    if isempty(getfieldns(opt, 'finished')) || any(cellfun(@isempty, getfieldns(opt, 'finished'))) || any(~isequal(cell2mat(getfieldns(opt, 'finished')),1))
        if ~tsgetcall %input struct does not require true 'finished' field if oid is called from tsget
            error("options struct must be 'finished'; you may have removed final call to ofill in an oset_* file with nonempty mosfinal name-value argument")
        end
    end

    for k = 1:numel(obin)

        obintmp = obin{k};

        if ~any(strcmp(obintmp, obin_ided))
            error("option module (obin) " + obintmp + " does not support mapping between options sets and option ids (oid)")
        end

        %%%%%%%% FIND OPTIONS FILE (FOR THIS FILESYSTEM) FOR A SINGLE obin %%%%%%%%

        pthoptpat = [pthscopa 'opt_' obintmp '_' scopausername '_.txt'];

        for m = 1:numel(opt)

            if isfield(opt(m), obintmp)

                %%%%%%%% PLACE OPTIONS IN TEMPORARY COPYBIN (IF NOT ALREADY) %%%%%%%%

                opttmp2 = ocopybinset(opt(m), obintmp, tsgetcall=tsgetcall);

                %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

                optdist = odist(opttmp2, obintmp, delimflat=delimflat); %optdist substructs (fields) are temporary names assigned during distribution

                optout = [];
                fntmp = fieldnames(optdist);
                for p = 1:numel(fntmp)


                    %%%%%%%% CHECK OPTIONS FOR PROBLEMS %%%%%%%%

                    optdist.(fntmp{p}) = ochk(optdist.(fntmp{p}), obintmp);


                    %%%%%%%% REDUCE OPTIONS %%%%%%%%

                    [optred, tmpinert] = ored(optdist.(fntmp{p}), obintmp, delimflat=delimflat); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, and without non-functional obin (plotting obin, temporarily held in tmpinert); ored is written to file (if it wasn't already)


                    %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) AND WRITE TO FILE REDUCED OPTIONS AND THEIR OPTIDS %%%%%%%%

                    [opttmp, optid] = structfile(pthoptpat, s=optred, usegit=usegit, getonly=getonly, dupe=0, dosort=1); %don't usegit in strucfile because you use it outside its enclosing loop (more efficient)


                    %%%%%%%% PUT NON FUNCTIONAL OBIN BACK INTO OPTIONS STRUCT (after retrieving optid and possbily writing to file, return substructs (obin) that have no functional effect (just for plotting); must be returned to struct because struct ciouod have changed withi ored; ); INDIVIDUAL sub FIELDS THAT HAVE NO FUNCTIONAL EFFECT ARE REMOVED IN ored??  %%%%%%%%


                    if tsgetcall && ~iscell(opttmp)
                        opttmp = {opttmp};
                        optid = {optid};
                    end

                    fnr = fieldnames(tmpinert);
                    if iscell(opttmp)
                        if ~tsgetcall
                            error("opttmp cannot be cell if tsgetcall")
                        end
                        for k2 = 1:numel(opttmp)
                            if ~isempty(opttmp{k2})
                                opttmp{k2} = structflat(opttmp{k2}, delim=delimflat);
                                fnor = fieldnames(opttmp{k2});
                                tghold = fnor(endsWith(fnor, ['tg' delimflat 'tg']));
                                opttmp{k2} = rmfield(opttmp{k2}, tghold);
                                for q = 1:numel(fnr)
                                    opttmp{k2}.(fnr{q}) = tmpinert.(fnr{q});
                                end
                                opttmp{k2} = structunflat(opttmp{k2}, delim=delimflat);
                                optout.(optid{k2}) = opttmp{k2};
                            end
                        end
                    else
                        opttmp = structflat(opttmp, delim=delimflat);
                        fnor = fieldnames(opttmp);
                        tghold = fnor(endsWith(fnor, ['tg' delimflat 'tg']));
                        opttmp = rmfield(opttmp, tghold); %remove the empty tg field you had to insert for json to write empty tg properly (hack needs to be fixed)
                        for q = 1:numel(fnr)
                            opttmp.(fnr{q}) = tmpinert.(fnr{q});
                        end
                        opttmp = structunflat(opttmp, delim=delimflat);
                        if ~isfield(opttmp, 'optid') %if optid itself is not field (shouldn't ever be, right?) add it here
                            opttmp.optid = optid;
                        end
                        optout.(optid) = opttmp;
                    end

                end

                opt(m).(obintmp) = optout;

            end
        end

    end

    opt = structsort(opt, vectype='row');

catch ME

    if usegit
        scopagit('discard', files={'^opt_.*_.txt$'})
    end
    error("oid failed with the following error: " + ME.message)

end

end










