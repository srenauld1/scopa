function plot_experiment(letui, stack, stack_mnt, vars, labs, vpmap, ...
    epochinds_all, roiinfo, ti, dtmni, zstartpos, epochinds_ts_i, gif_visibility, ...
    plotinds, display_range, fngif_prefix_short, fngif_prefix, ftv, ...
    pth_mroi_interactive, normopt, xwid, zwid)


"currently, stack must not be subset in x,y, or z, otherwise interactive roi indices will be wrong"
"labs shouldn't be cell in cell"
"passing full stack to init_axes_stack, likewise for ftv"
"make additional varcombo rather than overwrite all rois with interactive"
"sampinc~=1 will include addlower bound, but not necessarily upper, since sample=lower:sampinc:upper"

%vpmap maps vars to plot positions 
%cols assign color to each plot position
%user input sets vpmap to default (unless input is change to vpmap)  
%if a var doens't exist at a plot position, nothing is plotted there, but the plot positions of other variables do not change

gif_scope = 'eachv_eache'; %eachv_eache or allv_eache or allv_alle (currently can't do eachv_alle, but will soon); change filename (or not) according to epoch and variable changes
ts_scope = 'full'; %how much of total possible timseries to show in long timescale plot on top 
yaxisroomfac = 0.15; %fraction of total, extra room on y axis 
ylim_constancy = 'all';  %'all', 'each', or '' (empty); 'all' means y axis will be constant across all variables for a single fieldname in 'vars', each means it will be adjusted for each change in variable for each fieldname in 'vars'
sampinc = 5; %sample increment per gif frame
roialpha = 0.2; %transparency in roi overlay
rescale_timeseries = 1; %leave this as 1 to plot all timeseries on same scale (but keep labels at original scale)
skipnan_rescale = 1; %leave this as 1, skip nanes when rescaling to plot timeseries on same axis
newroirad = 2.5; %num pixels radius
max_num_gif_frames = 2000; %throw error if there will be more
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
labs(cellfun(@isempty, labs)) = {{'NOVAR'}}; %make empty labels 'novar' for now 

for j = 1:numel(vars)
    vars{j} = convert_to_single_precision(vars{j});
    labs{j} = check_labels(labs{j}, vars{j});
    limsc{j} = find_yaxis_limits(vars{j}, yaxisroomfac);
end

varcombos = make_varcombos(vars);

[epochstring, tinds, numsamp_tslong_eachgif] = apply_epochinds(epochinds_ts_i, ti, epochinds_all, sampinc, ts_scope, gif_scope);

% if max(numsamp_tslong_eachgif)*size(varcombos, 1)>max_num_gif_frames
%     error("there will be too many frames in gif")
% end

roipixind = repelem({roiinfo.roipixind}, numts);

%% loop over epoch sets and plotting variables

revert_vars = 0;

timestr_ui = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')); %insert timestring when interactive to record each change in user input
newroicen_all = cell(numts, 1);

cbflags = struct;
plotloop = 1;
while plotloop %loop is shut off if no user input


    if ~all(structfun(@isempty, cbflags)) && ~revert_vars
        framecount = 0;
        [varcombos_use, vars_use, labs_use, roipixind_use, newroicen_all, limsc, vpmap] = apply_user_input(cbflags, vars_use, vpmap, labs_use, roipixind_use, stack, stack_mnt, dtmni, pth_mroi_interactive, normopt, newroirad, newroicen_all, xwid, zwid, limsc, yaxisroomfac);
        timestr_use = timestr_ui;
    else
        varcombos_use = varcombos;
        vars_use = vars;
        labs_use = labs;
        roipixind_use = roipixind;
        timestr_use = '';
    end


    for ecnt = 1:numel(epochinds_all) %loop over all epoch sets (sets of samples within trial defining stimulus state)

        for vcount = 1:size(varcombos_use,1) %loop over all variable sets

            [varstmp, labstmp] = apply_varcombo(vars_use, labs_use, varcombos_use, vcount, numsamp_tslong_eachgif(ecnt));

            skipplot = skip_plot_criteria(labstmp, 'none');

            if skipplot
                sprintf("skipping plot with these labels: " + cell2mat(labstmp))
            else

                %%%% PREP TIMESERIES VARS %%%%
                axsides = fieldnames(vpmap);
                pcnt_tot = 0;
                roiind_st = cell(1, numel(roiind));
                for fi = 1:numel(axsides) %for each side (left and right)
                    vpmaptmp = vpmap.(axsides{fi});
                    pcnt = 0;
                    for vi = 1:numel(vpmaptmp) %for each variable on one side
                        pcnt_tot = pcnt_tot + 1;
                        if ~all(isnan(varstmp(vpmaptmp(vi),:)))
                            pcnt = pcnt + 1;
                            labs_ts.(axsides{fi}){pcnt} = labstmp{vpmaptmp(vi)};
                            ticklabs_ts.(axsides{fi}){pcnt} = limsc{vpmaptmp(vi)}.(ylim_constancy);
                            cols_ts.(axsides{fi}){pcnt} = cols(pcnt_tot,:); %cols indexed by total, not side
                            lims_ts.(axsides{fi}).rescale = limsc{vpmaptmp(vi)}.rescale; %right now same for all, move this or make variable
                            lims_ts.(axsides{fi}).rescale_xtra = limsc{vpmaptmp(vi)}.rescale_xtra;  %right now same for all, move this or make variable
                            if contains(labs_ts.(axsides{fi}){pcnt}, 'yaw', 'IgnoreCase', true) | contains(labs_ts.(axsides{fi}){pcnt}, 'yaw', 'IgnoreCase', true)
                                varstmp(vpmaptmp(vi),:) = insert_nan_for_polar_wrap(varstmp(vpmaptmp(vi),:));
                            end
                            varstmp(vpmaptmp(vi),:) = nanpadvec(numsamp_tslong_eachgif(ecnt), varstmp(vpmaptmp(vi),:));
                            vars_ts.(axsides{fi})(pcnt,:) = rescale_to_range(varstmp(vpmaptmp(vi),:), ticklabs_ts.(axsides{fi}){pcnt}, [0 1], skipnan_rescale); %rescale from tick label to [0,1], to plot on same scale (but tick label retains original scale)
                        end
                    end
                end

                vpmap_st = vec(cell2mat(transpose(struct2cell(vpmap))));
                roiind_st = roiind(vpmap_st);

                fngif = make_filename(labstmp, gif_scope, vpmap, epochstring{ecnt}, fngif_prefix_short, timestr_use);
                [roiind, roi_index_str] = find_roi_index(labstmp);
                figure_title = make_figure_title(fngif_prefix_short, epochstring{ecnt}, dtmni, roi_index_str);
                labstmp = process_labels(labstmp, roiind);


                roipixind_st = cell(1, numel(roiind_st));
                for ri = 1:numel(roiind_st)
                    if isempty(roiind_st{ri})
                        roipixind_st{ri} = [];
                    else
                        roipixind_st{ri} = roipixind_use{ri}{roiind_st{ri}};
                    end
                end

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
                    hndls.ts = init_axes_timeseries(hndls.hfg, ax, letui, numsamp_tslong_eachgif(ecnt), vars_ts, ti, lims_ts, ticklabs_ts, labs_ts, cols_ts, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries);

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
                    framecount, vars_ts, ti, tinds{ecnt}, cols, roialpha, roipixind_st, ...
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


function fngif = make_filename(lab, gif_scope, vpmap, epochstring, fngif_prefix, timestr)


lab = strrep(strrep(lab, 'ts.', ''), '.', '-');

if strcmp(gif_scope, 'allv_alle') %one gif for all variables, all epochinds
    fngif_suffix = {'gifscopeall'};
elseif strcmp(gif_scope, 'allv_eache') %different gif for each epochinds
    fngif_suffix = {'gifscopeepoch', ['e' epochstring.short ]};
elseif strcmp(gif_scope, 'eachv_eache') %different gif for each variable set
    fngif_suffix = {['L_' strjoin(lab(vpmap.left), '_')]; ['R_' strjoin(lab(vpmap.right), '_')]; ['e' epochstring.short ]};
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
    if contains(lab{j}, 'intfor') || contains(lab{j}, 'intside') || contains(lab{j}, 'yaw') || contains(lab{j}, 'yaw')
        lab{j} = [lab{j} ' (RAD)'];
    end
    if contains(lab{j}, 'forvel') || contains(lab{j}, 'sidevel')
        lab{j} = [lab{j} ' (MM/S)'];
    end
    if contains(lab{j}, 'yawvel') || contains(lab{j}, 'yawvel')
        lab{j} = [lab{j} ' (RAD/S)'];
    end
end

lab = upper(lab);

end


function sample_period_string = make_sample_period_string(dtmni)

sample_period_string = [num2str(dtmni*1000, 4) ' ms']; %'%.2g'

end


function varargout = nanpadvec(numsamp_max_onegif, varargin)

for j = 1:numel(varargin)
    if ~isvector(varargin{j})
        error("must be vector")
    end
    numsamp_pad = numsamp_max_onegif-numel(varargin{j});
    varargout{j} = cat(1, varargin{j}(:), nan(numsamp_pad, 1));
end

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

function varinds_visible = find_visible_timeseries(vars, vpmap, timedim)

ignoreinds = find(cellfun(@(x) all(isnan(x), timedim), vars));

axsides = fieldnames(vpmap);
for fi = 1:numel(axsides) %for each side (left and right)
    varinds_visible.(axsides{fi}) = vpmap.(axsides{fi})(~ismember(vpmap.(axsides{fi}), ignoreinds));
end


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

