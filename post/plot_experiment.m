function plot_experiment(stack, varsx, varsy, varsz, labsx, labsy, labsz, ...
    epochinds_all, roiinfo, ti, dtmni, zstartpos, epochinds_ts_i, ...
    gif_visibility, plotinds, display_range, fngif_prefix_short, fngif_prefix)


%don't subset the stack
"set time dim"
"change var names from xyz, confusing"
gif_scope = 'allvars';
lag_style = 'each'; %currently 'each' is only option; lags xy, then z for each xy; lag_style 'any' (soon available) will allow all combinations
threshold_data = 0;
blindspot = -pi/12; %nan to not draw blind spot
pval_siglev = 0.05; %pval bar gets colored if below pval_siglev
axisroomfac = 0.1;
maxlablength = 10000; %making this large to skip, isn't necessary so far
mkrsz = 4; %scatter marker size
fontmedium = 11;
ylim_constancy = 'eachvar';  %allvars, eachvar, none
sample_period_string = [num2str(dtmni*1000, 4) ' ms']; %'%.2g'
plot_z_as_color = 0;

% olayopt.foreground_plot_style = 'overlay'; %'boundary'; %options to show individual rois are 'boundary' and 'overlay'
% olayopt.ncol_each = 128; %number colors in each part of the overlay plot (2 parts are: mean volume/background, and roi/foreground)
% olayopt.saturation_factor_background = 1; %for gif, above this fraction of data is sent to max
% olayopt.saturation_factor_rois = 1; %for gif above this fraction of data is sent to max
% filename_olay = '~/stacks/olaytest.gif';
% olayopt.doplot = 1;
% ri = 1;
% stack = make_roi_overlay(stack, roiinfo.pixinds_roi(ri), olayopt.ncol_each, ...
%     olayopt.foreground_plot_style, olayopt.saturation_factor_background, ...
%     olayopt.saturation_factor_rois, filename_olay, olayopt.doplot);

roi_type = 'rois';
switch roi_type
    case 'pixels'
        for roi_ind = 1:roiinfo.numroi
            [crosshair{roi_ind}(1), crosshair{roi_ind}(2), crosshair{roi_ind}(3)] = ind2sub(size(roiinfo.mask_allroi), roiinfo.pixinds_roi{roi_ind});
        end
    case 'rois'
        crosshair = cellfun(@round, roiinfo.centroids_roi, 'UniformOutput', false); %will this take it out of bounds? should not
    case 'raw'
        error("raw doens't work yet")
end



label_prefix = 'z';
[plotinds.z, plotinds.z_str] = make_plot_inds(size(stack, 3), plotinds.z, label_prefix);
label_prefix = 't';
[plotinds.t, plotinds.t_str] = make_plot_inds(size(stack, 4), plotinds.t, label_prefix);

stack = stack(:,:,plotinds.z,plotinds.t);
epochinds_ts_i = epochinds_ts_i(plotinds.t);
ti = ti(plotinds.t);
varsx = varsx(:,plotinds.t);
varsy = varsy(:,plotinds.t);
% varsz = varsz(:,plotinds.t);

subplot_layout = {[4,4], stack};
margins_subplot = [0.05,0.005];
margins_fig = [0.07,0.01];
splitdim = 'y';
splitfrac = [0.5];
ax = arrange_subplots(subplot_layout, margins_subplot, margins_fig, splitdim, splitfrac);


[varsx, varsy, varsz] = convert_to_single_precision(varsx, varsy, varsz);
[varsx, varsy, varsz, z_is_empty, labsz, lagsz_sec] = check_variable_size(varsx, varsy, varsz);

labsx = check_labels(labsx, varsx);
labsy = check_labels(labsy, varsy);
labsz = check_labels(labsz, varsz);

[lims, numsamp_max] = find_axis_limits(varsx, varsy, varsz, axisroomfac, epochinds_all, epochinds_ts_i);


timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
fngif = [fngif_prefix '_.gif' ];
indpolar_prev = Inf;
hndls = struct;
framecount = 0;
for ei = 1:numel(epochinds_all)

    epochinds = epochinds_all{ei};
    tinds = find(ismember_each_element(epochinds_ts_i, epochinds));
    tinew = ti(tinds);

    % [actual_lags_xy_sec, actual_lags_z_sec, lagsall_xy, lagsall_z, zero_lag_index, numlags] = compute_lags(tinew, lagsxy_sec, lagsz_sec, lag_style); %actual lags depend on epoch (samples you're using)

    varcount = 0;
    for zi = 1:size(varsz, 1)
        for yi = 1:size(varsy, 1)
            for xi = 1:size(varsx, 1)
                varcount = varcount+1;

                varx = varsx(xi, tinds);
                vary = varsy(yi, tinds);
                varz = varsz(zi, tinds);
                labx = strrep(strrep(strrep(labsx{xi}, '_', ' '), '.', ' '), 'ts', '');
                laby = strrep(strrep(strrep(labsy{yi}, '_', ' '), '.', ' '), 'ts', '');
                labz = strrep(strrep(strrep(labsz{zi}, '_', ' '), '.', ' '), 'ts', '');
                laball = {labx, laby, labz};

                roi_index = find_roi_index(laball);
                [polar_index, labt, labr] = find_polar_index(labx, laby, labz);
                axtype = set_axtype(polar_index, z_is_empty, plot_z_as_color);
                skipplot = skip_plot_criteria(laball, 'none');

                [fngif, figure_title, labx, laby, labz, labt, labr] = process_strings(labx, laby, labz, labt, labr, axtype, epochinds, plot_z_as_color, gif_scope, varcount, ei, fngif_prefix_short, fngif_prefix, fngif, roi_index, sample_period_string);

                if isempty(polar_index)
                    polar_index = 100;
                    lims.t = lims.y;
                    lims.r = lims.x;
                else
                    switch polar_index
                        case 1
                            lims.t = lims.y;
                            lims.r = lims.x;
                        case 2
                            lims.t = lims.x;
                            lims.r = lims.y;
                        otherwise
                            error("not built for this yet")
                    end
                end

                if ~skipplot

                    sector_ind = 1;
                    subplot_ind = [1 5];
                    widfac = 4;
                    htfac = 1;

                    hndls = init_axes_timeseries(hndls, ax, numsamp_max, varx, vary, tinew, lims, sector_ind, subplot_ind, widfac, htfac);

                    sector_ind = 2;
                    cmap = gray(256);
                    hndls = init_axes_stack(hndls, ax, stack, cmap, roiinfo.pixinds_roi(roi_index), zstartpos, display_range, sector_ind);

                    % if isempty(polar_index) & ~isequal(polar_index, indpolar_prev)
                    %     scatter_type = 'cartesian';
                    %     hndls = init_axes(hndls, stack, lims, ylim_constancy, roi_index, scatter_type, ax, tinew, numsamp_max, numlags, actual_lags_xy_sec, plot_z_as_color, mkrsz, gif_visibility, fontmedium, blindspot, axisroomfac, zstartpos);
                    % end
                    % if ~isempty(polar_index) & ~isequal(polar_index, indpolar_prev)
                    %     scatter_type = 'polar';
                    %     hndls = init_axes(hndls, stack, lims, ylim_constancy, roi_index, scatter_type, ax, tinew, numsamp_max, numlags, actual_lags_xy_sec, plot_z_as_color, mkrsz, gif_visibility, fontmedium, blindspot, axisroomfac, zstartpos);
                    % end
                    indpolar_prev = polar_index;

                    if ismember(1, polar_index)
                        varx = insert_nan_for_polar_wrap(varx);
                    end
                    if ismember(2, polar_index)
                        vary = insert_nan_for_polar_wrap(vary);
                    end
                    if ismember(3, polar_index)
                        varz = insert_nan_for_polar_wrap(varz);
                    end
                    [plotx, ploty, plotz] = nanpadvars(numsamp_max, varx, vary, varz);

                    [hndls, framecount] = plot_axes(hndls, stack, lims, xi, yi, zi, ...
                        ylim_constancy, roi_index, crosshair, gif_scope, framecount, ...
                        plotx, ploty, plotz, tinew, labx, laby, labz, labt, labr,  ...
                        polar_index, fngif, roi_type, plot_z_as_color, figure_title);


                end
            end
        end
    end
end

end



function [varsx, varsy, varsz] = convert_to_single_precision(varsx, varsy, varsz)

if ~isa(varsx, 'single') & ~isa(varsx, 'double')
    error("varsx is neither single nor double, are you sure you want to proceed?");
end
if ~isa(varsy, 'single') & ~isa(varsy, 'double')
    error("varsy is neither single nor double, are you sure you want to proceed?");
end
if ~isa(varsz, 'single') & ~isa(varsz, 'double')
    error("varsz is neither single nor double, are you sure you want to proceed?");
end
if isa(varsx, 'double')
    varsx = single(varsx);
end
if isa(varsy, 'double')
    varsy = single(varsy);
end
if isa(varsz, 'double')
    varsz = single(varsz);
end



end

function [varsx, varsy, varsz, z_is_empty, labsz, lagsz_sec] = check_variable_size(varsx, varsy, varsz)

if isempty(varsx) & isempty(varsy) || isempty(varsx) & isempty(varsz) || isempty(varsy) & isempty(varsz)
    error("only one nonempty variable, at least 2 nonempty variables are required")
end
if isempty(varsx) & ~isempty(varsz)
    varsx = varsz;
    varsz = [];
    disp("varsx is empty but not varsz, moving varsz to varsx")
end
if isempty(varsy) & ~isempty(varsz)
    varsy = varsz;
    varsz = [];
    disp("varsy is empty but not varsz, moving varsz to varsy")
end
if isempty(varsz)
    z_is_empty = 1;
    varsz = nan(1, size(varsx, 2));
    labsz = {''};
    lagsz_sec = 0;
    disp("there is no z variable; setting lagz_sec to zero, labsz to empty, and varsz to nans")
else
    z_is_empty = 0;
end

end

function [lims, numsamp_max] = find_axis_limits(varsx, varsy, varsz, axisroomfac, epochinds_all, epochinds_ts_i)

rngx = range(varsx, 2);
rngy = range(varsy, 2);
rngz = range(varsz, 2);
lims.x.each = [min(varsx, [], 2, 'omitmissing'), max(varsx, [], 2, 'omitmissing')];
lims.y.each = [min(varsy, [], 2, 'omitmissing'), max(varsy, [], 2, 'omitmissing')];
lims.z.each = [min(varsz, [], 2, 'omitmissing'), max(varsz, [], 2, 'omitmissing')];
lims.x.each_xtra = [lims.x.each(:,1) - rngx*axisroomfac, lims.x.each(:,2) + rngx*axisroomfac];
lims.y.each_xtra = [lims.y.each(:,1) - rngy*axisroomfac, lims.y.each(:,2) + rngy*axisroomfac];
lims.z.each_xtra = [lims.z.each(:,1) - rngz*axisroomfac, lims.z.each(:,2) + rngz*axisroomfac];
lims.x.all = [min(lims.x.each, [], 'all', 'omitmissing'), max(lims.x.each, [], 'all', 'omitmissing')];
lims.y.all = [min(lims.y.each, [], 'all', 'omitmissing'), max(lims.y.each, [], 'all', 'omitmissing')];
lims.z.all = [min(lims.z.each, [], 'all', 'omitmissing'), max(lims.z.each, [], 'all', 'omitmissing')];
lims.x.all_xtra = [min(lims.x.each_xtra, [], 'all', 'omitmissing'), max(lims.x.each_xtra, [], 'all', 'omitmissing')];
lims.y.all_xtra = [min(lims.y.each_xtra, [], 'all', 'omitmissing'), max(lims.y.each_xtra, [], 'all', 'omitmissing')];
lims.z.all_xtra = [min(lims.z.each_xtra, [], 'all', 'omitmissing'), max(lims.z.each_xtra, [], 'all', 'omitmissing')];
lims.t = [];
lims.r = [];
lims.t2 = [];
lims.t3 = [];


numsamp_max = 0;
for ei = 1:numel(epochinds_all)
    numsamp_max = max(numsamp_max, numel(find(ismember_each_element(epochinds_ts_i, epochinds_all{ei}))));
end

end



function [actual_lags_xy_sec, actual_lags_z_sec, lagsall_xy, lagsall_z, zero_lag_index, numlags] = compute_lags(ti, lagsxy_sec, lagsz_sec, lag_style)

[lagsxy, actual_lags_xy_sec] = compute_lags_onedim(ti, lagsxy_sec);
[lagsz, actual_lags_z_sec] = compute_lags_onedim(ti, lagsz_sec);

switch lag_style
    case 'each'
        lgn = 0;
        for zitmp = lagsz
            for xyitmp = lagsxy
                lgn = lgn + 1;
                lagsall_xy(lgn) = xyitmp;
                lagsall_z(lgn) = zitmp;
            end
        end
    case 'any'
        error("lag_style 'any' not yet available")
end

zero_lag_index = find(lagsall_xy==0 & lagsall_z==0);
numlags = numel(lagsall_xy);

end

function [lags_samp, actual_lags_sec] = compute_lags_onedim(ti, lags_sec)


ticumdiff = ti - ti(1);
if isequal(lags_sec, 0)
    lags_samp = 0;
    actual_lags_sec = 0;
else
    lags_sec_neg = abs(lags_sec(lags_sec<0));
    [~, lags_samp_neg] = min(abs(ticumdiff-lags_sec_neg));
    lags_sec_pos = lags_sec(lags_sec>=0);
    [~, lags_samp_pos] = min(abs(ticumdiff-lags_sec_pos));
    lags_samp = [-lags_samp_neg, 0, lags_samp_pos];
    lags_samp = unique(lags_samp);
    actual_lags_sec = [vec(-ticumdiff(abs(lags_samp(lags_samp<0))+1)); vec(ticumdiff(lags_samp(lags_samp>=0)+1))];
    actual_lags_sec = unique(actual_lags_sec);
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


function roi_index = find_roi_index(laball)

labind_with_rois = find(startsWith(laball, 'resp') | startsWith(laball, ' resp')); %only check labels beginning with 'resp'
if isempty(labind_with_rois) %if none begin with 'resp', then there is no roi data
    roi_index = [];
else
    roi_index_expression = 'ind\d+$'; %ends with ind followed by integer
    [futmp, ~] = regexp(laball{labind_with_rois}, roi_index_expression, 'match');
    if isempty(futmp) %single responses don't get 'ind1' suffix, but if string begins with resp, we can call it roi_index 1
        roi_index = 1;
    else
        roi_index = sscanf(cell2mat(futmp), 'ind%d'); %extract number at end, following 'ind'
    end
end

end



function [polar_index, labt, labr] = find_polar_index(labx, laby, labz)

polar_index = [];
if endsWith(labx, 'yaw') || endsWith(labx, 'ang')
    polar_index = [polar_index 1];
end
if endsWith(laby, 'yaw') || endsWith(laby, 'ang')
    polar_index = [polar_index 2];
end
if endsWith(labz, 'yaw') || endsWith(labz, 'ang')
    polar_index = [polar_index 3];
end

labt = '';
labr = '';
if isequal(polar_index, 1)
    labt = labx;
    labr = laby;
elseif isequal(polar_index, 2) %if vary is polar, list it before varx (by convention, here, x/theta always precede y/rho in filenames/labels)
    labt = laby;
    labr = labx;
elseif isequal(polar_index, 3)
    labt = labz;
    labr = labx; %if z is only polar variable, by default make x rho and y color?
end

if numel(polar_index)>1 || any(polar_index==3)
    error("need to make sure double polar plots still work, and choose how to order xy when z polar")
end


end


function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagxy, lagz)


%first apply xy lag
if lagxy<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxy = vec(varx(1+abs(lagxy):end));
    vary_lagxy = vec(vary(1:end-abs(lagxy)));
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxy = vec(varx(1:end-abs(lagxy)));
    vary_lagxy = vec(vary(1+abs(lagxy):end));
end

%now apply 3rd variable lag
if lagz<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1+abs(lagz):end));
    vary_lagxyz = vec(vary_lagxy(1+abs(lagz):end));
    varz_lagxyz = vec(varz(1:end - (abs(lagxy)+abs(lagz)) )); %also include lagxy for 3rd var
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1:end-abs(lagz)));
    vary_lagxyz = vec(vary_lagxy(1:end-abs(lagz)));
    varz_lagxyz = vec(varz( (1+abs(lagxy)+abs(lagz) ) :end));
end

end

function skipplot = skip_plot_criteria(laball, noneflag)

if strcmp(noneflag, 'none') %don't apply criteria

    skipplot = 0;

else

    if ~any(endsWith(laball, 'vel')) & ~any(endsWith(laball, 'speed'))
        skipplot = 1;
    end

    if numel(unique(laball(:)))~=numel(laball(:)) %must not have duplicate vars
        skipplot = 1;
    end

    if any(strcmp(laball, 'angvel')) %must not have cuevel if skip_cuevel
        skipplot = 1;
    end

    if ((any(strcmp(laball, 'respgal')) | any(strcmp(laball, 'respgar'))) & any(strcmp(laball, 'respgalrmean'))) | ... %must not have no and ga from "same side" (not connected)
            ((any(strcmp(laball, 'respnol')) | any(strcmp(laball, 'respnor'))) & any(strcmp(laball, 'respnolrmean')))
        skipplot = 1;
    end

    if (any(endsWith(laball, 'gar')) & any(endsWith(laball, 'no_r'))) | ... %must not have no and ga from "same side" (not connected)
            (any(endsWith(laball, 'gal')) & any(endsWith(laball, 'no_l')))
        skipplot = 1;
    end

end

end


function [fngif_new, figure_title, labx, laby, labz, labt, labr] = process_strings(labx, laby, labz, labt, labr, axtype, epochinds, plot_z_as_color, gif_scope, varcount, ei, fngif_prefix_short, fngif_prefix, fngif_old, roi_index, sample_period_string)

if isempty(labz)
    dimstring = '2d';
else
    if plot_z_as_color
        dimstring = '2dcol';
    else
        dimstring = '3d';
    end
end

epochstring = regexprep( mat2str(epochinds), {'\[', '\]', '\s+'}, {'', '', 'e'});

if strcmp(epochstring, '1')
    epochstring_parsed = 'CLOSED LOOP';
end

stackidtmp = strsplit(fngif_prefix_short, filesep);
stackid = stackidtmp{end};
figure_title = [strrep(stackid, '_', ' ') ',   ' epochstring_parsed  ',   ' sample_period_string ' SAMPLES,    ROI #' num2str(roi_index)];
figure_title = upper(figure_title);

fngif_suffix = {[axtype{1} laby]; [axtype{2} labx]; [axtype{3} labz]; ['e' epochstring ' ' dimstring ]}; %switch order
fngif_suffix = strrep(strjoin(fngif_suffix), ' ', '_');
if strcmp(gif_scope, 'all') && ei==0 %make fngif at first epoch, first variable, and never update
    fngif_new = [fngif_prefix '_' fngif_suffix '_.gif' ];
elseif strcmp(gif_scope, 'epoch') && varcount==0 %update fngif for each epoch
    fngif_new = [fngif_prefix '_' fngif_suffix '_.gif' ];
elseif strcmp(gif_scope, 'var') %update for each variable
    fngif_new = [fngif_prefix '_' fngif_suffix '_.gif' ];
else
    fngif_new = fngif_old;
end

labx = strrep(labx, 'vis', 'cue');
laby = strrep(laby, 'vis', 'cue');
labz = strrep(labz, 'vis', 'cue');
labt = strrep(labt, 'vis', 'cue');
labr = strrep(labr, 'vis', 'cue');
labx = regexprep(labx, 'resp.*ind\d+$', ['ROI #' num2str(roi_index) ' (F)']);
laby = regexprep(laby, 'resp.*ind\d+$', ['ROI #' num2str(roi_index) ' (F)']);
labz = regexprep(labz, 'resp.*ind\d+$', ['ROI #' num2str(roi_index) ' (F)']);
labt = regexprep(labt, 'resp.*ind\d+$', ['ROI #' num2str(roi_index) ' (F)']);
labr = regexprep(labr, 'resp.*ind\d+$', ['ROI #' num2str(roi_index) ' (F)']);
if contains(labx, 'int')
    labx = [labx ' (RAD)'];
end
if contains(laby, 'int')
    laby = [laby ' (RAD)'];
end
if contains(labz, 'int')
    labz = [labz ' (RAD)'];
end
if contains(labt, 'int')
    labt = [labt ' (RAD)'];
end
if contains(labr, 'int')
    labr = [labr ' (RAD)'];
end
if endsWith(labx, 'vel')
    labx = [labx ' (RAD/S)'];
end
if endsWith(laby, 'vel')
    laby = [laby ' (RAD/S)'];
end
if endsWith(labz, 'vel')
    labz = [labz ' (RAD/S)'];
end
if endsWith(labt, 'vel')
    labt = [labt ' (RAD/S)'];
end
if endsWith(labr, 'vel')
    labr = [labr ' (RAD/S)'];
end

labx = upper(labx);
laby = upper(laby);
labz = upper(labz);
labt = upper(labt);
labr = upper(labr);


end

function axtype = set_axtype(polar_index, z_is_empty, plot_z_as_color)

if isempty(polar_index)
    axtype = {'X', 'Y'};
else
    axtype = {'T', 'R'};
end
if z_is_empty
    axtype{3} = '';
else
    if plot_z_as_color
        axtype{3} = 'C';
    else
        axtype{3} = 'Z';
    end
end

end





function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz)

keepind = ~(isnan(varx_lagxyz) | isnan(vary_lagxyz));
varz_lagxyz_isnan = isnan(varz_lagxyz);
if any(varz_lagxyz_isnan)
    keepind = keepind | varz_lagxyz_isnan;
    varz_lagxyz = varz_lagxyz(keepind);
end
varx_lagxyz = varx_lagxyz(keepind);
vary_lagxyz = vary_lagxyz(keepind);
if ~any(varz_lagxyz_isnan)
    varz_lagxyz = ones(numel(varx_lagxyz), 1);
end

end





