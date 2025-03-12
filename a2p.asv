
% see docs_a2p

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

clear glb %clear globals

oa = oset(specin); % set options; oa stands for o all (ie all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o

    %% paths

    pth = pthmake(o.id.pthstack);
    glb(1, pthstackdir=pth.stackdir, pthstack=pth.stack); %update some globals

    %% stack

    for m = transpose(fieldnames(o.sld))
        stack = stackld(o.sld.(m{1})); %load/process stack
    end

    %% metadata

    md = mdsild(pth.stack); 

    %% daq

    for m = transpose(fieldnames(o.daq))
        daq.(m{1}) = daqld(o.daq.(m{1})); %process daq
    end

    try
        t = daq.(m{1}).t; 
    catch
        t = md.sper:md.sper:md.numvol*md.sper;
    end

    %% rois

    if o.mn.doroi
        for m = transpose(fieldnames(o.roi))
            roi.(m{1}) = roimake(stack, pth.stack, o.roi.(m{1}), md.sper, md.widyxz, t); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %% bump

    if o.mn.dobmp
        for m = transpose(fieldnames(o.bmp))
            epochtmp = daq.a1.epochts;
            bmp.(m{1}) = bmpmake(o.bmp.(m{1}), [], [], [], md.volrate, epochtmp); %fit bump
        end
    end

    %% flymax

    if o.mn.dofmf
        for m = transpose(fieldnames(o.fmf))
            [fmf.(o.fmf.id), fmfvid] = flymaxfe(pth.stack, o.fmf); %extract flymax visual features
        end
    end

    %% models

    if o.mn.dofit
        for m = transpose(fieldnames(o.mdl))

            o.mdl.(m{1}).indv.tg=[];
            o.mdl.(m{1}).depv.tg=[];

            bmpmu = bmp.a1.mu;
            bmpvel = tsdv('circular', bmpmu, 0.2, 2, md.sper);
            ballyaw = daq.a1.by;
            ballvel = tsdv('circular', -ballyaw, 0.2, 2, md.sper);
            cueyaw = daq.a1.vy;
            cuevel = tsdv('circular', cueyaw, 0.2, 2, md.sper);

            indv = [ballvel; bmpvel];
            indv = [ballvel; cuevel];
            % indv = [ballvel; cueyaw];
            %indv = [ballyaw; cueyaw];
            % indv = [ballvel];
            % indv = [ballyaw; cueyaw];

            noresp = roi.a2.ts{1};
            noz = zscore(noresp);
            % nodv = tsdv('normal', noresp, 0.2, 2, md.sper);
            % nozdv = tsdv('normal', noz, 0.2, 2, md.sper);
            depv = noz;
            % depv = nozdv;


            o.mdl.(m{1}).epochnum = [2 3 4 5];
            o.mdl.(m{1}).mdlname = 'svd_0.9999999';
            o.mdl.(m{1}).mdlname = 'fnet_A01_v_A02_v_B_f';
            o.mdl.(m{1}).mdlname = 'svd_0.9';
            o.mdl.(m{1}).lensec = 0.5;
            o.mdl.(m{1}).lagsec = 0;
            o.mdl.(m{1}).valnum = 1;
            o.mdl.(m{1}).opl.MaxFunctionEvaluations = Inf;
            o.mdl.(m{1}).opl.MaxIterations = Inf;
            dopltmdl = 1;
            ldval = 0;
            mdl.(m{1}) = mdlmake(o.mdl.(m{1}), indv, depv, pth.stack, md.volrate, daq.a1.epochts, dopltmdl, ldval);
            
            %% 

            epochtmp = 4;
            btind = 2;
            blen = 122;
            te2 = find(daq.a1.epochts==epochtmp);
            bst = find(diff(te2)~=1);
            te3 = te2(bst(btind)); %one bout
            % te2 = te3:te3+blen*2;
            te2 = te3-blen*2:te3;
            % te2 = [te2(1)-numel(te2):te2(end)];
            figure; plot(roi.a2.ts{1}(te2)); hold on; yyaxis right; hold on; plot(ballvel(te2), '-r'); plot(bmpvel(te2), '-m')
            % figure; plot(roi.a2.ts{1}(te2)); hold on; plot(roi.a3.ts{1}(te2)); yyaxis right; hold on; plot(ballvel(te2), 'c'); plot(bmpvel(te2), 'g')
            % ha = area([4 6], [10 10]);
            figure; imagesc(bmp.a1.respcl(:, te2));

            %% 

        end
    end

    %% plots

    if o.mn.dopltx
        fn = fieldnames(o.pltx);
        for m = 1:numel(fn)
            pltx(stack(:,:,:,fk,:), mdl.vars, o.pltx.doui,  ...
                mdl.vnm, o.pltx.vpmap, o.pltx.epochnum, ...
                o.pltx.lagsxy_sec, o.pltx.lagsz_sec, o.pltx.lags_to_plot, ...
                o.pltx.plot_z_as_color, roidat.a1{1}, t, md.sper, zstartsub, ...
                vis.epochts, glb('pltvis'), o.pltx.iz, o.pltx.it, ...
                o.pltx.dr, mdl.fn_save_prefix_short, mdl.pthpre, ...
                pthroiint, nrm, md.widyxz, vid=ftv, stim=stimvid)
        end
    end


    %% specific

    ebno(stack, {'r'}, daq.a1.vy, daq.a1.by, bmp.a1.mu, bmp.a1.respcl, roi.a2.ts{1}, roi.a3.ts{1}, t, md.sper, pth.pre, plt=[0 0 1 0], facealpha=0.2, szthrres=[], szmin=10, szmaxfac=70, nothr='', colsep=0, xyrng=[], epoch={1}, epochts=daq.a1.epochts, lagsampxy=1, lagsampz=[-5:5], yconst=1, slopelensec=[0.4], bmpdomain=bmp.a1.domain)
    
    % t5tmp
    % ebtmp
    % mitotmp

    % epochtmp = 6;
    % te2 = find(daq.a3.epochts==epochtmp);
    % te2 = te2(1):te2(find(diff(te2)~=1, 1)); %one bout
    % te2 = [te2(1)-numel(te2):te2(end)];
    % inc = 5;
    % te2 = te2(1) : inc : te2(end);
    % stackplt3(stack, it=te2, style='MaximumIntensityProjection')


end



