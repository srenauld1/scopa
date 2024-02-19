
function cx_delete_caiman_fails(fn_pattern, fn_prefix, region_extraction_all)

%save caiman params that failed for each region and delete files


caimanfail = cell(500, length(region_extraction_all));

for ri = 1:length(region_extraction_all)

    failmode = strsplit(fn_pattern{ri}, '_');
    failmode = failmode{end-1};

    caimanfail{1,ri} = region_extraction_all{ri};
    failfnall = rdir(fn_pattern{ri});
    clear failtmp
    if length(failfnall)>size(caimanfail, 1)
        error
    end
    if ~isempty(failfnall)
        for ci = 1:length(failfnall)
            [~, fncr, ~] = fileparts(failfnall(ci).name);
            spl = strsplit(fncr, '_');
            %keep datestr in case you run more caiman, don't want to
            %overwrite previous fail records (in future should 
            %append to existing fail records
            filename_save = [fn_prefix strjoin(spl(1:4), '_') '_' strjoin(region_extraction_all, '_') '_caimanfails_' failmode  '_' datestr(now, 30) '_.mat'];
            failtmp{ci} = strjoin(spl(find(strcmp(spl, 'cmex'))+1:end-2), '_');
        end
        caimanfail([1:length(failtmp)]+1,ri) = natsortfiles(failtmp(:));
        if 1 % delete_failures
            delete(failfnall.name)
        end
    end
end
if exist('filename_save', 'var')
    save(filename_save, 'caimanfail', '-v7.3', '-mat')
end

