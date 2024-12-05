function [o, oflat] = oset(recin)

% EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
% edit docs_oset.m

arguments
    recin = [] %recin can be empty, or not passed as argument, and will search for file using fspc* below; recin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, pass recin as 'nofile'
end

if strcmp(recin, 'nofile') %if the only input to oset is 'nofile', will do everything but skip searching for files (and skip setting globals)
    dofindfiles = 0;
else
    dofindfiles = 1;
end

%%%% user-defined recording specifiers (if no input to a2p) %%%%

o.spec.pthparent_local = '~/stacks';
o.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(recin) %if you're running a2p without input arguments (ie if recin is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not recin is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    o.spec.recdate = {'22*'}; %cell array of char (or scalar char), can use wildcards
    o.spec.fly = {'*'}; %cell array of char (or scalar char), can use wildcards
    o.spec.trial = {'1'}; %cell array of char (or scalar char), can use wildcards
    o.spec.suffix = {'cmrg_dcdn'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in suffixvalid
    o.spec.match = 'each'; %'any' or 'each'; 'sany' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
    o.spec.pth = '';
elseif iscell(recin) || ischar(recin) %if input to a2p is not empty, and is not struct
    if strcmp(recin, 'nofile') %if input to oset is just 'nofile', skip file search part (but set all options otherwise); 'nofile' is not a valid input to a2p, but is a valid input to oset (so the user can query all options from anywhere in a2p without having to redefine found files, which can be slow and also confounding
        o.spec.pth = '';
    else % if input to a2p is char or cell of file paths with optional wildcards, find files matching those paths
        o.spec.pth = recin;
    end
end

%%%% dos %%%%

o.mn.dodaq = 1; %process daq timeseries?
o.mn.doftv = 0; %process fictrac video?
o.mn.doroi = 1; %make/load/process rois?
o.mn.dobmp = 1; %compute bump?
o.mn.dofit = 0; %fit model?
o.mn.dopltx = 0; %enter pltx for summary interactive plots?
o.mn.plt = [""]; %string array of subroutines that get plots; default is all of them, ["daq", "sld", "ftv", "roi", "bmp", "mf", "hires"], so keep this commented if you want all plots; if you want none, do empty string array [""]
o.mn.pltvis = 1; %1 shows requested plots (o.mn.plt) and saves them, 0 saves but does not show them
regionex = {'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any regionex you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mfit) or interactive plots (pltx); if regionex is not 'none', regionex can be, but do not have to be cuboid subregions of fov; regionex can but do not have to be unique regions of fov, although the user is prompted with that option;

%%%% some simple option specification %%%%

o.daq.useinds = 'none'; %how to resample daq timeseries
o.daq.use_carls_epochs = 1;

o.sld.chanuse = [1 2]; %which channel to use in stack denoted by o.spec.suffix, (also applied to any stacks listed in o.sld.suffixplt)
o.sld.suffixplt = ["cmrg_dcdn"]; %comment this out to plot/convert all available stacks; or list suffixes to plot as string array, or [""] to skip; string array of suffixes denoting which stacks to plot in gif (in stackld) for comparison (can be 1 or 2 channel); default is all stacks that exist, all channels; ignored if o.mn.plt does not contain "sld", or if o.sld.suffixplt is empty; the stack specified in o.spec.suffix gets converted from tif to mat and saved, and so do the stacks listed here in o.sld.suffixplt; any stack not listed in o.spec.suffix or o.sld.suffixplt will not get converted from tif to mat (so if you always want all stacks converted and plotted, just use default suffixplt by leaving this commented out)
o.sld.clip = 0; %[lower upper] quantiles, or -1 to clip negatives
o.sld.smlenpx = [0, 0, 0];

o.sld.sp.dr = {[0,1]}; %display range for stacks listed in o.sld.suffixplt; one vector for all, or can do one for each o.sld.suffixplt; if you have more vectors than suffixplt, will take first numel(suffixplt)
o.sld.sp.it = [1:100]; % t indices for gif of stack(s) o.sld.suffixplt; see indsmake for nonstandard syntax options
o.sld.sp.iz = []; %z indices for gif of stack(s) (o.sld.suffixplt); see indsmake for nonstandard syntax options

o.ftv.smlenpx = 2;

%%%% compute bump %%%%

o.bmp.domaintype = 'functional';
o.bmp.mf.tg.domain = 'roi';  %interactive plots using all variables matching this string as timeseries two
o.bmp.mf.tg.optused = [];  %interactive plots using all variables matching this string as timeseries two
o.bmp.mf.tg.name = [];  %interactive plots using all variables matching this string as timeseries two
o.bmp.mf.tg.group = 'name';  %interactive plots using all variables matching this string as timeseries two

%%%% fit model %%%%

o.mf.mdlname = 'fnet_A01_s'; %see docs_mdlname for how to use

%set indv
o.mf.tg.domain = 'daq';  %domain within ts
o.mf.tg.optused = [];  %empty for all
o.mf.tg.name = {'vf', 'vy'}; %variable name within domain; cell to expand
o.mf.tg.group = [];
o=odf(o, 'mf.tg', 'indv'); %put in copybin 'indv'

% to set depv, make a struct with opts from o.roi; output will be roi created with those options; anything not listed takes default (in odf); anything nonexisting causes error
roitmp.mm.chan = [2];
roitmp.ma.numroi = {256, 512}; %cell to expand

o.mf.tg.domain = 'roi';  %interactive plots using all variables matching this string as timeseries two
o.mf.tg.optused = roitmp;  %interactive plots using all variables matching this string as timeseries two
o.mf.tg.name = [];  %empty for all
o.mf.tg.group = [];
o=odf(o, 'mf.tg', 'depv'); %put in copybin 'depv'



%%%% pltx (interactive plots) %%%%

o.pltx.tg.domain = 'roi';  %interactive plots using all variables matching this string as timeseries two
o.pltx.tg.optused = [];  %interactive plots using all variables matching this string as timeseries two
o.pltx.tg.name = [];  %interactive plots using all variables matching this string as timeseries two
o.pltx.tg.group = 'name';  %interactive plots using all variables matching this string as timeseries two
o.pltx.lagsxy_sec = [0, 0, 1, 0]; %lags for interactive scatterplot; vector, or if you want all within range, bookend with zeros ([0 1 2 0] is range 1-2)
o.pltx.lagsz_sec = [0, 0, 1, 0]; %lags for interactive scatterplot; vector, or if you want all within range, bookend with zeros ([0 1 2 0] is range 1-2)

%%%% set more options and find files %%%%

o = odf(o, files=dofindfiles); %set all above options and find files (unless oset input recin is 'nofile')


%%%% create distinct options (or not) for different found recordings, and different regionex %%%%

for k = 1:numel(o)
    for m = 1:numel(regionex) %create different copybin within o.roi for each regionex, to analyze them differently

            o(k).roi.regionex = regionex{m};

            o(k).roi.domm = 1; %do draw rois
            o(k).roi.doma = 1; %do automated morph rois
            o(k).roi.docm = 0; %do caiman extraction
            o(k).roi.doqc = 0; %do quality control on rois

            o(k).roi.mm.chan = [1];

            o(k).roi.ma.chan = [1];
            o(k).roi.ma.numroi = 512; %for auto morph roi extraction (after optional mask draw)
            o(k).roi.ma.maskseg = 'uniform';
            o(k).roi.ma.do3d = 1;

            o(k).roi.nrm.wavp = []; %[0 50]; wavelet cwt periods to keep; seconds; carl uses [0 50] often to remove slow fluctuations; empty to skip
            o(k).roi.nrm.degdtr = [2];
            o(k).roi.nrm.post = {'f'}; %how to normalize roi responses; 'f' is raw, 'dff010020' is dff with f as 10th percentile over 20-sec sliding window

            if contains(o(k).id.pthstack, '2024112')
                o(k).roi.nrm.post = {'rsc000100'}; 
                if any(strcmp(regionex{m}, {'eb'}))
                    o(k).roi.domm = 0; 
                    o(k).roi.ma.numroi = 64; 
                    o(k).roi.ma.maskmake = 'edge'; 
                    o(k).bmp.mf.mdlname = 'fnet_v'; 
                    o(k).bmp.mf.mdl_length_sec = 0;
                    o(k).bmp.mf.epochinds = 4;
                    o(k).bmp.mf.normalize_indv = 'none';
                    % o(k).bmp.mf.opl.MaxFunctionEvaluations = Inf; %3000;
                    % o(k).bmp.mf.opl.MaxIterations = 5000; %1000

                elseif any(strcmp(regionex{m}, {'no', 'ga'}))
                    o(k).roi.doma = 0;
                    o(k).roi.mm.maskname = {'left', 'right'}; 
                end
            elseif contains(o(k).id.pthstack, '2211')
                if any(strcmp(regionex{m}, {'tm', 't5'}))
                    o(k).mn.oldcarl = 1;
                    o(k).mn.dodaq = 0; 
                    o(k).mn.doftv = 0; 
                    o(k).mn.dobmp = 0; 
                    o(k).mn.dofit = 0; 
                    o(k).mn.dopltx = 1; 
                    o(k).roi.doma = 0;
                    o(k).sld.tcrop = [4, 2]; 
                    o(k).mf.mdl_lag_sec = 1; 
                    o(k).mf.mdl_length_sec = 1.25;
                    o(k).carl.stimtype = 'drone';
                    o(k).carl.feat = 'CON_51';
                end
            end

            o(k) = odf(o(k), {'roi'}, regionex{m}, files=2); %use files=2 to keep id field untouched (keep found files)

    end

end


%%%% organize %%%%

o = odf(o, fill=1); %final call to odf with fill=1 will fill any missing option nestings, but otherwise change nothing

o = structsort(o, vectype='row'); %recursively order alphabetically

o = opt2id(o, 'roi');

oflat = structflat(o, prefix='o'); %get flattened struct for user to see options struct organization more easily (oflat does not get used); need prefix to make valid fieldnames in case nonscalar

end













