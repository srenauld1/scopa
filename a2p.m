

%{

see docs_a2p

%}

function a2p(spec, opt)

arguments
    spec = [] % optional input; struct of stack specifiers (see function 'stackfind'), or char or cell of char specifying full path(s) to stack(s); wildcards * are allowed; if empty, recording(s) searched for in oset>stackfind using stack specifiers set in oset (in struct spec)
    opt.usegit (1,1) {mustBeBinary} = 0 % optional input; 0 or 1; 1 to use git to sync with scopa remote repository to ensure opt files (and consequently, optid and varid) are integrated across filesystems; 0 to skip git
    opt.dopltx (1,1) {mustBeBinary} = 0 % 1 to run pltx
end
usegit = opt.usegit;
dopltx = opt.dopltx;

close all; clc; clear glb vget; clearvars -except spec usegit dopltx;


%%%% GLOBALS %%%%

glb(usegit=usegit); %set usegit in globals function 'glb'
glbfile('dmstackdf'); %confirm this exists in locked globals file glb.txt; default stack dimension order; if you use stackld to load the stack from tif (and save as mat), the stack is put into this order; c is stack collection channel (eg stack collected with 2 pmts makes 2 channels), k is truecolor stack's rgb channel (in general, stack is grayscale, not truecolor, so this is typically singleton), ...
glbfile('optiddf'); % confirm this exists in locked globals file glb.txt; default option id; if user doesn't use oid to map options sets to optid, optiddf is used instead (in filenames, figures, and struct names)


%%%% OPTIONS %%%%

oa = oset(spec); % set options; oa stands for "o all" (ie options for all recordings)

for k = 1:numel(oa) % loop over recordings found in oset

    o = oa(k); %index into options for one recording


    %%%% STACK %%%%

    if ~isempty(o.sld)
        for m = 1:numel(o.sld)
            prs = struct2pairs(o.sld(m));
            s(m) = stackld(o.id.pthstack, prs{:}, doplt=0); %load/process stack (metadata also gets loaded in stackld)
        end
    end

    o.id.pthstack = s(m).pth; oa(k).id.pthstack = s(m).pth; %update with .mat extension, in case pthstack was tif going in to stackld
    glb(1, pthsvdir=o.id.pthstackfld); %update global that refers to stack location, a default location for saving some less important files (like figures)


    %%%% DAQ %%%%

    if ~isempty(o.dq)
        for m = 1:numel(o.dq)
            prs = struct2pairs(o.dq(m));
            dq(m) = dqmake(o.id.pthdaq, prs{:}, doplt=0); %load/process dq (also fictrac video)
        end
    end

    
    %%%% ROIS %%%%

    if ~isempty(o.roi)
        for m = 1:numel(o.roi)
            prs = struct2pairs(o.roi(m));
            roi(m) = roimake(s, prs{:}, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% BUMP %%%%

    if ~isempty(o.bmp)
        for m = 1:numel(o.bmp)
            prs = struct2pairs(o.bmp(m));
            bmp(m,:) = bmpmake('', prs{:}, srate=s.md.volrate, epochts=dq.epochts, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% FLYMAX %%%%

    if ~isempty(o.fmf)
        for m = 1:numel(o.fmf)
            prs = struct2pairs(o.fmf(m));
            fmf(m) = flymaxfe('', prs{:}, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% MODELS %%%%

    if ~isempty(o.mdl)
        for m = 1:numel(o.mdl)
            prs = struct2pairs(o.mdl(m));
            mdl(m) = mdlmake('', prs{:}, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% PLOTS %%%%

    if dopltx
        pltx(o.pltx, stack=stack, dq=dq, roi=roi, bmp=[], mdl=mdl, fmf=fmf, t=glb('t'), stimvid=fmfvid)
    end


    %%%% a_* FUNCTIONS (EXPERIMENT-SPECIFIC ANALYSIS) %%%%

    if 0

        epoch = 1;
        bout = 8;

        % idaq = fieldmatch(dq, lev=1);
        idaq = 1;
        [~, ~, ipe, ~, tpe] = trmake(dq(idaq).epochts, padlent=3, t=dq(idaq).t, eb=[epoch bout]);

        if contains(o.id.pthstack, {'ebgano'})

            a_ebgano(s, roi, dq, bmp, dq(idaq).t, ...
                mix=[], ...{'gar', 'eb', 'gal'}, ...
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
                dvlensec=0.35, ...
                dvord=3, ...
                vt=tpe, ...
                dozscore=1, ...
                stackrot=[0,0,0], ...
                stackslice=[])

        elseif contains(idtmp(k).pthstack, {'opto'})
            
            a_opto(roi, s, glb('t') )

        end


    end

end


