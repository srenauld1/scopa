
%various ways to fix saved data in scopa and stacks

suffix = 'roi'; %'mm'
[~, ~, fuk] = structfile('/Users/wienecke/scopa/opt_rg_cw_.txt', s=[], nm=[], usegit=0, dosort=0);
tmp = rdir(['/Users/wienecke/stacks/**/*' suffix '_.mat']);
for k = 1:numel(tmp)
    pth = tmp(k).name;
    if strcmp(suffix, 'mm')
        mm = load(pth);
        for kk = 1:numel(mm)
            inl = fieldmatch(fuk, {'id', mm(kk).rg.id}, lev=1, multi=0);
            if isempty(inl)
                if startsWith(mm(kk).rg.id, 'a')
                    inl = fieldmatch(fuk, {'id', mm(kk).rg.id(2:end)}, lev=1, multi=0);
                else
                    error()
                end
            end
            mm(kk).rg = fuk.(inl);
        end
        save(pth, '-struct', 'mm', '-v7.3', '-mat')
    elseif strcmp(suffix, 'roi')
        roi = load(pth);
        if numel(roi)>1 || isempty(numel(roi.dat)) || numel(roi.dat)>2
            error()
        end
        for kk = 1:numel(roi.dat)
            inl = fieldmatch(fuk, {'id', roi.dat(kk).rg.id}, lev=1, multi=0);
            if isempty(inl)
                if startsWith(roi.dat(kk).rg.id, 'a')
                    inl = fieldmatch(fuk, {'id', roi.dat(kk).rg.id(2:end)}, lev=1, multi=0);
                else
                    error()
                end
            end
            roi.dat(kk).rg = fuk.(inl);
            if numel(roi.dat(kk).mm)>2 || numel(roi.dat(kk).mm)<1
                error()
            else
                for kkj = 1:numel(roi.dat(kk).mm)
                    roi.dat(kk).mm(kkj).rg = fuk.(inl);
                end
            end
        end
        save(pth, '-struct', 'roi', '-v7.3', '-mat')
    end
end