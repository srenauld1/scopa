

clear all
close all
clc


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

pthparent = pathparentfind;

for q = 1:numel(renm)
    nmtmp = strsplit(renm{q}, ':');
    if numel(nmtmp)~=2
        error
    end
    nmold = strtrim(nmtmp{1});
    nmnew = strtrim(nmtmp{2});

    pthpat = [pthparent '**/*' nmold '*'];
    pth = rdir(pthpat);
    pthnew = cell(numel(pth),1);
    for k = 1:numel(pth)
        pthnew{k} = strrep(pth(k).name, nmold, nmnew);
        movefile(pth(k).name, pthnew{k})
    end
end


% renm = { ...
%     'raw: o' ...
%     'cmrg: r', ...
%     'dcdn: d', ...
%     'bksb: b', ...
%     'nosn: s', ...
%     };
% 
% pthpat = '/Users/wienecke/stacks/**/*';
%
% pthtmp = rdir(pthpat);
% pthold = cell(numel(pthtmp),1);
% pthnew = cell(numel(pthtmp),1);
% for k = 1:numel(pthtmp)
%     pthold{k} = pthtmp(k).name;
%     [pp, fn, ext] = fileparts(pthold{k});
%     fnprefix = strsplit(fn, '_');
%     fnprefix = strjoin(fnprefix(1:3), '_');
%     tmp = regexp(fn, '^\d+_\d+_\d+_(.)*_$', 'tokens');
%     if ~isempty(cellflat(tmp))
%         if ~isscalar(cellflat(tmp))
%             error
%         end
% 
%         tmp = ['_' tmp{1}{1}];
%         for q = 1:numel(renm)
%             nmtmp = strsplit(renm{q}, ':');
%             if numel(nmtmp)~=2
%                 error
%             end
%             nmold = strtrim(nmtmp{1});
%             nmnew = strtrim(nmtmp{2});
%             if ~isempty(strfind(tmp, ['_' nmold]))
%                 fuk=2
%             end
%             tmp = strrep(tmp, ['_' nmold], nmnew);
%         end
% 
%         if ~contains(tmp, 'o')
%             tmp = ['o' tmp];
%         end
%         fnnew = [fnprefix '_' tmp '_'];
%         pthnew{k} = [pp, filesep, fnnew, ext];
%         % movefile(pth{k}, pthnew{k})
%     end
% end
