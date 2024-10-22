function o = oexpand(o, vbin)

arguments
    o
    vbin
end


for j = 1:numel(o)
    for k = 1:numel(vbin)
        vbintmp = o(j).(vbin{k});
        fn = fieldnames(vbintmp);
        for m = 1:numel(fn)
            copybintmp = vbintmp.(fn{w});
            opts = fieldnames(copybintmp);
            setcnt = 0;
            for p = 1:numel(opts)
                setcnt = stecnt+1;
                if iscell(opts{p})
                    for w = 1:numel(opts{p})
                        tmp.(vbintmp).(fn{w}) = opts{p}{w};
                    end
                else
                    tmp.(vbintmp).(fn{w}) = opts{p};
                end
                if p==numel(opts)
                    tmp.(vbintmp).(fn{w}) = opts{p}{w};
                end
            end
        end

    end

end








