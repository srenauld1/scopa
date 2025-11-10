

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
glbfile('dmstackdf'); %confirm this exists in locked globals file glb.txt; default stack dimension order; if you use smake to load the stack from tif (and save as mat), the stack is put into this order; c is stack collection channel (eg stack collected with 2 pmts makes 2 channels), k is truecolor stack's rgb channel (in general, stack is grayscale, not truecolor, so this is typically singleton), ...
glbfile('optiddf'); % confirm this exists in locked globals file glb.txt; default option id; if user doesn't use oid to map options sets to optid, optiddf is used instead (in filenames, figures, and struct names)


%%%% CREATE OPTIONS STRUCT otmp %%%%

otmp = oset(spec); % set options; oa stands for "o all" (ie options for all recordings)


%%%% CREATE STACK STRUCT s, UPDATE otmp (AS o) %%%%

o = [];
for k = 1:numel(otmp) % loop over recordings in otmp.pthstack (found in oset)

    if ~isempty(otmp(k).s) %if empty, found stack didn't enter oset_* file, so it will be skipped
        for m = 1:numel(otmp(k).s)
            prs = struct2pairs(otmp(k).s(m));
            [~, sopt, ~, spth] = smakew(otmp(k).pthstack, prs{:}, idx=m, doplt=0); %load/process stack (metadata also gets loaded in smake)
        end
        clen = numel(o);
        o = cat(2, o, repelem(otmp(k), numel(sopt)));
        for m = 1:numel(sopt)
            o(clen+m).pthstack = spth{m}; %update with .mat extension, in case pthstack was tif going in to smake
            o(clen+m).s = sopt(m);
        end
    end

end


%%%% LOOP OVER STACKS %%%%

for k = 1:numel(o) % loop over recordings found in oset

    s = load(o(k).pthstack); %load s
    glb(1, pthsvdir=s.id.pthstackfld); %update global that refers to stack folder, a default location for saving some less important files (like figures)


    %%%% DAQ %%%%

    if ~isempty(o(k).dq)
        for m = 1:numel(o(k).dq)
            prs = struct2pairs(o(k).dq(m));
            s = dqmakew(s, prs{:}, idx=m, mnum=numel(o(k).dq), doplt=0); %load/process dq (also fictrac video)
        end
    end


    %%%% ROIS %%%%

    if ~isempty(o(k).roi)
        for m = 1:numel(o(k).roi)
            prs = struct2pairs(o(k).roi(m));
            s = roimakew(s, prs{:}, idx=m, mnum=numel(o(k).roi), doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% BUMP %%%%

    if ~isempty(o(k).bmp)
        for m = 1:numel(o(k).bmp)
            prs = struct2pairs(o(k).bmp(m));
            s = bmpmakew(s, prs{:}, idx=m, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% FLYMAX %%%%

    if ~isempty(o(k).fmf)
        for m = 1:numel(o(k).fmf)
            prs = struct2pairs(o(k).fmf(m));
            fmf(m) = fmfmakew('', prs{:}, idx=m, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% MODELS %%%%

    if ~isempty(o(k).mdl)
        for m = 1:numel(o(k).mdl)
            prs = struct2pairs(o(k).mdl(m));
            s = mdlmakew(s, prs{:}, idx=m, doplt=0); %make (manual and/or automated and/or functional/caiman) rois in 2d or 3d, extract their responses, with normalization options
        end
    end


    %%%% PLOTS %%%%

    if dopltx
        pltx(o(k).pltx, stack=stack, dq=dq, roi=roi, bmp=[], mdl=mdl, fmf=fmf, t=glb('t'), stimvid=fmfvid)
    end


    %%%% a_* FUNCTIONS (EXPERIMENT-SPECIFIC ANALYSIS) %%%%

    if 0

        epoch = 1;
        bout = 8;

        % idaq = fieldmatch(dq, lev=1);
        idaq = 1;
        [~, ~, ipe, ~, tpe] = trmake(dq(idaq).epochts, padlent=3, t=dq(idaq).t, eb=[epoch bout]);

        if contains(o(k).pthstack, {'ebgano'})

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


