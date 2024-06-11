function [fitin, dochoose] = choose_timeseries(opt, ts, md, pth_tsuse_save, pth_stack_analysis, choosecount, dochoose)

% for convenience, saves substrings used to match variable within 'ts'
% as table ('fieldspec_all') and as string ('fieldspecstr_all')

if choosecount>1 %the set of all 'vars' fields combos is determined on the first fit (choosecount==1), so subsequent calls to choose_timeseries just

    load(pth_tsuse_save)

else

    fieldspec_parent_fields = fieldnames(opt(1).vars);

    count = zeros(length(fieldspec_parent_fields), 1);
    for ofi = 1:length(opt)

        combinecell = {};
        for vpfi = 1:length(fieldspec_parent_fields)
            combinecell{vpfi} = opt(ofi).vars.(fieldspec_parent_fields{vpfi});
        end
        if strcmp(opt(ofi).vars_combine, 'any')
            combinecell = table2cell(combinations(combinecell{:})); %make all combos of vars fields outer cells
            for vpfi = 1:length(fieldspec_parent_fields)
                opt(ofi).vars.(fieldspec_parent_fields{vpfi}) = combinecell(:, vpfi);
            end
        elseif strcmp(opt(ofi).vars_combine, 'each')
            error("is this optimized?")
        end

        for vpfi = 1:length(fieldspec_parent_fields)
            outercell = opt(ofi).vars.(fieldspec_parent_fields{vpfi});
            for oci = 1:length(outercell) %for each outer cell (results are kept separate)
                count(vpfi) = count(vpfi)+1;
                innercell = outercell{oci};
                tmp = {};
                strcount = 0;
                for ici = 1:length(innercell) %for each inner cell (results are concatenated)
                    varstr = innercell{ici}; %variable specification string
                    varsubstr = strsplit(varstr, ', '); %variable specification substrings
                    clear tstmp
                    tstmp{1} = ts;
                    fn = fieldnames(tstmp{1});
                    keepfields = [];
                    if contains(varsubstr{1}, '*')
                        keepfields{1} = fn(find( ~cellfun( @isempty, regexp( fn, regexptranslate('wildcard', varsubstr{1} ) ) ) ) );
                    else
                        keepfields{1} = fn(strcmp( fn, varsubstr{1} ) );
                    end
                    if isempty(keepfields{1})
                        if isempty(varsubstr{1})
                            disp("PASSED EMPTY STRING TO " + fieldspec_parent_fields{vpfi})
                        else
                            if opt(ofi).ignore_missing_vars
                                disp("REQUESTED SUBFIELD '" + varsubstr{1} + "' DOES NOT CURRENTLY EXIST IN STRUCT 'ts', 'IGNORING IT BECAUSE ignore_missing_vars=1")
                            else
                                error("REQUESTED SUBFIELD '" + varsubstr{1} + "' DOES NOT CURRENTLY EXIST IN STRUCT 'ts'")
                            end
                        end
                    end
                    breaktmp = 0;
                    for ssi = 2:length(varsubstr) %for each substring
                        for fi = 1:length(keepfields(ssi-1)) %for each matching field
                            try
                                fn = fieldnames(tstmp{ssi-1}.(keepfields{ssi-1}{fi})); %list all fields
                                if contains(varsubstr{ssi}, '*')
                                    keepfields{ssi} = fn( find( ~cellfun( @isempty, regexp( fn, regexptranslate('wildcard', varsubstr{ssi})  ) ) ) ); %find matching fields
                                else
                                    keepfields{ssi} = fn( strcmp( fn, varsubstr{ssi} ) ); %find matching fields
                                end
                                tstmp{ssi} = tstmp{ssi-1}.(keepfields{ssi-1}{fi}); %enter matching subfield
                            catch
                                if opt(ofi).ignore_missing_vars
                                    disp("no field matching string: " + varsubstr{ssi-1})
                                    breaktmp = 1;
                                    break;
                                else
                                    error("no field matching string: " + varsubstr{ssi-1})
                                end
                            end
                        end
                        if breaktmp
                            break;
                        end
                    end

                    tmp{ici} = combinations(keepfields{:}); %all combinations after expanding the string

                    tmpcat = table2cell(tmp{ici});
                    if isempty(tmpcat)
                        fieldspecstr_all(count(vpfi)).(fieldspec_parent_fields{vpfi}){1, 1} = '';
                    else
                        for tci = 1:size(tmpcat, 1)
                            strcount = strcount+1;
                            suffixtmp = strjoin(tmpcat(tci,:), '.');
                            fieldspecstr_all(count(vpfi)).(fieldspec_parent_fields{vpfi}){strcount, 1} = ['ts.' suffixtmp];
                        end
                    end


                end

                maxlen = max(cellfun(@width, tmp));
                tmp = cellfun(@(s) [s, repmat({''}, height(s), maxlen - width(s))], tmp, 'UniformOutput', false); %can't cat to empty for the max len tables, so doing loop
                tmpcat = vertcat(tmp{:});
                fieldspec_all(count(vpfi)).(fieldspec_parent_fields{vpfi}) = tmpcat;


            end
        end
    end

    save(pth_tsuse_save, 'fieldspecstr_all', 'fieldspec_all', '-v7.3', '-mat')

end


fn = fieldnames(fieldspecstr_all(choosecount));
regionex_cat = [];
for fi = 1:length(fn)
    outfn = erase(fn{fi}, '_str');
    fitin.(outfn) = [];
    fitin.fieldspecstr.(fn{fi}) = [];
    for vsi2 = 1:length(fieldspecstr_all(choosecount).(fn{fi}))
        if isempty(fieldspecstr_all(choosecount).(fn{fi}){vsi2})
            tmp = [];
        else
            tmp = eval(fieldspecstr_all(choosecount).(fn{fi}){vsi2});
            if size(tmp, 2)~=length(md.ti)
                tmp = tmp.';
            end
            if size(tmp, 2)~=length(md.ti)
                error("timeseries is does not match number imaging volumes (length md.ti)")
            end
            fitin.(outfn) = cat(1, fitin.(outfn), tmp);
            fsstmp = repmat(fieldspecstr_all(choosecount).(fn{fi})(vsi2), size(tmp, 1), 1);
            fitin.fieldspecstr.(fn{fi}) = cat(1, fitin.fieldspecstr.(fn{fi}), fsstmp);
            if strcmp(fieldspec_all(choosecount).(fn{fi}){vsi2,1}{1}, 'resp')
                fitin.regionex = fieldspec_all(choosecount).(fn{fi}){vsi2,2}{1};
                fitin.parsex = fieldspec_all(choosecount).(fn{fi}){vsi2,3}{1};
                fitin.parsnorm = fieldspec_all(choosecount).(fn{fi}){vsi2,4}{1};

                regionex_cat = cat(1, regionex_cat, {fitin.regionex});
                if numel(unique(regionex_cat))~=1
                    error("fitin cannot yet decide how to use multiple regionex across input vars")
                    % fitin.regionex = 'backupdefault';
                end
            end
        end
    end
end

if ~isfield(fitin, 'regionex')
    fitin.regionex = 'backupdefault';
    fitin.parsex = 'noparsex';
    fitin.parsnorm = 'noparsnorm';
end

fitin.choosecount = choosecount;
fitin.fn_save_prefix = [pth_stack_analysis(1:end-4) fitin.regionex '_' fitin.parsex '_' fitin.parsnorm '_fit' num2str(fitin.choosecount)];
fitin.fn_save_prefix_short = [pth_stack_analysis(1:end-4) '_fit' num2str(fitin.choosecount)];

fitin = orderfields_recursive(fitin);
if choosecount==length(fieldspecstr_all) %quit flag on final
    dochoose = 0;
end

