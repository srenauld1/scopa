function plot_experiment(interactive, stack, vars, labs, varinds, epochinds_all, roiinfo, ...
    ti, dtmni, zstartpos, epochinds_ts_i, gif_visibility, plotinds, ...
    display_range, fngif_prefix_short, fngif_prefix, ftv, pth_tmpfiles)



"currently, stack must not be subset in x,y, or z, otherwise interactive roi indices will be wrong"

gif_scope = 'allv_alle'; %eachv_eache or allv_eache or allv_alle (currently can't do eachv_alle, but will soon); change filename (or not) according to epoch and variable changes
ts_scope = 'full'; %how much of total possible timseries to show in long timescale plot on top 
yaxisroomfac = 0.15; %fraction of total, extra room on y axis 
ylim_constancy = 'all';  %'all', 'each', or '' (empty); 'all' means y axis will be constant across all variables for a single fieldname in 'vars', each means it will be adjusted for each change in variable for each fieldname in 'vars'
sampinc = 1; %sample increment per gif frame
alphafac = 0.2; %transparency in roi overlay
rescale_timeseries = 1; %leave this as 1 to plot all timeseries on same scale (but keep labels at original scale)
skipnan_rescale = 1; %leave this as 1, skip nanes when rescaling to plot timeseries on same axis


%% prep vars


delete([pth_tmpfiles 'tmp_cbf_.bin']) %try delete first in case you errored in the middle of callback last time
delete([pth_tmpfiles 'tmp_cbf_digit_.bin']) %try delete first in case you errored in the middle of callback last time
delete([pth_tmpfiles 'tmp_cbf_uiroi_.bin']) %try delete first in case you errored in the middle of callback last time

[plotinds.z, plotinds.z_str] = make_plot_inds(size(stack, 3), plotinds.z, 'z');
[plotinds.t, plotinds.t_str] = make_plot_inds(size(stack, 4), plotinds.t, 't');

stack = stack(:,:,plotinds.z,plotinds.t);
ftv = ftv(:,:,plotinds.t);
epochinds_ts_i = epochinds_ts_i(plotinds.t);
% ti = ti(plotinds.t);

if numel(size(ftv))==3
    ftv = reshape(ftv, size(ftv,1), size(ftv,2), 1, size(ftv,3)); %insert singleton 3rd dim, make time 4th dim, to match imaging stack and use same plotting code
end

fnp = fieldnames(varinds);

fn = fieldnames(vars);
for fi = 1:numel(fn)
    % vars.(fn{fi}) = vars.(fn{fi})(:,plotinds.t);
    vars.(fn{fi}) = convert_to_single_precision(vars.(fn{fi}));
    labs.(fn{fi}) = check_labels(labs.(fn{fi}), vars.(fn{fi}));
    lims.(fn{fi}) = find_yaxis_limits(vars.(fn{fi}), yaxisroomfac);
end

varsc = struct2cell(vars);
labsc = struct2cell(labs);
limsc = struct2cell(lims);

[varcombos, varsz] = make_varcombos(varsc);

subplot_layout = {[4,4], stack};
margins_subplot = [0.05,0.005];
margins_fig = [0.07,0.01];
splitdim = 'y';
splitfrac = [0.5];
ax = arrange_subplots(subplot_layout, margins_subplot, margins_fig, splitdim, splitfrac);

cols = cat(1, [0 0 0], distinguishable_colors(numel(varsc))); %make black first color, so subtract one for distinguishable_colors



%% loop over epoch sets and plotting variables


plotloop = 1;
while plotloop


    if exist('cbflags', 'var') && ~all(structfun(@isempty, cbflags))
        [varcombos_use, varsc_use, labsc_use] = user_input_updates(cbflags, varsc, labsc);
        timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS')); %insert timestring when interactive to record each change in user input
    else
        varcombos_use = varcombos;
        varsc_use = varsc;
        labsc_use = labsc;
        timestr = '';
    end


    for ecount = 1:numel(epochinds_all) %loop over all epoch sets (sets of samples within trial defining stimulus state)

        epochinds = epochinds_all{ecount};
        epochstring = make_epoch_string(epochinds);
        tinds = find(ismember_each_element(epochinds_ts_i, epochinds));
        tinds = tinds(1):sampinc:tinds(end);

        numsamp_max_full_ts_onegif = find_maxnumsamp(ts_scope, ti, tinds, epochinds_all, epochinds_ts_i);

        tinew = ti(tinds);
        stack = stack(:,:,:,tinds);
        ftv = ftv(:,:,tinds);


        for vcount = 1:size(varcombos_use,1) %loop over all variable sets

            varcombo = varcombos_use(vcount,:);
            varstmp = zeros(numel(varcombo), numsamp_max_full_ts_onegif, 'single');
            labstmp = cell(1, numel(varcombo));
            for vi = 1:numel(varcombo)
                varstmp(vi,:) = varsc_use{vi}(varcombo(vi),:);
                labstmp(vi) = labsc_use{vi}(varcombo(vi));
            end


            fngif = make_filename(labstmp, gif_scope, varinds, epochstring, fngif_prefix, timestr);
            [roi_index, roi_index_str] = find_roi_index(labstmp);
            figure_title = make_figure_title(fngif_prefix_short, epochstring, dtmni, roi_index_str);
            labstmp = process_labels(labstmp, roi_index);

            skipplot = skip_plot_criteria(labstmp, 'none');

            if skipplot
                sprintf("skipping plot with these labels: " + cell2mat(labstmp))
            else

                %%%% PREP TIMESERIES VARS %%%%
                cnt = 0;
                for fi = 1:numel(fnp) %for each side (left and right)
                    varindstmp = varinds.(fnp{fi});
                    for vi = 1:numel(varindstmp) %for each variable
                        cnt = cnt + 1;
                        labsp.(fnp{fi}){vi} = labstmp{varindstmp(vi)};
                        ticklab.(fnp{fi}){vi} = limsc{varindstmp(vi)}.(ylim_constancy);
                        limsp.(fnp{fi}).rescale = limsc{varindstmp(vi)}.rescale;
                        limsp.(fnp{fi}).rescale_xtra = limsc{varindstmp(vi)}.rescale_xtra;
                        if contains(labsp.(fnp{fi}){vi}, 'yaw', 'IgnoreCase', true) | contains(labsp.(fnp{fi}){vi}, 'ang', 'IgnoreCase', true)
                            varstmp(cnt,:) = insert_nan_for_polar_wrap(varstmp(cnt,:));
                        end
                        varstmp(cnt,:) = nanpadvec(numsamp_max_full_ts_onegif, varstmp(cnt,:));
                        varsp.(fnp{fi})(vi,:) = rescale_to_range(varstmp(varindstmp(vi),:), ticklab.(fnp{fi}){vi}, [0 1], skipnan_rescale); %rescale from tick label to [0,1], to multiple lines can be on same scale (but tick label remains unchanged)
                    end
                end


                %%%% INIT AXES %%%%
                if strcmp(gif_scope, 'eachv_eache') || (strcmp(gif_scope, 'allv_eache') && vcount == 1) || (strcmp(gif_scope, 'allv_alle') && ecount == 1 && vcount == 1)
                    
                    close all
                    hndls = struct;
                    framecount = 0;

                    hndls = init_fig(hndls, gif_visibility);

                    sector_ind = 1;
                    subplot_ind = [1 13];
                    widfac = [4 1];
                    htfac = [1 3];
                    hndls = init_axes_timeseries(hndls, ax, numsamp_max_full_ts_onegif, varinds, ti, limsp, ticklab, labsp, cols, sector_ind, subplot_ind, widfac, htfac, rescale_timeseries);

                    sector_ind = 1;
                    subplot_ind = 15;
                    widfac = 3;
                    htfac = 3;
                    cmap = gray(256);
                    display_range_ftv = [0 1];
                    hndls = init_axes_ftvid(hndls, ax, ftv, cmap, [], [], display_range_ftv, sector_ind, subplot_ind, widfac, htfac);

                    sector_ind = 2;
                    cmap = gray(256);
                    hndls = init_axes_stack(hndls, pth_tmpfiles, ax, stack, cmap, zstartpos, display_range, sector_ind);

                    if interactive
                        set(hndls.hfg, 'KeyPressFcn', @(src,evnt)pltexp_key_press_fcn(src,evnt,pth_tmpfiles));
                    else
                        plotloop = 0;
                    end

                end


                %%%% PLOT AXES %%%%
                [hndls, framecount, cbflags] = plot_axes(hndls, stack, ftv, ...
                    framecount, varsp, tinew, fngif, figure_title, ...
                    roiim, alphaim, interactive, pth_tmpfiles, varsz);

                if cbflags.restart==1
                    break;
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



function lims = find_yaxis_limits(varsin, yaxisroomfac)

varrng = range(varsin, 2);
lims.each = [min(varsin, [], 2, 'omitmissing'), max(varsin, [], 2, 'omitmissing')];
lims.each_xtra = [lims.each(:,1) - varrng*yaxisroomfac, lims.each(:,2) + varrng*yaxisroomfac];
lims.all = [min(lims.each, [], 'all', 'omitmissing'), max(lims.each, [], 'all', 'omitmissing')];
lims.all_xtra = [min(lims.each_xtra, [], 'all', 'omitmissing'), max(lims.each_xtra, [], 'all', 'omitmissing')];
lims.rescale = [0 1];
lims.rescale_xtra = [0 - yaxisroomfac, 1 + yaxisroomfac];

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


function [roi_index, roi_index_str] = find_roi_index(labsp)

varind_with_rois = find(startsWith(labsp, 'ts.resp') | startsWith(labsp, ' ts.resp')); %only check labels beginning with 'resp'
for li = 1:numel(labsp)
    if ismember(li, varind_with_rois) %if none begin with 'resp', then there is no roi data
        roi_index_expression = 'ind\d+$'; %ends with ind followed by integer
        [futmp, ~] = regexp(labsp{li}, roi_index_expression, 'match');
        if isempty(futmp) %single responses don't get 'ind1' suffix, but if string begins with resp, we can call it roi_index 1
            roi_index{li} = 1;
        else
            roi_index{li} = sscanf(cell2mat(futmp), 'ind%d'); %extract number at end, following 'ind'
        end
    else
        roi_index{li} = [];
    end
end

delim = ',';
roi_index_str = regexprep( mat2str(cell2mat(roi_index(~cellfun('isempty',roi_index)))), {'\[', '\]', '\s+'}, {'', '', delim});


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

    if any(strcmp(labsp, 'angvel')) %must not have cuevel if skip_cuevel
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


function fngif = make_filename(lab, gif_scope, varinds, epochstring, fngif_prefix, timestr)

lab = strrep(strrep(lab, 'ts.', ''), '.', '-');

if strcmp(gif_scope, 'allv_alle') %one gif for all variables, all epochinds
    fngif_suffix = {'gifscopeall'};
elseif strcmp(gif_scope, 'allv_eache') %different gif for each epochinds
    fngif_suffix = {'gifscopeepoch', ['e' epochstring.short ]};
elseif strcmp(gif_scope, 'eachv_eache') %different gif for each variable set
    fngif_suffix = {['L_' strjoin(lab(varinds.left), '_')]; ['R_' strjoin(lab(varinds.right), '_')]; ['e' epochstring.short ]};
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


function lab = process_labels(lab, roi_index)


lab = strrep(lab, 'ts.', '');
lab = strrep(lab, '.', ' ');
lab = strrep(lab, 'vis', 'cue');

for ri = 1:numel(roi_index)
    if ~isempty(roi_index{ri})
        lab(ri) = regexprep(lab(ri), 'resp.*ind\d+$', ['ROI #' num2str(roi_index{ri}) ' (F)']);
    end
end

for j = 1:numel(lab)
    if contains(lab{j}, 'intfor') || contains(lab{j}, 'intside') || contains(lab{j}, 'yaw') || contains(lab{j}, 'ang')
        lab{j} = [lab{j} ' (RAD)'];
    end
    if contains(lab{j}, 'forvel') || contains(lab{j}, 'sidevel')
        lab{j} = [lab{j} ' (MM/S)'];
    end
    if contains(lab{j}, 'angvel') || contains(lab{j}, 'yawvel')
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

function numsamp_max_full_ts_onegif = find_maxnumsamp(ts_scope, ti, tinds, epochinds_all, epochinds_ts_i)

if strcmp(ts_scope, 'full')
    numsamp_max_full_ts_onegif = numel(ti); %show full timeseries
elseif strcmp(ts_scope, 'epoch')
    if strcmp(gif_scope, 'allv_alle')
        numsamp_max_full_ts_allepochsets = 0;
        for ecount = 1:numel(epochinds_all)
            numsamp_max_full_ts_allepochsets = max(numsamp_max_full_ts_allepochsets, numel(find(ismember_each_element(epochinds_ts_i, epochinds_all{ecount}))));
        end
        numsamp_max_full_ts_onegif = numsamp_max_full_ts_allepochsets; %show all epochs in input epoch sets
    else
        numsamp_max_full_ts_onegif = numel(tinds); %show only current epoch
    end
end

end

function [varcombos, varsz] = make_varcombos(varsc)

varsz = cell2mat(cellfun(@size,varsc,'UniformOutput',false));

if all(varsz ~= varsz(1))
    error("timeseries do not have equal number samples")
end

for vi = 1:size(varsz,1)
    varcombstmp{vi} = 1:varsz(vi,:);
end
varcombos = cell(1, numel(varcombstmp));
[varcombos{:}] = ndgrid(varcombstmp{:});
varcombos = cellfun(@(x) x(:), varcombos, 'uniformoutput', false);
varcombos = [varcombos{:}];

end

function [varcombos, varsc_out, labsc_out] = user_input_updates(cbflags, varsc_in, labsc_in)

try
    if ~isempty(cbflags.uiroipixind)
        cbflags.uiroipixind

    else
    varsc_out = varsc_in;
    labsc_out = labsc_in;
    varsc_out{cbflags.pvarind} = varsc_in{cbflags.pvarind}(cbflags.ivarind,:);
    labsc_out{cbflags.pvarind} = labsc_in{cbflags.pvarind}(cbflags.ivarind);
    end
catch ME
    sprintf("user input for variable change has problem, returning to original variables")
    sprintf(ME.message)
end

varcombos = make_varcombos(varsc_out);


end
