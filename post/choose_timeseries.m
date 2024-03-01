function ts = choose_timeseries(opt, ts)

for ofi = 1:length(opt)
    outercell = opt(ofi).indv;
    for oci = 1:length(outercell) %for each outer cell
        innercell = outercell{oci};
        for ici = 1:length(innercell) %for each inner cell
            varstr = innercell{ici}; %variable specification string
            varsubstr = strsplit(varstr, ', '); %variable specification substrings
            clear tstmp
            tstmp{1} = ts;
            fn = fieldnames(tstmp{1});
            keepfields = [];
            keepfields{1} = fn(find( ~cellfun( @isempty, regexp( fn, regexptranslate('wildcard', varsubstr{1}) ) ) ) );
            breaktmp = 0;
            for ssi = 2:length(varsubstr) %for each substring
                for fi = 1:length(keepfields(ssi-1)) %for each field
                    try
                        fn = fieldnames(tstmp{ssi-1}.(keepfields{ssi-1}{fi}));
                        keepfields{ssi} = fn( find( ~cellfun( @isempty, regexp( fn, regexptranslate('wildcard', varsubstr{ssi})  ) ) ) );
                        tstmp{ssi} = tstmp{ssi-1}.(keepfields{ssi-1}{fi});
                    catch
                        disp(["no field matching string: " varsubstr{ssi-1}])
                        breaktmp = 1;
                        break;
                    end
                    % if ssi==length(depv_str_spl)
                    %     tstmp{ssi-1} = ts;
                    % end
                end
                if breaktmp
                    break;
                end
            end

            % keepfields_all{si} = keepfields;
            tmp{ici} = combinations(keepfields{:}); %all combinations after expanding the string
            % onecell_allcombos = [onecell_allcombos; tmp];

        end

        maxlen = max(cellfun(@width, tmp));
        % tmp = cellfun(@(s) [s, repmat({''}, 1, maxlen - width(s))], tmp, 'UniformOutput', false); %can't cat to empty for the max len tables, so doing loop
        tmpall = [];
        for i = 1:length(tmp)
            if maxlen ~= width(tmp{i})
                tmp{i} = [ tmp{i}, repmat({''}, 1, maxlen - width(tmp{i})) ];
            end
            tmpall = [tmpall; tmp{i}];
        end
    end

end


ts = 1;regexptranslate('wildcard', 'abc*x')