

%% fix roi

% fnd = rdir('~/stacks/**/*roi_.mat');
% for k = 1:numel(fnd)
%     roi = load(fnd(k).name);
%     if any(~isfield(roi, {'ts', 'dat', 'maketime_optfile_roi'}))
%         error("roi struct must contain fields 'ts' and 'dat'; you may have loaded an old roi struct")
%     end
% 
%     for q = 1:numel(roi.dat)
%         if roi.dat{q}.chan==1 && q==1
%             fkk=roi.dat{q};
%             fkk.ts = roi.ts{q};
%         elseif roi.dat{q}.chan==2 && q==2
%             fkk = roi.dat{q};
%             fkk(2) = roi.dat{q};
%             fkk(2).ts = roi.ts{q};
%             fkk(1) = structfun(@(x) [], fkk(1), 'UniformOutput', false);
%         else
%             error("charuck")
%         end
%     end
%     roi = rmfield(roi, 'ts');
%     roi.dat = fkk;
% 
%     save(fnd(k).name, '-struct', 'roi', '-v7.3', '-mat')
% end

%% fix mm

fnd = rdir('~/stacks/**/*mm_.mat');
for k = numel(fnd)
    load(fnd(k).name, 'mm');
    if any(~isfield(mm{1}, {'mask', 'maskname', 'chan', 'methodmm', 'rg'})) || numel(mm)==2 && any(~isfield(mm{2}, {'mask', 'maskname', 'chan', 'methodmm', 'rg'}))
        error("mm struct must contain fields 'mask', 'maskname', 'chan', 'methodmm', 'rg'; you may have loaded an old mm struct")
    end
    
    for q = 1:numel(mm)
        if mm{q}.chan==1 && q==1
            fkk=mm{q};
        elseif mm{q}.chan==2 && q==2
            fkk = mm{q};
            fkk(2) = mm{q};
            fkk(1) = structfun(@(x) [], fkk(1), 'UniformOutput', false);
        else
            error("charuck")
        end
    end
    mm = fkk;

    save(fnd(k).name, '-struct', 'mm', '-v7.3', '-mat')
end