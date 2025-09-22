

%{

see docs_a2p

%}

function a2p(specin)

arguments
    specin = '' %optional; full path to recording (char or cell, wildcards allow matching rules in rdir), or cell array of full paths (char), or struct with recording specifiers (see specin in oset and odf); if missing or empty, recording(s) searched for in oset using specifiers in oset
end

close all; clc; clear glb tsget


%% options

oa = oset(specin); % set options; oa stands for "o all" (ie options for all recordings)

for k = 1:numel(oa) % loop over recordings

    o = oa(k); %index into options for one recording, o
    glb(1, pthstackdir=o.id.pthstackdir, pthstack=o.id.pthstack, recid=o.id.recid, pthrec=o.id.pthrec); %update some globals that refer to stack location for this element of o

    
    %% stack

    for m = transpose(fieldnames(o.sld))
        [stack, pthstack_mat] = stackld(o.sld.(m{1}), o.id.pthstack); %load/process stack
    end
    o.id.pthstack = pthstack_mat; oa(k).id.pthstack = pthstack_mat; %update with .mat extension, in case it was tif going in to stackld


    %% metadata

    md = mdsild(o.id.pthstack);
    glb(1, md=md, srate=md.volrate, t=md.sper:md.sper:md.numvol*md.sper, epochts=ones(1, md.numvol));


    %% daq

    for m = transpose(fieldnames(o.daq))
        daq.(m{1}) = daqld(o.daq.(m{1})); %process daq
    end
    if ~isempty(daq.(m{1}))
        glb(1, t=daq.(m{1}).t, epochts=daq.(m{1}).epochts); %set global t using daq, overwriting metadata t
    end


    %% rois

    if o.mn.doroi
        for m = transpose(fieldnames(o.roi))
            roi.(m{1}) = roimake(o.roi.(m{1}), stack=stack); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %% bump

    if o.mn.dobmp
        for m = transpose(fieldnames(o.bmp))
            bmp.(m{1}) = bmpmake(o.bmp.(m{1})); %extract head direction bump
        end
    end


    %% flymax

    if o.mn.dofmf
        for m = transpose(fieldnames(o.fmf))
            [fmf.(o.fmf.(m{1}).id), fmfvid] = flymaxfe(o.id.pthstack, o.fmf.(m{1})); %extract flymax visual features
        end
    end


    %% models

    if o.mn.dofit
        for m = transpose(fieldnames(o.mdl))
            mdl.(m{1}) = mdlmake(o.mdl.(m{1}), doplt=1);
        end
    end


    %% interactive plots

    if o.mn.dopltx
        pltx(o.pltx, stack=stack, daq=daq, roi=roi, bmp=[], mdl=mdl, fmf=fmf, t=glb('t'), stimvid=fmfvid)
    end


    %% a_* functions (analysis specific to experiment)

    if 1

        epoch = 4;
        bout = 2;

        idaq = fieldmatch(daq, lev=1);
        [~, ~, ipe, ~, tpe] = trmake(daq.(idaq).epochts, padlent=3, t=glb('t'), eb=[epoch bout]);

        a_ebgano(stack, roi, daq, bmp, glb('t'), md.sper, ...
            mix={'gar', 'eb', 'gal'}, ...
            noside={'r'}, ...
            pltstr={'profile'}, ...
            facealpha=1, ...
            szthrres=[], ...
            szmin=15, ...
            szmaxfac=70, ...
            nothr='', ...
            colsep=0, ...
            xyrng=[], ...
            epoch={1:6}, ...{[1], [2], [3], [4], [5], [6]}, ...
            lagsampxy=-1, ...
            lagsampz=0, ...
            yconst=1, ...
            slopelensec=0.35, ...
            slopeord=3, ...
            widyxz=md.widyxz, ...
            vt=tpe, ... 
            dozscore=1, ...
            stackrot=[-90,0,0], ...
            stackslice=[])

    end

end


