

clear all
close all
clc

testrun = 0; %set to 1 to test the file renaming; set to 0 to actually rename

renm = { ... %do it in this order, staerting with longest suffixes (most compounded), to simplify the string replacement below (since we are removing some underscores), otherwise you need regexp (example below, commented out)
    '_bksb_cmrg_dcdn_nosn_: _obrds_', ...
    '_bksb_cmrg_dcdn_: _obrd_', ...
    '_bksb_cmrg_: _obr_', ...
    '_cmrg_dcdn_: _ord_', ...
    '_raw_: _o_' ...
    '_bksb_: _ob_', ...
    '_cmrg_: _or_', ...
    '_dcdn_: _od_', ...
    '_nosn_: _os_', ...
    };

pthpar = pthparget();

cnt = 0;
pthold = {};
pthnew = {};
for q = 1:numel(renm)
    nmtmp = strsplit(renm{q}, ':');
    if numel(nmtmp)~=2
        error
    end
    nmold = strtrim(nmtmp{1});
    nmnew = strtrim(nmtmp{2});

    pthpat = [pthpar '**/*' nmold '*'];
    pth = rdir(pthpat);
    for k = 1:numel(pth)
        if ~ismember(pth(k).name, pthold)
            cnt = cnt+1;
            pthold{cnt} = pth(k).name;
            pthnew{cnt} = strrep(pthold{cnt}, nmold, nmnew);
            if ~testrun
                movefile(pthold{cnt}, pthnew{cnt})
            end
        end
    end
end

if testrun
    for k = 1:numel(pthold)
        fprintf(string(pthold{k}) + newline + string(pthnew{k}) + newline + newline)
    end
end