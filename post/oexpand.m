function o = oexpand(o, vbin)

arguments
    o
    vbin
end

if ~iscell(vbin)
    vbin = {vbin};
end

for j = 1:numel(o)
    for k = 1:numel(vbin)
        vbintmp = o(j).(vbin{k});
        fn = fieldnames(vbintmp);
        alltmp = struct;
        for m = 1:numel(fn)
            copybintmp = vbintmp.(fn{m});
            optflat = structflat(copybintmp, prefix=fn{m});
            fnflat = fieldnames(optflat);
            % if any(~cellfun(@isempty, regexp(fnflat,'_[\d]*_')))
            %     error("cannot use nonscalar structs in o")
            % end

            fnnew = [fn{m} '_' num2str(1)];
            tmp = [];
            tmp.(fnnew) = struct;
            expandinds = zeros(numel(fnflat), 1, 'logical');
            for p = 1:numel(fnflat)
                tmpset = fieldnames(tmp);
                numset = numel(tmpset);
                if iscell(optflat.(fnflat{p})) && numel(optflat.(fnflat{p}))>1
                    expandinds(p) = 1;
                    for w = 1:numel(optflat.(fnflat{p}))
                        for ww = 1:numset
                            newind = ww+numel(numset)*(w-1);
                            fnnew = [fn{m} '_' num2str(newind)];
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p}){w};
                        end
                    end
                end
            end
            tmpset = fieldnames(tmp);
            numset = numel(tmpset);
            for p = 1:numel(fnflat)
                if ~expandinds(p)
                    for ww = 1:numset
                        fnnew = [fn{m} '_' num2str(ww)];
                        if iscell(optflat.(fnflat{p}))
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p}){1}; %since singleton, take it out of cell
                        else
                            tmp.(fnnew).(fnflat{p}) = optflat.(fnflat{p});
                        end
                    end
                end
            end

            alltmp = cell2struct([struct2cell(alltmp); struct2cell(tmp)], [fieldnames(alltmp); fieldnames(tmp)]); %combine

            alltmp = fieldord(alltmp);
            
        end

    end

end








