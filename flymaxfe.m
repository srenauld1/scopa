function [stim, stimgrid] = flymaxfe(pthstack, opt, opt2)

%just mat files right now, will include binaries soon and be renamed load_flymax_movie

arguments

    pthstack {mustBeTextScalar} = '' %path to stack; if empty, user prompted to choose file
    
    opt.stimtype = 'drone';
    opt.id = 'CON_51';
    opt.crop_edges = 1;
    opt.rep = 1;
    opt.flipped = 0;
    opt.feat2 = [];
    
    opt2.pthpar = [];
    opt2.pthtemplate = [];
    opt2.getgrid = 1; %get the feature on a grid (phi theta if vistype is sphere, xy if gridtype is plane)
    opt2.vistype = 'plane'; %sphere, plane, or raw
    opt2.it = -100;
    opt2.gridres = 256;
    opt2.downsample_template = 1; %downsamples template, then uses it, rather than using template then downsampling; fine for most cases, just looks a little rougher
    opt2.pthgif = []
    opt2.doplt (1,1) {mustBeBinary} = 0 % 1 to make plots
    opt2.och (1,1) {mustBeBinary} = 0 %och means "options check"; 1 to exit function and return nothing but arguments block struct opt (not opt2 or any other name-value arguments struct); 0 to skip och (run function normally), which is default

end

if opt2.och
    if isfield(opt, 'optid')
        opt = rmfield(opt, 'optid');
    end
    stim = opt;
    return
end

stimtype = opt.stimtype;
featid = opt.id;
pthpar_feat = opt.pthpar;
pth_template = opt.pthtemplate;
rep = opt.rep;
feat2 = opt.feat2;
getgrid = opt.getgrid;%get the feature on a grid (phi theta if vistype is sphere, xy if gridtype is plane)
vistype = opt.vistype;%sphere, plane, or raw 
it = opt.it;
gridres = opt.gridres;
flipped = opt.flipped;
downsample_template = opt.downsample_template; %downsamples template, then uses it, rather than using template then downsampling; fine for most cases, just looks a little rougher
crop_edges = opt.crop_edges;

if strcmp(vistype, 'raw') && getgrid
    error("to get grid, vistype cannot be raw; this is not a grid for flymax features (it is hex values)")
end

if isempty(doplt)
    doplt = any(strcmp('featid', glb('plt')));
end
gifsuffix = [vistype '_.gif'];
if isempty(pthgif)
    pthgif = pthauto(suffix=gifsuffix, usetime=1, usefun=1);
end

id = idmake(pthstack);
recdate = id.recdate;
fly = id.fly;
trial = id.trial;
fldr = [num2str(recdate) num2str(fly) ',*'];

spl = strsplit(featid, '_');
stimfeat_type = spl{1};
stimfeat_num = spl{2};


fnpat = [stimtype '_' num2str(trial) '_' num2str(rep) '_' featid '_*_*_.mat'];
pthpat = [pthpar_feat filesep fldr filesep fnpat];

pthall = rdir(pthpat);
pthall = natsortfiles(pthall);

suffix_grid = ['grid_' vistype '_'];

for fi = 1:length(pthall)

    if ~contains(pthall(fi).name, suffix_grid) %first load the feature; load or make the gridded feature next
        pth_stimfeat = pthall(fi).name;
        [pthtmp, fntmp, exttmp] = fileparts(pth_stimfeat);
        stim = struct2cell(load(pth_stimfeat, 'stimulus'));
        stim = stim{1};
        if ~isa(stim, 'single')
            stim = single(stim);
        end
    end


    if doplt || getgrid

        pth_stimgrid = insertBefore(pth_stimfeat, '.mat', suffix_grid);
        if isfile(pth_stimgrid)
            stimgrid = struct2cell(load(pth_stimgrid, 'stimgrid'));
            stimgrid = stimgrid{1};
        else
            fprintf("stimgrid file '" + pth_stimgrid + "' does not exist; making stimgrid now" + newline)
            stimgrid = hex2grid(stim,...
                vistype = vistype,...
                it = it,...
                gridres = gridres,...
                flipped = flipped,...
                pthgif = pthgif,...
                downsample_template = downsample_template, ...
                crop_edges = crop_edges,...
                pth_template = pth_template, ...
                cmap = 'rb', ...
                doplt = doplt);
            save(pth_stimgrid, 'stimgrid', '-v7.3', '-mat')
        end

    end


    if ~isempty(feat2)
        fntmp = strrep(fntmp, featid, feat2);
        pth_stim2 = [pthtmp filesep fntmp exttmp];
        load(pth_stim2, 'stim')
        stim2 = struct2cell(load(pth_stim2, 'stimulus'));
        stim2 = stim2{1};
        if ~isa(stim2, 'single')
            stim2 = single(stim2);
        end
    end



end



