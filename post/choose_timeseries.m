function [fitin, regionex, parsex, parsnorm, dofit, fieldspecstr_single] = ...
    choose_timeseries(opt, ts, md, pth_parsall_save, fitcount, dofit)



if fitcount>1 %isfile(pth_parsall_save)

    load(pth_parsall_save)

else
    fieldspec_parent_fields = {'indv', 'depv'};

    count = zeros(length(fieldspec_parent_fields), 1);
    for ofi = 1:length(opt)

        combinecell = {};
        for vpfi = 1:length(fieldspec_parent_fields)
            combinecell{vpfi} = opt(ofi).(fieldspec_parent_fields{vpfi});
        end
        if strcmp(opt(ofi).depv_indv_combine, 'any')
            combinecell = table2cell(combinations(combinecell{:})); %make all combos of indv/depv outer cells
            for vpfi = 1:length(fieldspec_parent_fields)
                opt(ofi).(fieldspec_parent_fields{vpfi}) = combinecell(:, vpfi);
            end
        elseif strcmp(opt(ofi).depv_indv_combine, 'each')
            fuke=2;

        end


        for vpfi = 1:length(fieldspec_parent_fields)
            outercell = opt(ofi).(fieldspec_parent_fields{vpfi});
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
                        if opt(ofi).ignore_missing_vars
                            disp("REQUESTED SUBFIELD '" + varsubstr{1} + "' DOES NOT CURRENTLY EXIST IN STRUCT 'ts'")
                        else
                            error("REQUESTED SUBFIELD '" + varsubstr{1} + "' DOES NOT CURRENTLY EXIST IN STRUCT 'ts'")
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
                    for tci = 1:size(tmpcat, 1)
                        strcount = strcount+1;
                        suffixtmp = strjoin(tmpcat(tci,:), '.');
                        fieldspecstr(count(vpfi)).(fieldspec_parent_fields{vpfi}){strcount, 1} = ['ts.' suffixtmp];
                    end


                end

                maxlen = max(cellfun(@width, tmp));
                tmp = cellfun(@(s) [s, repmat({''}, height(s), maxlen - width(s))], tmp, 'UniformOutput', false); %can't cat to empty for the max len tables, so doing loop
                tmpcat = vertcat(tmp{:});
                fieldspec(count(vpfi)).(fieldspec_parent_fields{vpfi}) = tmpcat;


            end
        end
    end

    save(pth_parsall_save, 'fieldspecstr', 'fieldspec', '-v7.3', '-mat')

end


fieldspecstr_single = fieldspecstr(fitcount);
fn = fieldnames(fieldspecstr_single);
for fi = 1:length(fn)
    fitin.(fn{fi}) = [];
    for vsi2 = 1:length(fieldspecstr_single(fitcount).(fn{fi}))
        tmp = eval(fieldspecstr_single(fitcount).(fn{fi}){vsi2});
        if size(tmp, 2)~=length(md.ti)
            tmp = tmp.';
        end
        if size(tmp, 2)~=length(md.ti)
            error("timeseries is does not match number imaging volumes (length md.ti)")
        end
        fitin.(fn{fi}) = cat(1, fitin.(fn{fi}), tmp);
        if strcmp(fn{fi}, 'depv')
            regionex = fieldspec(fitcount).(fn{fi}){vsi2,2}{1};
            parsex = fieldspec(fitcount).(fn{fi}){vsi2,3}{1};
            parsnorm = fieldspec(fitcount).(fn{fi}){vsi2,4}{1};
        end
    end
end


if fitcount==length(fieldspecstr) %quit flag on final
    dofit = 0;
end
