function o = opt2id(o, vbin)

% python optex.py does this: user's set, load df, overwrite df, distribute, reduce, sort, unique, ID, derive, check
% this function starts at distribute, and derive and check require data, so only happen in python, not here 
% (so here we just do distribute, reduce, sort, unique, ID) 

arguments
    o %options struct 
    vbin %vbin to recover id (and expand)
end

if ~iscell(vbin)
    vbin = {vbin};
end

id_capable_vbin = {'roi', 'mfit', 'feat'}; %only these vbin can be expanded and mapped to id (since they are the most option-dependent, user-may want to explore options easily, and also their options can be set simply without requiring complex encoding/decoding between matlab/python, or into and out of txt file; vbin 'daq', for example, requires options that are arrays of strings, which would require some ugly ad hoc solution to maintain consistency across all vbin if it were included here)

for k = 1:numel(vbin)

    vbintmp = vbin{k};

    if ~any(strcmp(vbintmp, id_capable_vbin))
        error(sprintf("option module (vbin) " + vbintmp + " does not support mapping between options sets and option ids (opt2id)"))
    end

    pthopt = [glb('pthparent') 'opt' vbintmp '.txt'];
    if isfile(pthopt)
        optfile = structtxtld(pthopt, nocells=1);
    else
        optfile = struct;
    end

    %%%%%%%% EXPAND OPTIONS %%%%%%%%

    for j = 1:numel(o)
        vbinstruct = o(j).(vbintmp);
        fn = fieldnames(vbinstruct);
        optexpall = struct;
        for m = 1:numel(fn)
            copybintmp = fn{m};
            copybinstruct = vbinstruct.(copybintmp);
            optflat = structflat(copybinstruct); % prefix=copybintmp);
            fnflat = fieldnames(optflat);

            % if any(~cellfun(@isempty, regexp(fnflat,[delim '(\d+)' delim])))
            %     error("cannot use nonscalar structs in o")
            % end

            fnnew = [copybintmp '_' num2str(1)];
            tmp = [];
            tmp.(fnnew) = struct;
            expandinds = zeros(numel(fnflat), 1, 'logical');
            for p = 1:numel(fnflat)
                tmpset = fieldnames(tmp);
                optidnums = numel(tmpset);
                tmpval = optflat.(fnflat{p});
                if isstring(tmpval) && numel(tmpval)>1
                    error("string arrays are not allowed in vbin that can undergo expansion / optid mapping; strings must be scalar, or in cell arrays (to be expanded)")
                elseif iscell(tmpval) && numel(tmpval)>1
                    expandinds(p) = 1;
                    for w = 1:numel(tmpval)
                        for ww = 1:optidnums
                            newind = ww+numel(optidnums)*(w-1);
                            fnnew = [copybintmp '_' num2str(newind)];
                            tmp.(fnnew).(fnflat{p}) = tmpval{w};
                        end
                    end
                end
            end
            tmpset = fieldnames(tmp);
            optidnums = numel(tmpset);
            for p = 1:numel(fnflat)
                if ~expandinds(p)
                    for ww = 1:optidnums
                        fnnew = [copybintmp '_' num2str(ww)];
                        if iscell(optflat.(fnflat{p}))
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p}){1}; %since singleton, take it out of cell
                        else
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p});
                        end
                    end
                end
            end

            optexpall = cell2struct([struct2cell(optexpall); struct2cell(tmp)], [fieldnames(optexpall); fieldnames(tmp)]); %combine
            optexpall = structsort(optexpall, vectype='row');

        end

        %%%%%%%% MATCH OR DERIVE OPTID FOR REDUCED OPTIONS %%%%%%%%

        optout = [];
        fntmp = fieldnames(optexpall);
        for p = 1:numel(fntmp)
            
            oone = optexpall.(fntmp{p}); %single options set after expansion of cell arrays
            oone = structunflat(oone);
            optred = optreduce(oone, vbintmp); %options set without any redundancy (this goes to file)
            
            optid = fieldnames(optfile);
            optidnums = cellfun(@str2double, cellflat(regexp(optid,'\d+','match')));
            if ~isempty(optidnums) && ( numel(optidnums)~=numel(optid) || ~isequal(optidnums, 1:numel(optidnums)) )
                error("there should be one integer per optind, sequentially from 1 to max, you may have an optind with an invalid name; name should be i followed by an integer")
            end
            if isempty(optidnums)
                optidnew = 'i1';
                optfile.(optidnew) = optred;
                optout.(optidnew) = optred;
            else
                maxoptind = max(optidnums);
                foundequal = 0;
                numoptid = numel(optid);
                for w = 1:numoptid
                    if isequal(optred, optfile.(optid{w}))
                        if foundequal
                            error("found multiple matches in opt file")
                        else
                            foundequal = 1;
                            optout.(optid{w}) = optfile.(optid{w}); %if options match existing set in file, name struct the option index from file
                        end
                    end
                    if w==numoptid && foundequal==0 %if current options don't match any in the roiopt file, append them to end as new option set
                        optidnew = ['i' num2str(maxoptind+1)];
                        optfile.(optidnew) = optred;
                        optout.(optidnew) = optred;
                        optid = [optid; optidnew];
                    end
                end
            end
        end

        o(j).(vbintmp) = optout;
    
    end

    structtxtsv(optfile, pthopt); %write optout (the corrected vbin from o) to opt file (do not not the whole opt struct o)

end

o = structsort(o, vectype='row');








