function optout2 = structunpack(optout,mosc_all,mostree_open_with_mosc_descend)

arguments
    optout (1,1) struct
    mosc_all
    mostree_open_with_mosc_descend
end

mosc_all_loc = strcat(mosc_all(:,1), '.', mosc_all(:,2));

optout2 = struct;
mosc_par_finished = {};
for k = 1:numel(flip(mostree_open_with_mosc_descend))
    stind = structind(mostree_open_with_mosc_descend{k});
    try
        tmp = getfield(optout, stind{:});
        mos_exists = 1;
    catch %skip trying to get submos when supermos is empty
        mos_exists = 0;
    end
    if mos_exists
        idx_mosc = find(strcmp(mostree_open_with_mosc_descend{k}, mosc_all_loc),1);
        idx_mosc_par_finished = find(strcmp(mostree_open_with_mosc_descend{k}, mosc_par_finished),1);
        if isempty(idx_mosc_par_finished) %skip parent mos of mosc that have been expanded into nonscalar struct versions
            if isempty(idx_mosc)
                mosc_expr = strcat('\.', mosc_all(:,2), '((\.\w+)*)?$');  %see regexprep  below
                mos_nomosc = regexprep(mostree_open_with_mosc_descend{k}, mosc_expr, '$1'); %replace dot followed by mosc, keep any trailing dot followed by alphanumeric or underscore chars 
                stind = structind(mos_nomosc);
                optout2 = setfield(optout2, stind{:}, tmp);
            else
                mosc_par = mosc_all{idx_mosc,1};
                optout2.(mosc_par)(k) = tmp;
                mosc_par_finished = unique(cat(2, mosc_par_finished, mosc_par)); %parent mos of mosc that have been operated on
            end
        end
    end
end

%
% fn = fieldnames(s);
% for k = 1:numel(fn)
%     fn2 = fieldnames(s.(fn{k}));
%     for m = 1:numel(fn2)
%         out.(fn{k})(m).(fn2{m}) = s.(fn{k}).(fn2{m});
%     end
% end

% 
% fieldn = fieldnames(s);
% fieldv = struct2cell(s);
% nfield = length(fieldn);
% c1 = cell(2*nfield,1);
% c1(1:2:end) = fieldn;
% c1(2:2:end) = fieldv;
end
