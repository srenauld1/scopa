function o = oid(o, opt)

% python oex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% so here we just do distribute, reduce, sort, unique, ID

arguments
    o %options struct
    opt.getonly = 0 %get ids only (cannot write to file or create new id)
    opt.scopausername = []
    opt.usegit = []
    opt.delimflat = []
end

try

    opt = glboropt(opt); %get some arguments from glb or name-value
    getonly = opt.getonly;
    scopausername = opt.scopausername;
    usegit = opt.usegit;
    delimflat = opt.delimflat;

    pthopt = [pthscopaget() 'optdf.txt'];
    dall = structld(pthopt, nocells=1, dosort=0);
    mostree = dall.mostree;

    if isempty(usegit)
        error("must set name-value argument usegit or glb('usegit')")
    end
    mos = fieldnames(o);
    mos = mos(~strcmp(mos, 'finished'));

    if getonly
        fprintf("NOTE: setting usegit to false because s is empty or getonly is true (meaning nothing will be written to file), so syncing filesystems with git is not necessary" + newline)
    end

    callstack = dbstack();
    tsgetcall = 0;
    if ismember('tsget', {callstack.name})
        tsgetcall = 1;
    end

    if tsgetcall && ~getonly
        error("tsget should call oid with getonly=1")
    end

    if ~tsgetcall && ( isempty(getfieldns(o, 'finished')) || any(cellfun(@isempty, getfieldns(o, 'finished'))) || any(~isequal(cell2mat(getfieldns(o, 'finished')),1)) ) %input struct does not require true 'finished' field if oid is called from tsget
        error("options struct must be 'finished'; you may have removed final call to ofill in an oset_* file with nonempty mosfinal name-value argument")
    end

    for k = 1:numel(mos)

        for q = 1:numel(o) %in case nonscalar

            if ~isempty(o(q).(mos{k}))

                %%%%%%%% PLACE OPTIONS IN TEMPORARY mosc (IF NOT ALREADY PLACED IN ONE BY USER) %%%%%%%%

                opttmp2 = moscset(o(q), mos{k}, mostree, tsgetcall=tsgetcall);

                %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

                optdist = odist(opttmp2, mos{k}, delimflat=delimflat); %optdist substructs (fields) are temporary names assigned during distribution

                optout = [];
                fntmp = fieldnames(optdist);
                for m = 1:numel(fntmp)


                    %%%%%%%% CHECK OPTIONS FOR PROBLEMS %%%%%%%%

                    optdist.(fntmp{m}) = ochk(optdist.(fntmp{m}), mos{k});


                    %%%%%%%% REDUCE OPTIONS %%%%%%%%

                    optred = ored(optdist.(fntmp{m}), mos{k}); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, ored is written to file (if it wasn't already)


                    %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) AND WRITE TO FILE REDUCED OPTIONS AND THEIR OPTIDS %%%%%%%%

                    pthoptpat = [pthscopaget() 'opt_' mos{k} '_' scopausername '_.txt'];

                    [opttmp, optid, ~] = structfile(pthoptpat, s=optred, usegit=usegit, getonly=getonly, dupe=0, dosort=1); %don't usegit in strucfile because you use it outside its enclosing loop (more efficient)


                    %%%%%%%% ACCUMULATE  %%%%%%%%


                    if tsgetcall && ~iscell(opttmp)
                        opttmp = {opttmp};
                        optid = {optid};
                    end

                    if iscell(opttmp)
                        if ~tsgetcall
                            error("opttmp cannot be cell if tsgetcall")
                        end
                        for p = 1:numel(opttmp)
                            if ~isempty(opttmp{p})
                                optout.(optid{p}) = opttmp{p};
                            end
                        end
                    else
                        optout.(optid) = opttmp;
                    end

                end

                o(q).(mos{k}) = optout;

            end
        end

    end

    o = structsort(o, vectype='row');

catch ME

    if usegit
        scopagit('discard', files={'^opt_.*_.txt$'})
    end
    error("oid failed with the following error: " + ME.message)

end

end










