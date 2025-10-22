function o = oid(o, opt)

%{

oid is called from ofill when finalizing a2p options struct, or from vget when searching for variables; 
oid assigns id to unique options sets for each module, and writes them to txt file; also distributes each element of any cell-valued options into separate options sets; also checks for problems in options struct
oex.py does something similar; it does this: user's set, load defaults, overwrite defaults, distribute, reduce, sort, unique, ID, derive, check
this function starts at the "distribute" step; "derive" and "check" steps require data, so they happen in oex.py (since oex is called after data is loaded), but not here in oid.m (where data is not necessarily loaded, like when oid is called from oset>ofill 
so oid just has these steps: distribute, reduce, sort, unique, ID

%}

arguments
    o % options struct 
    opt.getonly = 0 % get ids only (cannot write to file or create new id)
end

try

    getonly = opt.getonly;

    usegit = glb('usegit', err=1);

    scopausername = userdatfile('scopausername');

    callstack = dbstack();
    vgetcall = 0;
    if ismember('vget', {callstack.name})
        vgetcall = 1;
    end
    if vgetcall && ~getonly
        error("vget should call oid with getonly=1")
    end
    if ~vgetcall && ( ~isfield(o, 'finished') || ~isequal(o.finished, 1) ) %input struct does not require true 'finished' field if oid is called from vget
        error("options struct must be 'finished'; you may have removed final call to ofill in an oset_* file with nonempty mosfinal name-value argument")
    end
    if ~isscalar(o) || ~isstruct(o)
        error("o must be scalar struct")
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

            optdist = odist(opttmp2); %optdist substructs (fields) are temporary names assigned during "distribution" of any cell-valued options
            
            cnt = 0;
            optout = [];
            mosctmp = fieldnames(optdist);
            for q = 1:numel(mosctmp)


                %%%%%%%% REDUCE OPTIONS %%%%%%%%

                optred = ored(optdist.(mosctmp{q}), mos{k}); %input is single options set after distribution of cell arrays in odist; output is that same options set but without any redundancy, ored is written to file below with structfile (if it wasn't already)


                %%%%%%%% MATCH (TO FILE) OR DERIVE (NOT IN FILE) AND WRITE TO FILE REDUCED OPTIONS AND THEIR OPTIDS %%%%%%%%

                pthoptmos = [pthscopaget() 'opt_' mos{k} '_' scopausername '_.txt'];
                [opttmp, optid, ~] = structfile(pthoptmos, s=optred, usegit=usegit, getonly=getonly, dupe=0, dosort=1, cellout=1); %don't usegit in strucfile because you use it outside its enclosing loop (more efficient)

                if ~vgetcall && ~isscalar(opttmp)
                    error("opttmp must be scalar, except when vgetcall=1 (ie when calling oid from vget, where wildcard can find multiple matching structs)")
                end

                
                %%%%%%%% ACCUMULATE NONSCALAR STRUCT WITH NEW OPTID FIELD  %%%%%%%%

                for m = 1:numel(opttmp)
                    if ~isempty(opttmp{m}) %why would this ever be empty??
                        cnt = cnt+1;
                        opttmp{m}.optid = optid{m};
                        if cnt==1
                            optout = opttmp{m};
                        else
                            optout(cnt) = opttmp{m};
                        end
                    end
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










