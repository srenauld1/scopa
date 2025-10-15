function o = oid(o, opt)

% python oex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here
% so here we just do distribute, reduce, sort, unique, ID

arguments
    o %options struct
    opt.getonly = 0 %get ids only (cannot write to file or create new id)
    opt.scopausername = []
    opt.usegit = []
end

try

    opt = glboropt(opt); %get some arguments from glb or name-value
    getonly = opt.getonly;
    scopausername = opt.scopausername;
    usegit = opt.usegit;

    callstack = dbstack();
    tsgetcall = 0;
    if ismember('tsget', {callstack.name})
        tsgetcall = 1;
    end
    if tsgetcall && ~getonly
        error("tsget should call oid with getonly=1")
    end
    if ~tsgetcall && ( ~isfield(o, 'finished') || ~isequal(o.finished, 1) ) %input struct does not require true 'finished' field if oid is called from tsget
        error("options struct must be 'finished'; you may have removed final call to ofill in an oset_* file with nonempty mosfinal name-value argument")
    end
    if ~isscalar(o) || ~isstruct(o)
        error("o must be scalar struct")
    end
    if isempty(usegit)
        error("must set name-value argument usegit or glb('usegit')")
    end
    if getonly
        fprintf("NOTE: setting usegit to false because s is empty or getonly is true (meaning nothing will be written to file), so syncing filesystems with git is not necessary" + newline)
    end
    

    mos = fieldnames(o);
    mos = mos(~strcmp(mos, 'finished'));

    for k = 1:numel(mos)

        if ~isempty(o.(mos{k}))

            %%%%%%%% PLACE OPTIONS IN TEMPORARY mosc (IF NOT ALREADY PLACED IN ONE BY USER) %%%%%%%%

            opttmp2 = moscset(o, mos{k});


            %%%%%%%% DISTRIBUTE OPTIONS %%%%%%%%

            optdist = odist(opttmp2, mos{k}); %optdist substructs (fields) are temporary names assigned during distribution

            optout = [];
            fntmp = fieldnames(optdist);
            for q = 1:numel(fntmp)


                %%%%%%%% CHECK OPTIONS FOR PROBLEMS %%%%%%%%

                optdist.(fntmp{q}) = ochk(optdist.(fntmp{q}), mos{k});


                %%%%%%%% REDUCE OPTIONS %%%%%%%%

                optred = ored(optdist.(fntmp{q}), mos{k}); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, ored is written to file (if it wasn't already)


                %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) AND WRITE TO FILE REDUCED OPTIONS AND THEIR OPTIDS %%%%%%%%

                pthoptmos = [pthscopaget() 'opt_' mos{k} '_' scopausername '_.txt'];
                [opttmp, optid, ~] = structfile(pthoptmos, s=optred, usegit=usegit, getonly=getonly, dupe=0, dosort=1); %don't usegit in strucfile because you use it outside its enclosing loop (more efficient)


                %%%%%%%% ACCUMULATE  %%%%%%%%

                if tsgetcall && ~iscell(opttmp)
                    opttmp = {opttmp};
                    optid = {optid};
                end

                if iscell(opttmp)
                    if ~tsgetcall
                        error("opttmp cannot be cell if tsgetcall")
                    end
                    for m = 1:numel(opttmp)
                        if ~isempty(opttmp{m})
                            opttmp{m}.optid = optid;
                            optout.(optid{m}) = opttmp{m};
                        end
                    end
                else
                    opttmp.optid = optid;
                    optout.(optid) = opttmp;
                end

            end

            o.(mos{k}) = optout;

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










