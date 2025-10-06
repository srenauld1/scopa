function pltx(opt, opt2)


% "TODO: SCATTER, POPULATION FEATURE, FT PATH, HEATMAP, MODEL"
% "TODO: MENU, FULL roidraw, MERGE ALL A2P PLOTTING (MODULAR SUBPLOTS FOR SPECIALIZATION)"

% scatterplot
%   scatterplot of 2 or 3 timeseries the lag with the greatest correlation coefficient
%   scinds are indices of plot variables to use for scatterplot (since there can be more plot variables);
%   scinds can be 2 (x-y scatterplot) or 3 elements (x-y-color scatterplot)
%   inset bar plot shows correlation coefficient at all requested lags
%   markers are dimmed according to distance from current sample/gif frame; dimming is gaussian
%   scdimmin is min marker intensity, ie min of gaussian multiplier; if scalpha_min=1, there is no dimming
%   scdimsd is std of gaussian multiplier, in seconds
%   if mark_epochs=1, marker type is mapped to epoch (ie epoch 1 gets period markers, epoch 2 gets star markers, etc)

%vpmap maps vars to plot positions
%cols assign color to each plot position
%user input sets vpmap to default (unless input is change to vpmap)
%if a var doens't exist at a plot position, nothing is plotted there, but the plot positions of other variables do not change
% currently, stack must not be subset in x,y, or z, otherwise interactive roi indices will be wrong


arguments
    opt = []
    opt2.stack = []
    opt2.daq = []
    opt2.roi = []
    opt2.bmp = []
    opt2.mdl = []
    opt2.fmf = []
    opt2.vars = []
    opt2.labs = []
    opt2.roidat = []
    opt2.pthstack = []
    opt2.md = []
    opt2.sper = []
    opt2.widyxz = [] 
    opt2.t = [] 
    opt2.zstartpos = [] 
    opt2.epochts = []
    opt2.pthpre = []
    opt2.pth_roim_interactive = []
    opt2.normopt = []
    opt2.ftvid = []
    opt2.stimvid = []
    opt2.doplt = []
end
opt2 = glboropt(opt2);
stack = opt2.stack;
daq = opt2.daq;
roi = opt2.roi;
bmp = opt2.bmp;
mdl = opt2.mdl;
fmf = opt2.fmf;
vars = opt2.vars;
labs = opt2.labs;
roidat = opt2.roidat;
pthstack = opt2.pthstack;
md = opt2.md;
sper = opt2.sper;
widyxz = opt2.widyxz;
t = opt2.t;
zstartpos = opt2.zstartpos;
epochts = opt2.epochts;
pthpre = opt2.pthpre;
pth_roim_interactive = opt2.pth_roim_interactive;
normopt = opt2.normopt;
stimvid = opt2.stimvid;
ftvid = opt2.ftvid;
doplt = opt2.doplt;

[opt, doplt, pthstack] = fset('pltx', opt, doplt, pthstack);

vpmapl = opt.vpmapl;
vpmapr = opt.vpmapr;
lagsxy_sec = opt.lagsxy_sec;
lagsz_sec = opt.lagsz_sec;
lags_to_plot = opt.lags_to_plot;
plot_z_as_color = opt.plot_z_as_color;
epochnum = opt.epochnum;
iz = opt.iz;
it = opt.it;
dr = opt.dr;
doui = opt.doui;


if isempty(md)
    md = mdsild(pthstack);
end
if isempty(sper)
    sper = md.sper;
end
if isempty(widyxz)
    widyxz = md.widyxz;
end
if isempty(t)
    t = md.sper:md.sper:md.numvol*md.sper;
end
if isempty(pth_roim_interactive)
    pth_roim_interactive = [erase(pthstack, '.mat') 'int_roi_.mat'];
end
if ndims(stack)<4
    error("stack must be 4d or 5d")
end
if ~iscell(epochnum)
    epochnum = {epochnum};
end


drvid = dr;
dool = 1; %do overlay hard coded for now
gif_scope = 'allv_eache'; %'eachv_eache'; %eachv_eache or allv_eache or allv_alle (currently can't do eachv_alle, but will soon); change filename (or not) according to epoch and variable changes
ts_scope = 'full'; %how much of total possible timseries to show in long timescale plot on top
yaxisroomfac = 0.15; %fraction of total, extra room on y axis
ylim_constancy = 'all';  %'all', 'each', or '' (empty); 'all' means y axis will be constant across all variables for a single fieldname in 'vars', each means it will be adjusted for each change in variable for each fieldname in 'vars'
lrscale = 'equal'; %whether left and right have relative scaling
sampinc = 40; %sample increment per gif frame; sampinc~=1 will include lower bound, but not necessarily upper, since sample=lower:sampinc:upper"
roialpha = 0.2; %transparency in roi overlay
dors = 1; %leave this as 1 to plot all timeseries on same scale (but keep tick labels at original scale)
skipnan_rescale = 0; %making 0 makes missing channel nan, which is good i think . . . previously thought leave this as 1, skip nanes when rescaling to plot timeseries on same axis
newroirad = 10;%3*widyxz(1); %radius (microns) for user input rois
numfr_gif_max = 2000; %throw error if there will be more
timedim = 2;

scinds = [1 5]; %indices of plot variables
scdimmin = 0; %min
scdimsd = 4; %seconds
lag_style = 'each'; %currently 'each' is only option; lags xy, then z for each xy; lag_style 'any' (soon available) will allow all combinations
threshold_data = 0;
blindspot = -pi/12; %nan to not draw blind spot
pval_siglev = 0.05; %pval bar gets colored if below pval_siglev
mkrsz = 4; %scatter marker size
bar_contrast = 0.3; %to make difference between non-significant (white) and barely significant (0.05) clear in blue saturation

if plot_z_as_color==0
    error("plot_z_as_color must be 1 for now")
end
if ~ismember(numel(scinds), [0 2 3])
    error("scinds must be length 0, 2, or 3")
end

clear pltexp_scat_prepvars %clear persistent variable within

%% arrange figure, choose colors

layout = {[4,4], stack(:,:,:,:,1)};
marginax = [0.005];
marginfg = [0.05];
splitfrac = 0.55;
ax = axarr(layout, marginax=marginax, marginfg=marginfg, splitfrac=splitfrac, splitdim='y', stackjust='min');

maxnumvars = 8;%numel(fieldnames(vars));
cols = brewermap(maxnumvars,'Dark2'); %distinguishable_colors(numel(fieldnames(vars)));
cols(1,:) = cols(4,:);

if any(ismember(cols, [0 0 0], 'rows'))
    error("cannot use black for plotting until there is code to prevent it from being assigned to rois (since black roi overlay will cause error")
end


%% prep vars

[iz, izstr] = vecsub(iz, superset=1:size(stack, 3), labprefix='z: ');
[it, itstr] = vecsub(it, superset=1:size(stack, 4), labprefix='t: ');

% stack = stack(:,:,iz,it,:);
kpepidx = setdiff(1:numel(epochts), it);
epochts(kpepidx) = 0;

vid = [];
vidrot = 0;
if ~isempty(stimvid)
    vid = stimvid;
    vidrot = -90;
    stimvid = [];
elseif ~isempty(ftvid)
    vid = ftvid;
    ftvid = [];
end

if ~isempty(vid)
    if ndims(vid)==2
        vid = reshape(vid, size(vid,1), 1, 1, size(vid,2)); %insert singleton 3rd dim, make time 4th dim, to match imaging stack and use same plotting code
    elseif ndims(vid)==3
        vid = reshape(vid, size(vid,1), size(vid,2), 1, size(vid,3)); %insert singleton 3rd dim, make time 4th dim, to match imaging stack and use same plotting code
    end
else
    vid = rand(10,10,size(stack, 4));
end

if size(vid, ndims(vid))~=size(stack, ndims(stack))
    error("stack and vid do not have the same number of frames")
end

fn = fieldnames(roi);
for k = 1:numel(fn)
    var{k} = roi.(fn{k}).dat.ts;

end

vars = struct2cell(vars);
labs = struct2cell(labs);

[varsz, numts, numsamp] = get_vars_size(vars, timedim);

vars(cellfun(@isempty, vars)) = {nan(1,numsamp,'single')}; %make empty timeseries nan for now
labs(cellfun(@isempty, labs)) = {{''}}; %make empty labels 'novar' for now

for j = 1:numel(vars)
    vars{j} = convert_to_single_precision(vars{j});
    labs{j} = check_labels(labs{j}, vars{j});
    lims{j} = axlim(vars{j}, roomfac=yaxisroomfac);
end

[vpmapflat, varaxside] = translate_vpmap(vpmap);
vars = vars(vpmapflat);
labs = labs(vpmapflat);
lims = lims(vpmapflat);

varcombos = combomake(vars);

[epochstring_all, tinds_all, numsamp_tslong_all_gifs] = apply_epochinds(epochts, t, epochnum, sampinc, ts_scope, gif_scope);

numfr_gif = check_gif_frame_number(gif_scope, tinds_all, varcombos, numfr_gif_max);


[actual_lags_xy_sec, actual_lags_z_sec, lagsall_xy, lagsall_z, zero_lag_index, numlags] = pltexp_compute_lags(t, lagsxy_sec, lagsz_sec, lag_style); %actual lags depend on epoch (samples you're using)


%% loop over epoch sets and plotting variables

revert_vars = 0; %revert to input variables after user input changes
timestr_ui = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')); %insert timestring when interactive to record each change in user input
newroicen_all = cell(numts, 1);
cb = struct;
plotloop = 1;
while plotloop %loop is turned off if no user input

    if ~all(structfun(@isempty, cb)) && ~revert_vars
        framecount = 0;
        [vars_use, labs_use, lims_use, roipixind_use, varcombos_use] = pltexp_cbapply(cb, vars_use, labs_use, roipixind_use, stack, t, sper, pth_roim_interactive, normopt, newroirad, newroicen_all, widyxz, yaxisroomfac, numsamp);
        timestr_use = timestr_ui;
    else
        vars_use = vars;
        labs_use = labs;
        lims_use = lims;
        roipixind_use = roidat.roipx;
        varcombos_use = varcombos;
        timestr_use = '';
    end

    [varsz, ~, ~] = get_vars_size(vars_use, timedim);


    for ecnt = 1:numel(epochnum) %loop over all epoch sets (sets of samples within trial defining stimulus state)

        numsamp_tslong_this_gif = numsamp_tslong_all_gifs(ecnt);
        tinds = tinds_all{ecnt};
        epochstring = epochstring_all{ecnt};

        for vcount = 1:size(varcombos_use,1) %loop over all variable sets

            [varsp, labsp] = apply_varcombo(vars_use, labs_use, varcombos_use, vcount, numsamp_tslong_this_gif);

            skipplot = skip_plot_criteria(labsp, 'none');

            if skipplot

                sprintf("skipping plot with these labels: " + cell2mat(labsp))

            else

                %%%% PREP VARS %%%%

                tlabsp = cellfun(@(x) x.(ylim_constancy), lims_use, 'UniformOutput', false);
                polarinds = find_polar_inds(labsp);
                varsp(polarinds,:,:) = polarnan(varsp(polarinds,:,:)); %FIX FOR CHANNEL
                varsp = nanpadvar(varsp, numsamp_tslong_this_gif);
                yaxis_true_lims = find_yaxis_true_lims(lrscale, lims_use);
                varsp = rescale2(varsp, tlabsp, yaxis_true_lims, skipnan_rescale);

                pthgif = make_filename(labsp, gif_scope, epochstring, pthpre, timestr_use); %gif_scope determines whether pthgif gets updated
                [roiindp, roi_index_str] = find_roi_index(labsp);
                figure_title = make_figure_title(pthpre, epochstring, sper, roi_index_str);
                labsp = process_labels(labsp, roiindp);

                roipixindp = cell(numel(roiindp),1);
                roipixindp(~cellfun(@isempty, roiindp)) = roipixind_use([roiindp{:}]);

                varaxside_use = flag_empty_timeseries(varsp, varaxside, timedim);

                "WARNING HARD CODING CHANNEL 1 FOR PREPVARS SCAT"
                [init_scatter, sctype, varsp_sc, labsp_sc, cols_sc, rdummies, cmp_sc, ccr, pval_norm, laginds_to_plot] = ...
                    pltexp_scat_prepvars(scinds, numlags, lagsall_xy, lagsall_z, varsp(:,:,1), labsp, cols, threshold_data, varaxside_use, ...
                    plot_z_as_color, polarinds, numsamp_tslong_this_gif, zero_lag_index, lags_to_plot, pval_siglev, bar_contrast);

                if size(stack, 5)==2
                    dmt = size(stack);
                    stackp = chanfuseim(vec(stack(:,:,:,:,1)), vec(stack(:,:,:,:,2)));
                    stackp = reshape(stackp, [dmt(1:end-1) 3]);
                else
                    stackp = [];
                end


                %%%% INIT AXES %%%%
                if strcmp(gif_scope, 'eachv_eache') || (strcmp(gif_scope, 'allv_eache') && vcount == 1) || (strcmp(gif_scope, 'allv_alle') && ecnt == 1 && vcount == 1)

                    close all
                    h = struct;
                    framecount = 0;


                    h = fg(h=h, doui=doui, gifvis=gifvis, szf=1);


                    idxsect = 2;
                    cmap = gray(256);
                    h = axim(stack, h=h, ax=ax, stackp=stackp, doui=doui, dool=dool, cmap=cmap, txtvar=zstartpos, dr=drvid, idxsect=idxsect);


                    idxsect = 1;
                    idxsubp = [5 13];
                    widfac = [4 1];
                    htfac = [2 2];
                    h.ts = axts(h.fg, ax, doui, numsamp_tslong_this_gif, varaxside_use, t, lims_use, tlabsp, labsp, cols, idxsect, idxsubp, widfac, htfac, dors);


                    idxsect = 1;
                    idxsubp = 15; %idxsubp=16 with widfac>1 forces image into margins, but it looks fine that way and gives more room for other plots
                    widfac = 2;
                    htfac = 2;
                    cmap = gray(256);
                    drvid = [0 1];
                    douivid = 1;
                    doolvid = 1;
                    h.vid = axim(h.fg, vid, ax=ax, doui=douivid, dool=doolvid, cmap=cmap, dr=drvid, idxsect=idxsect, idxsubp=idxsubp, widfac=widfac, htfac=htfac);


                end

                if strcmp(gif_scope, 'eachv_eache') || (strcmp(gif_scope, 'allv_eache') && vcount == 1) || (strcmp(gif_scope, 'allv_alle') && ecnt == 1 && vcount == 1) || init_scatter %scatterplot also needs to be initialized if it's changed sctype (other plots aren't like this)
                    idxsect = 1;
                    idxsubp = 14;
                    widfac = 1;
                    htfac = 1;
                    h.sc = axsc(h.fg, ax, doui, sctype, mkrsz, blindspot, numsamp_tslong_this_gif, numlags, actual_lags_xy_sec, plot_z_as_color, labsp, cols, idxsect, idxsubp, widfac, htfac);
                end


                %%%% PLOT AXES %%%%
                [h, framecount, cb] = axplt(h, stack, stackp, vid, ...
                    framecount, varsp, varaxside_use, t, tinds, cols, ...
                    roialpha, roipixindp, pthgif, figure_title, varsz, doui, ...
                    timestr_ui, sampinc, varsp_sc, labsp_sc, rdummies, cmp_sc, ...
                    ccr, pval_norm, laginds_to_plot, cols_sc, scdimmin, scdimsd, vidrot);

                if cb.restart.v==1
                    plotloop = 1;
                    break;
                else
                    plotloop = 0;
                end

            end
        end
    end
end


end



%% helper functions



function varsin = convert_to_single_precision(varsin)

if ~isa(varsin, 'single') & ~isa(varsin, 'double')
    error("variable is neither single nor double; not strictly required, but make sure your variables are correct");
end
if isa(varsin, 'double')
    varsin = single(varsin);
end

end




function labs = check_labels(labs, vars)

if ~isempty(labs) && ~all(isnan(vars(:))) %if it's not an empty variable
    if numel(labs)~=size(vars, 1) %if label length doesn't match variable dim 1 size
        if numel(labs)==1
            labs = repmat(labs, size(vars, 1), 1);
            disp("repeating singleton lab for all vars")
        else
            error("lab must be empty, or length 1, or match var length")
        end
    end
end

end





function skipplot = skip_plot_criteria(labsp, noneflag)

if strcmp(noneflag, 'none') %don't apply criteria

    skipplot = 0;

else

    if ~any(endsWith(labsp, 'vel')) & ~any(endsWith(labsp, 'speed'))
        skipplot = 1;
    end

    if numel(unique(labsp(:)))~=numel(labsp(:)) %must not have duplicate vars
        skipplot = 1;
    end

    if any(strcmp(labsp, 'yawvel')) %must not have cuevel if skip_cuevel
        skipplot = 1;
    end

    if ((any(strcmp(labsp, 'respgal')) | any(strcmp(labsp, 'respgar'))) & any(strcmp(labsp, 'respgalrmean'))) | ... %must not have no and ga from "same side" (not connected)
            ((any(strcmp(labsp, 'respnol')) | any(strcmp(labsp, 'respnor'))) & any(strcmp(labsp, 'respnolrmean')))
        skipplot = 1;
    end

    if (any(endsWith(labsp, 'gar')) & any(endsWith(labsp, 'no_r'))) | ... %must not have no and ga from "same side" (not connected)
            (any(endsWith(labsp, 'gal')) & any(endsWith(labsp, 'no_l')))
        skipplot = 1;
    end

end

end


function epochstring_all = make_epoch_string(epochnum)

delim = 'e';
epochstring_all.short = regexprep( mat2str(epochnum), {'\[', '\]', '\s+'}, {'', '', delim});
[~, epochstring_all.parsed] = epochidget(epochstring_all.short);

end


function pthgif = make_filename(lab, gif_scope, epochstring, pthgif_prefix, timestr)


lab = strrep(strrep(lab, 'ts.', ''), '.', '-');

if strcmp(gif_scope, 'allv_alle') %one gif for all variables, all epochnum
    pthgif_suffix = {'gifscopeall'};
elseif strcmp(gif_scope, 'allv_eache') %different gif for each epochnum
    pthgif_suffix = {'gifscopeepoch', ['e' epochstring.short ]};
elseif strcmp(gif_scope, 'eachv_eache') %different gif for each variable set
    pthgif_suffix = {['v_' strjoin(lab, '_')]; ['e' epochstring.short ]};
    pthgif_suffix = {'eachv_eache'};
end

pthgif = [pthgif_prefix '_' strrep(strjoin(pthgif_suffix), ' ', '_') '_' timestr '_.gif' ];

end


function figure_title = make_figure_title(pthpre, epochstring, sper, roi_index_str)

stackidtmp = strsplit(pthpre, filesep);
stackid = stackidtmp{end};
sample_period_string = make_sample_period_string(sper);
figure_title = [strrep(stackid, '_', ' ') ',   ' epochstring.parsed  ',   ' sample_period_string ' SAMPLES,    ROI #' roi_index_str];
figure_title = upper(figure_title);

end


function lab = process_labels(lab, roiind)

for ri = 1:numel(roiind)
    if ~isempty(roiind{ri})
        lab(ri) = regexprep(lab(ri), 'resp.*.[ind\d+]?$', ['ROI #' num2str(roiind{ri}) ' (F)']);
    end
end

lab = strrep(lab, 'ts.', '');
lab = strrep(lab, '.', ' ');
lab = strrep(lab, '_', ' ');
lab = strrep(lab, 'vis', 'cue');


for j = 1:numel(lab)
    if contains(lab{j}, 'intfor') || contains(lab{j}, 'intside') || endsWith(lab{j}, 'yaw') || endsWith(lab{j}, 'ang')
        lab{j} = [lab{j} ' (RAD)'];
    end
    if contains(lab{j}, 'forvel') || contains(lab{j}, 'sidevel')
        lab{j} = [lab{j} ' (MM/S)'];
    end
    if contains(lab{j}, 'yawvel')
        lab{j} = [lab{j} ' (RAD/S)'];
    end
end

lab = upper(lab);

end


function sample_period_string = make_sample_period_string(sper)

sample_period_string = [num2str(sper*1000, 4) ' ms']; %'%.2g'

end



function numsamp_tslong_all_gifs = find_total_num_samp(ts_scope, gif_scope, t, tinds_full)

if strcmp(ts_scope, 'full')
    numsamp_tslong_all_gifs = numel(t); %show full timeseries
    numsamp_tslong_all_gifs = repelem(numsamp_tslong_all_gifs, numel(tinds_full));
elseif strcmp(ts_scope, 'epoch')
    if strcmp(gif_scope, 'allv_alle')
        numsamp_tslong_all_gifs = max(cellfun(@numel, tinds_full)); %show max of all epoch sets
        numsamp_tslong_all_gifs = repelem(numsamp_tslong_all_gifs, numel(tinds_full));
    else
        numsamp_tslong_all_gifs = cellfun(@numel, tinds_full); %show max of all epoch sets
    end
end

end


function [varsz, numts, numsamp] = get_vars_size(vars, timedim)

stmp = cellfun(@size, vars, 'UniformOutput', false);
dtmp = cellfun(@ndims, vars, 'UniformOutput', false);
maxsz = 3; %max(cell2mat(dtmp));
minsz = min(cell2mat(dtmp));
if minsz==2 %add channel size as third element for each var
    repidx = cell2mat(cellfun(@(x) x~=maxsz, dtmp, 'UniformOutput', false));
    stmp(repidx) = cellfun(@(x) cat(2,x,1), stmp(repidx), 'UniformOutput', false);
else
    error("source size mistmatch")
end

varsz = cell2mat(stmp);
numts = numel(vars);
numsamp = unique(varsz(:,timedim));

if numel(numsamp)~=1
    error("timeseries do not all have equal number samples; or there are no samples")
end

end


function [epochstring_all, tinds_all, numsamp_tslong_all_gifs] = apply_epochinds(epochts, t, epochnum, sampinc, ts_scope, gif_scope)

for j = 1:numel(epochnum) %loop over all epoch sets (sets of samples within trial defining stimulus state)
    if isempty(cell2mat(epochnum))
        if numel(epochnum)>1
            error("empty should be singleton")
        end
        epochstring_all{j}.short = 1;
        epochstring_all{j}.parsed = 'none';
        epochinds_pretend = 1;
        tinds_full{j} = find(ismember_each(epochts, epochinds_pretend));
        tinds_all{j} = tinds_full{j}(1):sampinc:tinds_full{j}(end);
    else
        epochstring_all{j} = make_epoch_string(epochnum{j});
        tinds_full{j} = find(ismember_each(epochts, epochnum{j}));
        tinds_all{j} = tinds_full{j}(1):sampinc:tinds_full{j}(end);
    end
end

numsamp_tslong_all_gifs = find_total_num_samp(ts_scope, gif_scope, t, tinds_full);

end

function [varstmp, labstmp] = apply_varcombo(vars_use, labs_use, varcombos_use, vcount, numsamp_tslong_all_gifs)
numchannels = max(cellfun(@(x) size(x,3), vars_use));
varcombo = varcombos_use(vcount,:);
varstmp = nan(numel(varcombo), numsamp_tslong_all_gifs, numchannels, 'single');
labstmp = cell(1, numel(varcombo));
for vi = 1:numel(varcombo)
    varstmp(vi,:,1:size(vars_use{vi},3)) = vars_use{vi}(varcombo(vi),:,:);
    labstmp(vi) = labs_use{vi}(varcombo(vi));
end
end


function varaxside = flag_empty_timeseries(vars, varaxside, timedim)
% varaxside(all(isnan(sum(vars,3,'omitmissing')),timedim)) = 0;
varaxside(all(isnan(vars(:,:,1)),timedim)) = 0; %do it this way (rather than varaxside(all(isnan(vars(:,:,1)),timedim)) ) so nans in one missing channel don't get flagged as a missing variable
end

function polarinds = find_polar_inds(labsp)
polarinds = (contains(labsp, 'yaw', 'IgnoreCase', true) | contains(labsp, 'ang', 'IgnoreCase', true)) & ~contains(labsp, 'vel', 'IgnoreCase', true);
end

function [vpmapflat, varaxside] = translate_vpmap(vpmap)

if any(~structfun(@isvector, vpmap))
    error("each field of vpmap must contain a vector")
end
vpmap = structfun(@(x) transpose(vec(x)), vpmap, 'UniformOutput', false); %make sure each is row vector

vpmapflat = vec(cell2mat(transpose(struct2cell(vpmap))));
if numel(vpmapflat)~=numel(unique(vpmapflat))
    error("vpmap cannot have repeated elements")
end

varaxside = zeros(numel(vpmapflat), 1);
fn = fieldnames(vpmap);
for j = 1:numel(vpmapflat)
    for k = 1:numel(fn)
        if ismember(vpmapflat(j), vpmap.(fn{k}))
            varaxside(j) = k;
        end
    end

end

end

function yaxis_true_lims = find_yaxis_true_lims(lrscale, lims)

if strcmp(lrscale, 'equal')
    yaxis_true_lims = [0 1];
else
    error("haven't written this yet; make right axis relative to left [0 1] depending on values of lims")
end

end

function numfr_gif = check_gif_frame_number(gif_scope, tinds_all, varcombos, numfr_gif_max)

num_extra_frames = 0;
numfr_gif = num_extra_frames;
epfr = cellfun(@numel, tinds_all);
numfr_gif = numfr_gif + epfr;
if contains(gif_scope, 'alle')
    numfr_gif = sum(numfr_gif);
end
if contains(gif_scope, 'allv')
    numfr_gif = numfr_gif .* size(varcombos, 1);
end

if any(numfr_gif>numfr_gif_max)
    error("there will be too many frames in gif; check your variables")
end

end



function result = chanfuseim(A, B)

scaling = 'independent';
channels = [2 1 2];

if size(A,3) > 1
    A = rgb2gray(A);
end
if size(B,3) > 1
    B = rgb2gray(B);
end
switch lower(scaling)
    case 'none'
    case 'joint'
        [A,B] = scaleTwoGrayscaleImages(A,B);
    case 'independent'
        A = scaleGrayscaleImage(A);
        B = scaleGrayscaleImage(B);
end

A = im2uint8(A);
B = im2uint8(B);

result = zeros([size(A,1) size(A,2) 3], class(A));
for p = 1:3
    if (channels(p) == 1)
        result(:,:,p) = A;
    elseif (channels(p) == 2)
        result(:,:,p) = B;
    end
end

end


function image_data = scaleGrayscaleImage(image_data)

if (islogical(image_data))
    return
end
% convert to floating point
image_data = single(image_data);
minData = min(image_data(:));
maxData = max(image_data(:));

if (minData == maxData)
    return
end

% Scale to range [0 1]
image_data = (image_data - minData)/(maxData - minData);

end % scaleGrayscaleImage



