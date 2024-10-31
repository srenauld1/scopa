function o = opt2id(o, vbin)

arguments
    o
    vbin
end

if ~iscell(vbin)
    vbin = {vbin};
end

for k = 1:numel(vbin)

    vbintmp = vbin{k};

    pthopt = [glb('pthparent') 'opt' vbintmp '.txt'];
    if isfile(pthopt)
        optfile = jsondecode(fileread(pthopt));
    else
        optfile = struct;
    end

    optfile = structord(optfile, vectype='row');

    for j = 1:numel(o)
        vbinstruct = o(j).(vbintmp);
        fn = fieldnames(vbinstruct);
        optexpall = struct;
        for m = 1:numel(fn)
            copybintmp = fn{m};
            copybinstruct = vbinstruct.(copybintmp);
            optflat = structflat(copybinstruct); % prefix=copybintmp);
            fnflat = fieldnames(optflat);
            % if any(~cellfun(@isempty, regexp(fnflat,'_[\d]*_')))
            %     error("cannot use nonscalar structs in o")
            % end

            fnnew = [copybintmp '_' num2str(1)];
            tmp = [];
            tmp.(fnnew) = struct;
            expandinds = zeros(numel(fnflat), 1, 'logical');
            for p = 1:numel(fnflat)
                tmpset = fieldnames(tmp);
                optidnums = numel(tmpset);
                if iscell(optflat.(fnflat{p})) && numel(optflat.(fnflat{p}))>1
                    expandinds(p) = 1;
                    for w = 1:numel(optflat.(fnflat{p}))
                        for ww = 1:optidnums
                            newind = ww+numel(optidnums)*(w-1);
                            fnnew = [copybintmp '_' num2str(newind)];
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p}){w};
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
            optexpall = structord(optexpall, vectype='row');

        end

        optout = [];
        fntmp = fieldnames(optexpall);
        for p = 1:numel(fntmp)
            oone = optexpall.(fntmp{p}); %single options set after expansion of cell arrays
            optred = optreduce(oone, vbintmp); %options set without any redundancy (this goes to file)
            optid = fieldnames(optfile);
            optidnums = cellfun(@str2double, cellflat(regexp(optid,'\d+','match')));
            if ~isempty(optidnums) && ( numel(optidnums)~=numel(optid) || ~isequal(optidnums, 1:numel(optidnums)) )
                error("there should be one integer per optind, sequentially from 1 to max, you may have an optind with an invalid name; name should be i followed by an integer")
            end
            if isempty(optidnums)
                optidnew = 'i1';
                optfile.(optidnew) = optred;
                optout.(optidnew) = oone;
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
                        optout.(optidnew) = oone;
                        optid = [optid; optidnew];
                    end
                end
            end
        end

        fno = fieldnames(optout);
        for p = 1:numel(fno)
            optout.(fno{p}) = structunflat(optout.(fno{p}));
        end
        o(j).(vbintmp) = optout;
    end

    pthopt = '~/stacks/fool.txt';
    optfile = odf;
    optfile = structord(optfile, vectype='row');

    txt = jsonencode(optfile, PrettyPrint=true);
    txt = regexprep(txt,',\s+(?=\d)',','); % , white-spaces digit remove
    txt = regexprep(txt,',\s+(?=-)',','); % , white-spaces minussign remove
    txt = regexprep(txt,'[\s+(?=\d)','['); % [ white-spaces digit remove
    txt = regexprep(txt,'[\s+(?=-)','['); % [ white-spaces minussign remove
    txt = regexprep(txt,'(?<=\d)\s+]',']'); % digit white-spaces ] remove

    fid = fopen(pthopt, 'w');
    fprintf(fid,'%s',txt);
    fclose(fid);

end

o = structord(o, vectype='row');








