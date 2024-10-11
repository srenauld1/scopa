function [tsuse, dochoose] = tsget(vnm, ts, ti, pth_tsuse_nms_prefix, pth_stack, choosecount, dochoose)

% select timeseries from 'ts' whose flattened nested struct fieldnames match vnm pattern,
% output variables, their names, and some info in struct 'tsuse'

timedim = 2; %for now hard code to assume second dim is time 
force_single_precision = 1;
must_have_full_var_sets = 0;

pth_tsuse_nms = [pth_tsuse_nms_prefix num2str(choosecount) '_.mat'];

%%% FLATTEN TIMESERIES STRUCT ts FOR SIMPLE MATCHING WITH USER INPUT PATTERN vnm %%%

[sflat, fnflat, fnflatex] = structflat(ts);
sflat = struct2cell(sflat);
if force_single_precision
    sflat = cellfun(@single, sflat, 'UniformOutput', false);
end

%%% TRANFORM INPUT VARNM PATTERNS FROM NESTED CELL TO UN-NESTED CELL, TO RUN unique ON IT AND REMOVE DUPLICATE PATTERNS %%%

fn = fieldnames(vnm);

tmp2 = cell(numel(fn),1);
for vpfi = 1:numel(fn)
    tmp = cell(numel(vnm.(fn{vpfi})),1);
    for j = 1:numel(vnm.(fn{vpfi}))
        tmp{j} = strjoin(vnm.(fn{vpfi}){j}, ', ');
    end
    tmp2{vpfi} = tmp;
end
tmp2 = cellfun(@(x) unique(x, 'stable'), tmp2, 'UniformOutput', false);


%%% MAKE ALL COMBINATIONS OF PATTERNS ACROSS fn %%%

tmp2 = table2cell(combinations(tmp2{:})); %make all combos of vnm fields outer cells
tmp3 = cell(size(tmp2));
for vpfi = 1:size(tmp2, 2)
    for j = 1:size(tmp2, 1)
        tmp3{j, vpfi} = strsplit(tmp2{j, vpfi}, ', ');
    end
end

%%% FLATTEN TIMESERIES STRUCT ts AND FIND MATCHES WITH PATTERNS IN vnm %%%

tsflatcat = cell(size(tmp3'));
fnflatcat = cell(size(tmp3'));
for vpfi = 1:size(tmp3,2)
    outercell = tmp3(:,vpfi);
    for oci = 1:numel(outercell) %for each outer cell (matches are kept separate)
        innercell_tmp = outercell{oci};
        tsflatcat{vpfi,oci} = [];
        fnflatcat{vpfi,oci} = [];
        for ici = 1:numel(innercell_tmp) %for each inner cell (matches are concatenated)
            icpat = regexptranslate('wildcard', innercell_tmp{ici});
            icpat = [icpat '$']; %mark end of pattern
            
            chk = cellfun(@(x,y) regexp(x,y), fnflatex, repelem({icpat}, numel(fnflatex))', 'UniformOutput', false);
            kpp = cell(numel(chk),1);
            for j = 1:numel(chk)
                kpp{j} = find(~cellfun(@isempty, chk{j}));
            end
            fnflat_tmp = cellfun( @(x,y) x(y), fnflatex, kpp, 'UniformOutput', false);

            if all(cellfun(@isempty, fnflat_tmp)) % if no match, check for match without the 'ind' suffix, in fnflat, rather than fnflatex
                chk = regexp(fnflat, icpat);
                kpp = find(~cellfun(@isempty, chk));
                fnflat_tmp = fnflatex(kpp);
                if kpp
                    sflat_tmp = vertcat(sflat{kpp});
                else
                    fnflat_tmp = cellfun( @(x,y) x(y), fnflatex, repelem({kpp}, size(sflat,1), 1), 'UniformOutput', false);
                    try
                        sflat_tmp = cell2mat(cellfun( @(x,y) x(y,:), sflat, repelem({kpp}, size(sflat,1), 1), 'UniformOutput', false)); %if it's empty do this to make empty arrays with size matching nonempty in time dimension
                    catch
                    hh=2;
                    end
                end
            else
                sflat_tmp = cell2mat(cellfun( @(x,y) x(y,:), sflat, kpp, 'UniformOutput', false));
            end

            fnflat_tmp = vertcat(fnflat_tmp{:});

            fnflatcat{vpfi,oci} = cat(1, fnflatcat{vpfi,oci}, fnflat_tmp);
            tsflatcat{vpfi,oci} = cat(1, tsflatcat{vpfi,oci}, sflat_tmp);
        end

    end
end


if must_have_full_var_sets %remove an entire var set if any one fn is missing (ts struct has no match with vnm)
    fnflatcat = fnflatcat(:,~sum(cell2mat(cellfun(@isempty, fnflatcat, 'UniformOutput', false)))); %remove any empty cells, where there are no matches to vnm pattern
    tsflatcat = tsflatcat(:,~sum(cell2mat(cellfun(@isempty, tsflatcat, 'UniformOutput', false)))); %remove any empty cells, where there are no matches to vnm pattern
end


numsamp = cell2mat(cellfun(@(x) size(x,timedim), tsflatcat, 'UniformOutput', false));
numsamp = numsamp(numsamp~=0); %remove zeros in case remove_missing==0
if ~all(numsamp==numel(ti))
    error("timeseries is does not match number imaging volumes (numel ti)")
end


save(pth_tsuse_nms, 'fnflatcat', '-v7.3', '-mat') %save since this only needs to


%%% SUBSET WITH choosecount AND ORGANIZE INTO STRUCT tsuse %%%

tsuse.numsamp = numsamp;
tsuse.timedim = timedim;
tsuse.vnm = cell2struct(fnflatcat(:,choosecount), fn);
tsuse.vars = cell2struct(tsflatcat(:,choosecount), fn);


%%% MAKE SURE THERE IS ONLY ONE REGIONEX (FOR NOW) %%%

regionex_cat = [];
for fi = 1:numel(fn)
    for vni = 1:numel(tsuse.vnm.(fn{fi}))
        if startsWith(tsuse.vnm.(fn{fi}){vni}, 'resp')
            varnmtmp = strsplit(tsuse.vnm.(fn{fi}){vni}, '.');
            tsuse.regionex = varnmtmp{2};
            tsuse.parsex = varnmtmp{3};
            tsuse.parsnorm = varnmtmp{4};

            regionex_cat = cat(1, regionex_cat, {tsuse.regionex});
            if numel(unique(regionex_cat))~=1
                error("tsuse cannot yet use multiple regionex across input vars; in future crop_stack will just have to loop over them and cat the regionex stacks in xy")
                % tsuse.regionex = 'default';
            end
        end
    end
end

if ~isfield(tsuse, 'regionex')
    tsuse.regionex = 'default';
    tsuse.parsex = 'noparsex';
    tsuse.parsnorm = 'noparsnorm';
end


%%% SET PATHS, ORDER FIELDS, AND STOP dochoose WHILE LOOP IF AT END %%%

tsuse.choosecount = choosecount;
tsuse.fn_save_prefix = [pth_stack(1:end-4) tsuse.regionex '_' tsuse.parsex '_' tsuse.parsnorm '_fit' num2str(tsuse.choosecount)];
tsuse.fn_save_prefix_short = [pth_stack(1:end-4) '_fit' num2str(tsuse.choosecount)];


tsuse = fieldord(tsuse);

if choosecount==size(fnflatcat, 2) %quit flag on final set of vnm (length of nonscalar struct)
    dochoose = 0;
end

