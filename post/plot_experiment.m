function plot_experiment(letui, stack, stack_mnt, vars, labs, vpmap, ...
    epochinds_all, roiinfo, ti, dtmni, zstartpos, epochinds_ts_i, gif_visibility, ...
    plotinds, display_range, fngif_prefix_short, fngif_prefix, ftv, ...
    pth_mroi_interactive, normopt, xwid, zwid)

"TODO: SCATTER, POPULATION FEATURE, FT PATH, HEATMAP, MODEL" 
"TODO: MENU, FULL DRAWROIS, MERGE ALL A2P PLOTTING (MODULAR SUBPLOTS FOR SPECIALIZATION)"

% scatterplot 
%   scatterplot of 2 or 3 timeseries the lag with the greatest correlation coefficient
%   scinds are indices of plot variables to use for scatterplot (since there can be more plot variables); 
%   scinds can be 2 (x-y scatterplot) or 3 elements (x-y-color scatterplot)
%   inset bar plot shows correlation coefficient at all requested lags 
%   markers are dimmed according to distance from current sample/gif frame; dimming is gaussian 
%   scalpha_min is min marker intensity, ie min of gaussian multiplier; if scalpha_min=1, there is no dimming
%   scalpha_dist is std of gaussian multiplier, in seconds  
%   if mark_epochs=1, marker type is mapped to epoch (ie epoch 1 gets period markers, epoch 2 gets star markers, etc) 

%vpmap maps vars to plot positions
%cols assign color to each plot position
%user input sets vpmap to default (unless input is change to vpmap)
%if a var doens't exist at a plot position, nothing is plotted there, but the plot positions of other variables do not change
% currently, stack must not be subset in x,y, or z, otherwise interactive roi indices will be wrong

gif_scope = 'eachv_eache'; %eachv_eache or allv_eache or allv_alle (currently can't do eachv_alle, but will soon); change filename (or not) according to epoch and variable changes
ts_scope = 'full'; %how much of total possible timseries to show in long timescale plot on top
yaxisroomfac = 0.15; %fraction of total, extra room on y axis
ylim_constancy = 'all';  %'all', 'each', or '' (empty); 'all' means y axis will be constant across all variables for a single fieldname in 'vars', each means it will be adjusted for each change in variable for each fieldname in 'vars'
lrscale = 'equal'; %whether left and right have relative scaling
sampinc = 5; %sample increment per gif frame; sampinc~=1 will include lower bound, but not necessarily upper, since sample=lower:sampinc:upper"
roialpha = 0.2; %transparency in roi overlay
rescale_timeseries = 1; %leave this as 1 to plot all timeseries on same scale (but keep tick labels at original scale)
skipnan_rescale = 1; %leave this as 1, skip nanes when rescaling to plot timeseries on same axis
newroirad = 2.5; %num pixels radius for user input rois
numfr_gif_max = 2000; %throw error if there will be more
timedim = 2;


%% arrange figure, choose colors

subplot_layout = {[4,4], stack};
margins_subplot = [0.05,0.005];
margins_fig = [0.07,0.01];
splitdim = 'y';
splitfrac = 0.5;
ax = arrange_subplots(subplot_layout, margins_subplot, margins_fig, splitdim, splitfrac);

cols = brewermap(numel(fieldnames(vars)),'Dark2'); %distinguishable_colors(numel(fieldnames(vars)));

if any(ismember(cols, [0 0 0], 'rows'))
    error("cannot use black for plotting until there is code to prevent it from being assigned to rois (since black roi overlay will cause error")
end


%% prep vars


[plotinds.z, plotinds.z_str] = make_plot_inds(size(stack, 3), plotinds.z, 'z');
[plotinds.t, plotinds.t_str] = make_plot_inds(size(stack, 4), plotinds.t, 't');


stack = stack(:,:,plotinds.z,plotinds.t);
ftv = ftv(:,:,plotinds.t);
epochinds_ts_i = epochinds_ts_i(plotinds.t);


if numel(size(ftv))==3
    ftv = reshape(ftv, size(ftv,1), size(ftv,2), 1, size(ftv,3)); %insert singleton 3rd dim, make time 4th dim, to match imaging stack and use same plotting code
end

vars = struct2cell(vars);
labs = struct2cell(labs);

[varsz, numts, numsamp] = get_vars_size(vars, timedim);

vars(cellfun(@isempty, vars)) = {nan(1,numsamp,'single')}; %make empty timeseries nan for now
labs(cellfun(@isempty, labs)) = {{''}}; %make empty labels 'novar' for now

for j = 1:numel(vars)
    vars{j} = convert_to_single_precision(vars{j});
    labs{j} = check_labels(labs{j}, vars{j});
    lims{j} = find_yaxis_limits(vars{j}, yaxisroomfac);
end

[vpmapflat, vpmapflat_axid] = translate_vpmap(vpmap);
vars = vars(vpmapflat);
labs = labs(vpmapflat);
lims = lims(vpmapflat);

varcombos = make_varcombos(vars);

[epochstring, tinds, numsamp_tslong_eachgif] = apply_epochinds(epochinds_ts_i, ti, epochinds_all, sampinc, ts_scope, gif_scope);

numfr_gif = check_gif_frame_number(gif_scope, tinds, varcombos, numfr_gif_max);


%% loop over epoch sets and plotting variables

revert_vars = 0; %revert to input variables after user input changes
timestr_ui = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')); %insert timestring when interactive to record each change in user input
newroicen_all = cell(numts, 1);
cbflags = struct;
plotloop = 1;
while plotloop %loop is turned off if no user input

    if ~all(structfun(@isempty, cbflags)) && ~revert_vars
        framecount = 0;
        [vars_use, labs_use, lims_use, roipixind_use, varcombos_use] = apply_user_input(cbflags, vars_use, labs_use, roipixind_use, stack, stack_mnt, dtmni, pth_mroi_interactive, normopt, newroirad, newroicen_all, xwid, zwid, yaxisroomfac, numsamp);
        timestr_use = timestr_ui;
    else
        vars_use = vars;
        labs_use = labs;
        lims_use = lims;
        roipixind_use = roiinfo.roipixind;
        varcombos_use = varcombos;
        timestr_use = '';
    end


    for ecnt = 1:numel(epochinds_all) %loop over all epoch sets (sets of samples within trial defining stimulus state)

        for vcount = 1:size(varcombos_use,1) %loop over all variable sets

            [varsp, labsp] = apply_varcombo(vars_use, labs_use, varcombos_use, vcount, numsamp_tslong_eachgif(ecnt));

            skipplot = skip_plot_criteria(labsp, 'none');

            if skipplot

                sprintf("skipping plot with these labels: " + cell2mat(labsp))

            else

                %%%% PREP VARS %%%%

                tlabsp = cellfun(@(x) x.(ylim_constancy), lims_use, 'UniformOutput', false);
                polarinds = find_polar_inds(labsp);
                varsp(polarinds,:) = insert_nan_for_polar_wrap(varsp(polarinds,:));
                varsp = nanpadvec(varsp, numsamp_tslong_eachgif(ecnt));
                yaxis_true_lims = find_yaxis_true_lims(lrscale, lims_use);
                varsp = rescale_to_range(varsp, tlabsp, yaxis_true_lims, skipnan_rescale);

                fngif = make_filename(labsp, gif_scope, epochstring{ecnt}, fngif_prefix_short, timestr_use); %gif_scope determines whether fngif gets updated
                [roiindp, roi_index_str] = find_roi_index(labsp);
                figure_title = make_figure_title(fngif_prefix_short, epochstring{ecnt}, dtmni, roi_index_str);
                labsp = process_labels(labsp, roiindp);

                roipixindp = cell(numel(roiindp),1);
                roipixindp(~cellfun(@isempty, roiindp)) = roipixind_use([roiindp{:}]);

                vpmapflat_axid_use = flag_empty_timeseries(varsp, vpmapflat_axid, timedim);

                %%%% INIT AXES %%%%
                if strcmp(gif_scope, 'eachv_eache') || (strcmp(gif_scope, 'allv_eache') && vcount == 1) || (strcmp(gif_scope, 'allv_alle') && ecnt == 1 && vcount == 1)

                    close all
                    hndls = struct;
                    framecount = 0;

                    hndls = init_fig(hndls, letui, gif_visibility);

                    sector_ind = 1;
                    subplot_ind = [5 13];
                    widfac = [4 1];
                    htfac = [2 2];
                    hndls.ts = init_axes_timeseries(hndls.hfg, ax, letui, numsamp_tslong_eachgif(ecnt), vpmapflat_axid_use, ti, lims_use, tlabsp, labsp, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries);

                    sector_ind = 2;
                    cmap = gray(256);
                    hndls.st = init_axes_stack(hndls.hfg, ax, letui, stack, cmap, zstartpos, display_range, sector_ind);

                    sector_ind = 1;
                    subplot_ind = 16; %subplot_ind=16 with widfac>1 forces image into margins, but it looks fine that way and gives more room for other plots
                    widfac = 2;
                    htfac = 2;
                    cmap = gray(256);
                    display_range_ftv = [0 1];
                    letui_ftv = 0;
                    txtvar_ftv = [];
                    hndls.ftv = init_axes_stack(hndls.hfg, ax, letui_ftv, ftv, cmap, txtvar_ftv, display_range_ftv, sector_ind, subplot_ind, widfac, htfac);

                end


                %%%% PLOT AXES %%%%
                [hndls, framecount, cbflags] = plot_axes(hndls, stack, ftv, ...
                    framecount, varsp, vpmapflat_axid_use, ti, tinds{ecnt}, cols, roialpha, roipixindp, ...
                    fngif, figure_title, varsz, letui, timestr_ui, sampinc);

                if cbflags.restart.v==1
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


function epochstring = make_epoch_string(epochinds)

delim = 'e';
epochstring.short = regexprep( mat2str(epochinds), {'\[', '\]', '\s+'}, {'', '', delim});
[~, epochstring.parsed] = get_epoch_number(epochstring.short);

end


function fngif = make_filename(lab, gif_scope, epochstring, fngif_prefix, timestr)


lab = strrep(strrep(lab, 'ts.', ''), '.', '-');

if strcmp(gif_scope, 'allv_alle') %one gif for all variables, all epochinds
    fngif_suffix = {'gifscopeall'};
elseif strcmp(gif_scope, 'allv_eache') %different gif for each epochinds
    fngif_suffix = {'gifscopeepoch', ['e' epochstring.short ]};
elseif strcmp(gif_scope, 'eachv_eache') %different gif for each variable set
    fngif_suffix = {['v_' strjoin(lab, '_')]; ['e' epochstring.short ]};
    fngif_suffix = {'eachv_eache'};
end

fngif = [fngif_prefix '_' strrep(strjoin(fngif_suffix), ' ', '_') '_' timestr '_.gif' ];

end


function figure_title = make_figure_title(fngif_prefix_short, epochstring, dtmni, roi_index_str)

stackidtmp = strsplit(fngif_prefix_short, filesep);
stackid = stackidtmp{end};
sample_period_string = make_sample_period_string(dtmni);
figure_title = [strrep(stackid, '_', ' ') ',   ' epochstring.parsed  ',   ' sample_period_string ' SAMPLES,    ROI #' roi_index_str];
figure_title = upper(figure_title);

end


function lab = process_labels(lab, roiind)


lab = strrep(lab, 'ts.', '');
lab = strrep(lab, '.', ' ');
lab = strrep(lab, 'vis', 'cue');

for ri = 1:numel(roiind)
    if ~isempty(roiind{ri})
        lab(ri) = regexprep(lab(ri), 'resp.*ind\d+$', ['ROI #' num2str(roiind{ri}) ' (F)']);
    end
end

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


function sample_period_string = make_sample_period_string(dtmni)

sample_period_string = [num2str(dtmni*1000, 4) ' ms']; %'%.2g'

end




function numsamp_tslong_eachgif = find_numsamp_tslong(ts_scope, gif_scope, ti, tinds_full)

if strcmp(ts_scope, 'full')
    numsamp_tslong_eachgif = numel(ti); %show full timeseries
    numsamp_tslong_eachgif = repelem(numsamp_tslong_eachgif, numel(tinds_full));
elseif strcmp(ts_scope, 'epoch')
    if strcmp(gif_scope, 'allv_alle')
        numsamp_tslong_eachgif = max(cellfun(@numel, tinds_full)); %show max of all epoch sets
        numsamp_tslong_eachgif = repelem(numsamp_tslong_eachgif, numel(tinds_full));
    else
        numsamp_tslong_eachgif = cellfun(@numel, tinds_full); %show max of all epoch sets
    end
end

end


function [varsz, numts, numsamp] = get_vars_size(vars, timedim)

varsz = cell2mat(cellfun(@size,vars,'UniformOutput',false));

if all(varsz ~= varsz(1))
    error("timeseries do not all have equal number samples")
end

numts = numel(vars);
numsamp = unique(varsz(:,timedim));


end


function [epochstring, tinds, numsamp_tslong_eachgif] = apply_epochinds(epochinds_ts_i, ti, epochinds_all, sampinc, ts_scope, gif_scope)

for j = 1:numel(epochinds_all) %loop over all epoch sets (sets of samples within trial defining stimulus state)
    epochstring{j} = make_epoch_string(epochinds_all{j});
    tinds_full{j} = find(ismember_each_element(epochinds_ts_i, epochinds_all{j}));
    tinds{j} = tinds_full{j}(1):sampinc:tinds_full{j}(end);
end
numsamp_tslong_eachgif = find_numsamp_tslong(ts_scope, gif_scope, ti, tinds_full);


end

function vpmapflat_axid = flag_empty_timeseries(vars, vpmapflat_axid, timedim)

vpmapflat_axid(all(isnan(vars),timedim)) = 0;

end

function [varstmp, labstmp] = apply_varcombo(vars_use, labs_use, varcombos_use, vcount, numsamp_tslong_eachgif)
varcombo = varcombos_use(vcount,:);
varstmp = zeros(numel(varcombo), numsamp_tslong_eachgif, 'single');
labstmp = cell(1, numel(varcombo));
for vi = 1:numel(varcombo)
    varstmp(vi,:) = vars_use{vi}(varcombo(vi),:);
    labstmp(vi) = labs_use{vi}(varcombo(vi));
end
end


function polarinds = find_polar_inds(labsp)

polarinds = (contains(labsp, 'yaw', 'IgnoreCase', true) | contains(labsp, 'ang', 'IgnoreCase', true)) & ~contains(labsp, 'vel', 'IgnoreCase', true);

end

function [vpmapflat, vpmapflat_axid] = translate_vpmap(vpmap)

if any(~structfun(@isvector, vpmap))
    error("each field of vpmap must contain a vector")
end
vpmap = structfun(@(x) transpose(vec(x)), vpmap, 'UniformOutput', false); %make sure each is row vector

vpmapflat = vec(cell2mat(transpose(struct2cell(vpmap))));
if numel(vpmapflat)~=numel(unique(vpmapflat))
    error("vpmap cannot have repeated elements")
end

vpmapflat_axid = zeros(numel(vpmapflat), 1);
fn = fieldnames(vpmap);
for j = 1:numel(vpmapflat)
    for k = 1:numel(fn)
        if ismember(vpmapflat(j), vpmap.(fn{k}))
            vpmapflat_axid(j) = k;
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

function numfr_gif = check_gif_frame_number(gif_scope, tinds, varcombos, numfr_gif_max)

num_extra_frames = 0;
numfr_gif = num_extra_frames;
epfr = cellfun(@numel, tinds);
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

