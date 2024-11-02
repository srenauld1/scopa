function o = optreduce(o, vbin)

%remove redundancy in options sets (before writing to options file and assigning options set index)

arguments
    o
    vbin
end

if ~iscell(vbin)
    vbin = {vbin};
end

for m = 1:numel(vbin)
    vbintmp = vbin{m};

    switch vbintmp
        case 'roi'
            fn = fieldnames(o);
            for k = 1:numel(fn)
                if o.domm==0 && startsWith(fn{k}, 'mm_')
                    o = rmfield(o, fn{k});
                end
                if o.doma==0 && startsWith(fn{k}, 'ma_')
                    o = rmfield(o, fn{k});
                end
                if o.doqc==0 && startsWith(fn{k}, 'fa_')
                    o = rmfield(o, fn{k});
                end
                if o.docm==0 && startsWith(fn{k}, 'cm_')
                    o = rmfield(o, fn{k});
                end
            end
            fn = fieldnames(o);
            for k = 1:numel(fn)
                if endsWith(fn{k}, 'doplt') %also remove doplt, since that's irrelevant to the data
                    o = rmfield(o, fn{k});
                end
            end
            if any(startsWith(fn, 'cm_')) %also remove doplt, since that's irrelevant to the data
                o = cmex_reduce(o);
            end


        case 'mfit'

        case 'feat'

    end

end

end
