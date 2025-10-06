
%various ways to fix saved data in scopa and stacks

clear all
close all
clc

dosave = 1;

suffix = 'mm'; %'roi' or 'mm'
[~, ~, fuk] = structfile('/Users/wienecke/scopa/opt_rg_cw_.txt', s=[], nm=[], usegit=0, dosort=0);
tmp = rdir(['/Users/wienecke/stacks/**/*' suffix '_.mat']);
for k = 1:numel(tmp)
    pth = tmp(k).name;


    if strcmp(suffix, 'mm')
        mm = load(pth);
        if numel(mm)>2
            error()
        elseif numel(mm)<1
            emptymm=1;
        end
        % for kk = 1:numel(mm)
            % inl = fieldmatch(fuk, {'id', mm(kk).rg.id}, lev=1, multi=0);
            % if isempty(inl)
            %     if startsWith(mm(kk).rg.id, 'a')
            %         inl = fieldmatch(fuk, {'id', mm(kk).rg.id(2:end)}, lev=1, multi=0);
            %     else
            %         error()
            %     end
            % end
            % mm(kk).rg = fuk.(inl);
        % end
        for kkj = 1:numel(mm)
            if ~isfield(mm(kkj), 'chanstr')
                mm(kkj).chanstr = mm(kkj).methodmm;
                mm = rmfield(mm, 'methodmm');
                mm(kkj).channel = mm(kkj).chan;
                mm = rmfield(mm, 'chan');
            end
            if ~isfield(mm(kkj), 'mmname')
                mm(kkj).mmname = mm(kkj).mmname;
                if kkj == numel(mm)
                    mm = rmfield(mm, 'mmname');
                end
            end
            if ~isfield(mm(kkj).rg, 'rgname')
                mm(kkj).rg.rgname = mm(kkj).rg.name;
                if kkj == numel(mm)
                    mm(kkj).rg= rmfield(mm(kkj).rg, 'name');
                end
            end
        end
        if dosave
            save(pth, '-struct', 'mm', '-v7.3', '-mat')
        end


    elseif strcmp(suffix, 'roi')

        roi = load(pth);

        if numel(roi)>1 || isempty(numel(roi.dat)) || numel(roi.dat)>2
            error()
        end


        if isfield(roi, 'opt') && ~isfield(roi.opt.mm, 'chanstr')
            % roi.dat(kk).mm(kkj).rg = fuk.(inl);
            roi.opt.mm.chanstr = roi.opt.mm.methodmm;
            roi.opt.mm = rmfield(roi.opt.mm, 'methodmm');
        end


        for kk = 1:numel(roi.dat)
            % inl = fieldmatch(fuk, {'id', roi.dat(kk).rg.id}, lev=1, multi=0);
            % if isempty(inl)
            %     if startsWith(roi.dat(kk).rg.id, 'a')
            %         inl = fieldmatch(fuk, {'id', roi.dat(kk).rg.id(2:end)}, lev=1, multi=0);
            %     else
            %         error()
            %     end
            % end
            % roi.dat(kk).rg = fuk.(inl);
            if numel(roi.dat(kk).mm)>2
                error()
            elseif numel(roi.dat(kk).mm)<1
                emptymm=1;
            else
                for kkj = 1:numel(roi.dat(kk).mm)
                    if ~isfield(roi.dat(kk).mm(kkj), 'chanstr')
                        % roi.dat(kk).mm(kkj).rg = fuk.(inl);
                        roi.dat(kk).mm(kkj).chanstr = roi.dat(kk).mm(kkj).methodmm;
                        roi.dat(kk).mm = rmfield(roi.dat(kk).mm, 'methodmm');
                        roi.dat(kk).mm(kkj).channel = roi.dat(kk).mm(kkj).chan;
                        roi.dat(kk).mm = rmfield(roi.dat(kk).mm, 'chan');
                    end
                    if ~isfield(roi.dat(kk).mm(kkj), 'mmname')
                        roi.dat(kk).mm(kkj).mmname = roi.dat(kk).mm(kkj).mmname;
                        if kkj == numel(roi.dat(kk).mm)
                            roi.dat(kk).mm = rmfield(roi.dat(kk).mm, 'mmname');
                        end
                    end
                    if ~isfield(roi.dat(kk).mm(kkj).rg, 'rgname')
                        roi.dat(kk).mm(kkj).rg.rgname = roi.dat(kk).mm(kkj).rg.name;
                        if kkj == numel(roi.dat(kk).mm)
                            roi.dat(kk).mm(kkj).rg= rmfield(roi.dat(kk).mm(kkj).rg, 'name');
                        end
                    end
                end
            end
        end
        if dosave
            save(pth, '-struct', 'roi', '-v7.3', '-mat')
        end


        
    end
end