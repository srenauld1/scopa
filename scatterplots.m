function scatterplots(stack, varsx, varsy, varsz, labsx, labsy, labsz, ...
    epochinds_all, roidat, ti, sampper, zstartpos, epochts, lagsxy_sec, ...
    lagsz_sec, lags_to_plot, plot_z_as_color, gifvis, pthgif_prefix_short, pthgif_prefix)


error("scatterplots is deprecated, replaced by scatterplot routine within pltx")

%don't subset the stack 

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
sample_period_string = [num2str(sampper*1000, '%.2g') ' ms'];

% stack = roidat.roi_overlay;
roi_type = 'rois';
switch roi_type
    case 'pixels'
        for roi_ind = 1:roidat.numroi
            [crosshair{roi_ind}(1), crosshair{roi_ind}(2), crosshair{roi_ind}(3)] = ind2sub(size(roidat.mask_allroi), roidat.roipx{roi_ind});
        end
    case 'rois'
        crosshair = cellfun(@round, roidat.roicen, 'UniformOutput', false); %will this take it out of bounds? should not
    case 'raw'
        error("raw doens't work yet")
end

layout = {[4,4], stack};
marginax = [0.05, 0];
marginfg = 0.05;
splitdim = 'x';
splitfrac = 0.65;
ax = axarr(layout, marginax=marginax, marginfg=marginfg, splitdim=splitdim, splitfrac=splitfrac);


[varsx, varsy, varsz] = convert_to_single_precision(varsx, varsy, varsz);
[varsx, varsy, varsz, z_is_empty, labsz, lagsz_sec] = check_variable_size(varsx, varsy, varsz, labsz, lagsz_sec);

labsx = check_labels(labsx, varsx);
labsy = check_labels(labsy, varsy);
labsz = check_labels(labsz, varsz);

[lims, numsamp_max] = axlim_old(varsx, varsy, varsz, axisroomfac, epochinds_all, epochts);


timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
pthgif = [pthgif_prefix '_.gif' ];
indpolar_prev = Inf;
h = struct;
framecount = 0;
for ei = 1:numel(epochinds_all)

    epochnum = epochinds_all{ei};
    tinds = find(ismember_each(epochts, epochnum));
    tinew = ti(tinds);

    [actual_lags_xy_sec, actual_lags_z_sec, lagsall_xy, lagsall_z, zero_lag_index, numlags] = compute_lags(tinew, lagsxy_sec, lagsz_sec, lag_style); %actual lags depend on epoch (samples you're using)

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
                [pthgif, figure_title, labx, laby, labz, labt, labr] = process_strings(labx, laby, labz, labt, labr, axtype, epochnum, plot_z_as_color, gif_scope, varcount, ei, pthgif_prefix_short, pthgif_prefix, pthgif, roi_index, sample_period_string);

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


                if ~skipplot

                    if isempty(polar_index) & ~isequal(polar_index, indpolar_prev)
                        scatter_type = 'cartesian';
                        h = init_axes(h, stack, lims, ylim_constancy, roi_index, scatter_type, ax, tinew, numsamp_max, numlags, actual_lags_xy_sec, plot_z_as_color, mkrsz, gifvis, fontmedium, blindspot, axisroomfac, zstartpos);
                    end
                    if ~isempty(polar_index) & ~isequal(polar_index, indpolar_prev)
                        scatter_type = 'polar';
                        h = init_axes(h, stack, lims, ylim_constancy, roi_index, scatter_type, ax, tinew, numsamp_max, numlags, actual_lags_xy_sec, plot_z_as_color, mkrsz, gifvis, fontmedium, blindspot, axisroomfac, zstartpos);
                    end
                    indpolar_prev = polar_index;

                    [plotx, ploty, plotz, r_dummy1, r_dummy2, cmp, ccr, pval_norm, laginds_to_plot] = ...
                        prepvars(numlags, lagsall_xy, lagsall_z, varx, vary, varz, threshold_data, laball, z_is_empty, ...
                        plot_z_as_color, polar_index, numsamp_max, zero_lag_index, lags_to_plot, pval_siglev);

                    [h, framecount] = plotvars(h, stack, lims, xi, yi, zi, ylim_constancy, roi_index, crosshair, gif_scope, framecount, laginds_to_plot, ...
                        plotx, ploty, plotz, labx, laby, labz, labt, labr, cmp, r_dummy1, r_dummy2, ...
                        polar_index, actual_lags_xy_sec, ccr, pval_norm, pthgif, roi_type, plot_z_as_color, figure_title);


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

function [varsx, varsy, varsz, z_is_empty, labsz, lagsz_sec] = check_variable_size(varsx, varsy, varsz, labsz, lagsz_sec)

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
    disp("setting lagz_sec to zero since there is no z variable")
else
    z_is_empty = 0;
end

end

function [lims, numsamp_max] = axlim_old(varsx, varsy, varsz, axisroomfac, epochinds_all, epochts)

rngx = range(varsx, 2);
rngy = range(varsy, 2);
rngz = range(varsz, 2);
lims.x.each = [min(varsx, [], 2, 'omitmissing'), max(varsx, [], 2, 'omitmissing')];
lims.y.each = [min(varsy, [], 2, 'omitmissing'), max(varsy, [], 2, 'omitmissing')];
lims.z.each = [min(varsz, [], 2, 'omitmissing'), max(varsz, [], 2, 'omitmissing')];
lims.x.eachpad = [lims.x.each(:,1) - rngx*axisroomfac, lims.x.each(:,2) + rngx*axisroomfac];
lims.y.eachpad = [lims.y.each(:,1) - rngy*axisroomfac, lims.y.each(:,2) + rngy*axisroomfac];
lims.z.eachpad = [lims.z.each(:,1) - rngz*axisroomfac, lims.z.each(:,2) + rngz*axisroomfac];
lims.x.all = [min(lims.x.each, [], 'all', 'omitmissing'), max(lims.x.each, [], 'all', 'omitmissing')];
lims.y.all = [min(lims.y.each, [], 'all', 'omitmissing'), max(lims.y.each, [], 'all', 'omitmissing')];
lims.z.all = [min(lims.z.each, [], 'all', 'omitmissing'), max(lims.z.each, [], 'all', 'omitmissing')];
lims.x.allpad = [min(lims.x.eachpad, [], 'all', 'omitmissing'), max(lims.x.eachpad, [], 'all', 'omitmissing')];
lims.y.allpad = [min(lims.y.eachpad, [], 'all', 'omitmissing'), max(lims.y.eachpad, [], 'all', 'omitmissing')];
lims.z.allpad = [min(lims.z.eachpad, [], 'all', 'omitmissing'), max(lims.z.eachpad, [], 'all', 'omitmissing')];
lims.t = [];
lims.r = [];
lims.t2 = [];
lims.t3 = [];

numsamp_max = 0;
for ei = 1:numel(epochinds_all)
    numsamp_max = max(numsamp_max, numel(find(ismember_each(epochts, epochinds_all{ei}))));
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
    if isempty(lags_samp_neg)
        lags_samp = lags_samp_pos;
    elseif isempty(lags_samp_pos)
        lags_samp = lags_samp_neg;
    else
        lags_samp = [-lags_samp_neg, 0, lags_samp_pos];
    end
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
if endsWith(labx, 'yaw') || endsWith(labx, 'yaw')
    polar_index = [polar_index 1];
end
if endsWith(laby, 'yaw') || endsWith(laby, 'yaw')
    polar_index = [polar_index 2];
end
if endsWith(labz, 'yaw') || endsWith(labz, 'yaw')
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

    if any(strcmp(laball, 'yawvel')) %must not have cuevel if skip_cuevel
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



function varargout = nanpadvar_loc(numsamp_max, varargin)

for j = 1:numel(varargin)
    if ~isvector(varargin{j})
        error("must be vector")
    end
    numsamp_pad = numsamp_max-numel(varargin{j});
    varargout{j} = cat(1, varargin{j}(:), nan(numsamp_pad, 1));
end

end

function [pthgif_new, figure_title, labx, laby, labz, labt, labr] = process_strings(labx, laby, labz, labt, labr, axtype, epochnum, plot_z_as_color, gif_scope, varcount, ei, pthgif_prefix_short, pthgif_prefix, pthgif_old, roi_index, sample_period_string)

if isempty(labz)
    dimstring = '2d';
else
    if plot_z_as_color
        dimstring = '2dcol';
    else
        dimstring = '3d';
    end
end

epochstring = regexprep( mat2str(epochnum), {'\[', '\]', '\s+'}, {'', '', 'e'});

if strcmp(epochstring, '1')
    epochstring_parsed = 'CLOSED LOOP';
end

stackidtmp = strsplit(pthgif_prefix_short, filesep);
stackid = stackidtmp{end};
figure_title = [strrep(stackid, '_', ' ') ',   ' epochstring_parsed  ',   ' sample_period_string ' SAMPLES,    ROI #' num2str(roi_index)];
figure_title = upper(figure_title);

pthgif_suffix = {[axtype{1} laby]; [axtype{2} labx]; [axtype{3} labz]; ['e' epochstring ' ' dimstring ]}; %switch order
pthgif_suffix = strrep(strjoin(pthgif_suffix), ' ', '_');
if strcmp(gif_scope, 'all') && ei==0 %make pthgif at first epoch, first variable, and never update
    pthgif_new = [pthgif_prefix '_' pthgif_suffix '_.gif' ];
elseif strcmp(gif_scope, 'epoch') && varcount==0 %update pthgif for each epoch
    pthgif_new = [pthgif_prefix '_' pthgif_suffix '_.gif' ];
elseif strcmp(gif_scope, 'var') %update for each variable
    pthgif_new = [pthgif_prefix '_' pthgif_suffix '_.gif' ];
else
    pthgif_new = pthgif_old;
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

function h = init_axes(h, stack, lims, ylim_constancy, roi_index, scatter_type, ax, ti, numsamp_max, numlags, actual_lags_xy_sec, plot_z_as_color, mkrsz, gifvis, fontmedium, blindspot, axisroomfac, zstartpos)

%must reinitialize axes to switch between cartesian and polar axes in the same location of the same figure; to save time, this function is called only when the axis switches
dummyvec_ts = nan(numsamp_max, 1);
dummyvec_lag = nan(numlags, 1);


if ~isfield(h, 'hfg') %if no figure has been initialized yet, initialize the axes that won't change


    [dms,arat] = pxscreenget();
    szf = 0.75; 

    szftmp = figsz(szf);
    hfg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    hfg.Position = [0 0 szftmp];
    haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );


    %%%%%%%%%%%% BAR PLOT %%%%%%%%%%%%

    sector_ind = 1;
    spind = 1;
    width_multiplier = 2.8;
    height_multiplier = 1;
    haxbr = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    haxbr.InnerPosition(1) = ax(sector_ind).x(spind);
    haxbr.InnerPosition(2) = ax(sector_ind).y(spind);
    haxbr.InnerPosition(3) = ax(sector_ind).w(width_multiplier);
    haxbr.InnerPosition(4) = ax(sector_ind).h(height_multiplier);
    hold(haxbr, 'on')

    hplbr = bar(haxbr, dummyvec_lag, dummyvec_lag);
    hplbrln = xline(haxbr, nan, 'k');

    haxbr.YLim = [-1 1];
    haxbr.Box = 'off';
    haxbr.Title.String = 'LAG';
    haxbr.XLim = [min(actual_lags_xy_sec) - range(actual_lags_xy_sec)*axisroomfac, max(actual_lags_xy_sec) + range(actual_lags_xy_sec)*axisroomfac];
    haxbr.XTick = [min(actual_lags_xy_sec), 0, max(actual_lags_xy_sec)];
    haxbr.XTickLabels = {sprintf('%.2g', min(actual_lags_xy_sec)), 0, sprintf('%.2g', max(actual_lags_xy_sec))};
    haxbr.Title.String = 'LAGS';
    haxbr.YLabel.String = 'CORR COEFF';

    hold(haxbr, 'off')


    %%%%%%%%%%%% TIMESERIES %%%%%%%%%%%%

    sector_ind = 1;
    spind = 4;
    width_multiplier = 4;
    height_multiplier = 0.8;

    haxts = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    haxts.InnerPosition(1) = ax(sector_ind).x(spind);
    haxts.InnerPosition(2) = ax(sector_ind).y(spind);
    haxts.InnerPosition(3) = ax(sector_ind).w(width_multiplier);
    haxts.InnerPosition(4) = ax(sector_ind).h(height_multiplier);

    hold(haxts, 'on')
    yyaxis left
    hplts1 = plot(haxts, ti, dummyvec_ts);
    hplts1.Color = [0 0 1];
    yyaxis right
    hplts2 = plot(haxts, ti, dummyvec_ts);
    hplts2.Color = [1 0 0];
    hpltsln = xline(haxts, nan, 'k');

    haxts.XTick = round(max(ti));
    haxts.XTickLabel = [num2str(haxts.XTick) ' sec'];
    haxts.YAxis(1).Color = [0 0 1];
    haxts.YAxis(2).Color = [1 0 0];
    if strcmp(ylim_constancy, 'allvars')
        haxts.YAxis(1).Limits = lims.x.all;
        haxts.YAxis(2).Limits = lims.y.all;
    end
    haxts.Box = 'off';
    haxts.XLabel.String = '';
    haxts.YLabel.String = '';

    hold(haxts, 'off')


    %%%%%%%%%%%% STACK IMAGES %%%%%%%%%%%%

    sector_ind = 2;
    width_multiplier = 1;
    height_multiplier = 1;

    if roi_index %if there are roi variables

        for spind = 1:ax(sector_ind).numsubplot

            [cit, rit] = ind2sub([ax(sector_ind).numcolumns, ax(sector_ind).numrows], spind); %reverse output since subplots are column-major
            spind_new = sub2ind([ax(sector_ind).numrows, ax(sector_ind).numcolumns], rit, cit);

            haxfov{spind} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
            haxfov{spind}.InnerPosition(1) = ax(sector_ind).x(spind);
            haxfov{spind}.InnerPosition(2) = ax(sector_ind).y(spind);
            haxfov{spind}.InnerPosition(3) = ax(sector_ind).w(width_multiplier);
            haxfov{spind}.InnerPosition(4) = ax(sector_ind).h(height_multiplier);

            hold(haxfov{spind}, 'on');

            dummy_index_dim5 = 1;
            hplfov{spind} = image(haxfov{spind}, squeeze(stack(:,:,spind,:,dummy_index_dim5))); %dummy_index_dim5=1 will work to initialize for roi_type pixel and roi

            % axis image %should not have to call axis image because of how subfig width/height were calculated to maintain aspect ratio above
            axis off
            axis ij

            hplfovlnx{spind} = xline(haxfov{spind}, nan, 'w', 'LineStyle', 'none');
            hplfovlny{spind} = yline(haxfov{spind}, nan, 'w', 'LineStyle', 'none');
            txfov{spind} = text( haxfov{spind}, size(stack, 2), size(stack, 1), num2str(zstartpos(spind)), 'Units', 'data', 'FontSize', fontmedium, 'Color', 'white');
            txfov{spind}.HorizontalAlignment = 'right';
            txfov{spind}.VerticalAlignment = 'bottom';

        end

    else %if there are no roi variables

        htx = text( ax(sector_ind).x(1), ax(sector_ind).y(1), 'NO ROI DATA, SKIPPING FOV PLOTS', 'FontSize', fontmedium, 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;

        haxfov = [];
        hplfov = [];
        hplfovlnx = [];
        hplfovlny = [];

    end

    %%%%%%%%%%%% ASSIGN HANDLES TO OUTPUT STRUCT %%%%%%%%%%%%

    h.hfg = hfg;
    h.htx = htx;
    h.haxbr = haxbr;
    h.haxts = haxts;
    h.hplbr = hplbr;
    h.hplbrln = hplbrln;
    h.hplts1 = hplts1;
    h.hplts2 = hplts2;
    h.hpltsln = hpltsln;
    h.haxfov = haxfov;
    h.hplfov = hplfov;
    h.hplfovlnx = hplfovlnx;
    h.hplfovlny = hplfovlny;

end

%%%%%%%%%%%% SCATTERPLOT %%%%%%%%%%%%
% initialize axes that can change (scatterplots, which can be cartesian or polar, and must be reinitialized for each switch)

sector_ind = 1;
spind = 7;
width_multiplier = 3;
height_multiplier = 3;

tmp_x_extent = ax(sector_ind).w(width_multiplier);
tmp_y_extent = ax(sector_ind).h(height_multiplier);
minextent = min(tmp_x_extent, tmp_y_extent); %force this axis to be square, without

switch scatter_type

    case 'cartesian'

        if isfield(h, 'haxscp')
            delete(h.haxscp)
            delete(h.hplscp1)
            delete(h.hplscp2)
            delete(h.hpllnp)
        end

        haxscc = axes( 'Parent', h.hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
        haxscc.InnerPosition(1) = ax(sector_ind).x(spind);
        haxscc.InnerPosition(2) = ax(sector_ind).y(spind);
        haxscc.InnerPosition(3) = minextent; %do this rather than plotBoxAspectRatio to ensure shorter axis is used
        haxscc.InnerPosition(4) = minextent; %do this rather than plotBoxAspectRatio to ensure shorter axis is used


        hold(haxscc, 'on')
        if plot_z_as_color
            hplscc = scatter(haxscc, dummyvec_ts, dummyvec_ts, mkrsz, dummyvec_ts, 'filled');
        else
            hplscc = scatter3(haxscc, dummyvec_ts, dummyvec_ts, dummyvec_ts, mkrsz, dummyvec_ts, 'filled');
        end

        haxscc.Box = 'off';
        if ylim_constancy
            % haxscp.XLim = [0 1];
            % haxscp.YLim = [0 1];
        end
        hplscc.MarkerFaceColor = 'k';

        hold(haxscc, 'off')

        h.haxscc = haxscc;
        h.hplscc = hplscc;


    case 'polar'

        if isfield(h, 'haxscc')
            delete(h.haxscc)
            delete(h.hplscc)
        end

        haxscp = polaraxes( 'Parent', h.hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
        haxscp.InnerPosition(1) = ax(sector_ind).x(spind);
        haxscp.InnerPosition(2) = ax(sector_ind).y(spind);
        haxscp.InnerPosition(3) = minextent;
        haxscp.InnerPosition(4) = minextent;

        hold(haxscp, 'on')
        hplscp1 = polarscatter(haxscp, dummyvec_ts, dummyvec_ts, mkrsz, 'filled');
        hplscp2 = polarscatter(haxscp, dummyvec_ts, dummyvec_ts, mkrsz, 'filled');
        hpllnp = polarplot(haxscp, [blindspot blindspot], [0 0], 'r');

        hplscp1.MarkerFaceColor = 'k';
        hplscp2.MarkerFaceColor = 'k';
        hpllnp.LineStyle = 'none';

        haxscp.RTickLabel = [];

        haxscp.ThetaTick = [0 90 180 270];
        haxscp.ThetaTickLabel = {'0', '90', '180', '270'};

        haxscp.ThetaAxis.Label.Units = 'normalized';
        haxscp.ThetaAxis.Label.Position = [0.5, -0.05, 0];
        haxscp.ThetaAxis.Label.Rotation = 0;
        haxscp.RAxis.Label.Units = 'normalized';
        haxscp.RAxis.Label.Position = [-0.13, 0.5, 0];
        haxscp.RAxis.Label.Rotation = 90;

        if ylim_constancy
            % haxscp.RLim = [0 1];
        end

        hold(haxscp, 'off')

        h.haxscp = haxscp;
        h.hplscp1 = hplscp1;
        h.hplscp2 = hplscp2;
        h.hpllnp = hpllnp;


end

end



function [plotx, ploty, plotz, r_dummy1, r_dummy2, cmp, ccr, pval_norm, laginds_to_plot] = prepvars(numlags, lagsall_xy, lagsall_z, varx, vary, varz, threshold_data, laball, z_is_empty, plot_z_as_color, polar_index, numsamp_max, zero_lag_index, lags_to_plot, pval_siglev)


plotx = cell(1, numlags);
ploty = cell(1, numlags);
plotz = cell(1, numlags);
r_dummy1 = cell(1, numlags);
r_dummy2 = cell(1, numlags);
cmp = cell(1, numlags);
ccr = zeros(1, numlags);
ccpv = zeros(1, numlags);

for lagind = 1:numlags

    [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagsall_xy(lagind), lagsall_z(lagind));

    [plotx{lagind}, ploty{lagind}, plotz{lagind}] = remove_nans_as_group(varx_lagxyz, vary_lagxyz, varz_lagxyz);

    if ismember(1, polar_index)
        plotx{lagind} = polarnan(plotx{lagind});
    end
    if ismember(2, polar_index)
        ploty{lagind} = polarnan(plotx{lagind});
    end
    if ismember(3, polar_index)
        plotz{lagind} = polarnan(plotx{lagind});
    end

    %threshold if requested
    if threshold_data
        if contains(laball{1}, 'vel')
            [histdt, histx] = hist(abs(plotx{lagind}(:)), 500);
            thrbin = triangle_threshold(histdt, 'R', 0);
            thrvel = histx(thrbin);
            excludeinds = abs(plotx{lagind})<thrvel;
        elseif contains(laball{2}, 'vel')
            [histdt, histx] = hist(abs(ploty{lagind}(:)), 500);
            thrbin = triangle_threshold(histdt, 'R', 0);
            thrvel = histx(thrbin);
            excludeinds = abs(ploty{lagind})<thrvel;
        end
        plotx{lagind}(excludeinds) = [];
        ploty{lagind}(excludeinds) = [];
        plotz{lagind}(excludeinds) = [];
    end


    %sort for color plot (if plot_z_as_color)
    if z_is_empty | (~z_is_empty & ~plot_z_as_color)
        cmp{lagind} = [0 0 1];
    elseif ~z_is_empty & plot_z_as_color
        [~, idx4] = sort(plotz{lagind});
        plotx{lagind} = plotx{lagind}(idx4);
        ploty{lagind} = ploty{lagind}(idx4);
        cmp{lagind} = jet(numel(idx4));
    end


    %dummy variables for possible double polar plot (ie two polar vars)
    rdummy1_lbnd = 0.1; %for double polar plots
    rdummy1_ubnd = 0.45;%for double polar plots
    rdummy2_lbnd = 0.5;%for double polar plots
    rdummy2_ubnd = 0.85;%for double polar plots
    r_dummy1{lagind} = rdummy1_lbnd + (rdummy1_ubnd-rdummy1_lbnd)*rand(size(plotx{lagind}));
    r_dummy2{lagind} = rdummy2_lbnd + (rdummy2_ubnd-rdummy2_lbnd)*rand(size(ploty{lagind}));

    %find corr coeffs
    switch num2str(polar_index)
        case ''
            [ccr(lagind) ccpv(lagind)] = corr(plotx{lagind}, ploty{lagind}); %linear-linear
            % [ccr(lagind) ccpv(lagind)] = corr(plotz{lagind}, ploty{lagind}); %linear-linear
        case '1'
            [ccr(lagind) ccpv(lagind)] = circ_corrcl(plotx{lagind}, ploty{lagind}); %circ-linear
        case '2'
            [ccr(lagind) ccpv(lagind)] = circ_corrcl(ploty{lagind}, plotx{lagind}); %circ-linear (and switch input order)
        case '1  2'
            [ccr(lagind) ccpv(lagind)] = circ_corrcc(plotx{lagind}, ploty{lagind}); %circ-circ
    end

    [plotx{lagind}, ploty{lagind}, plotz{lagind}, r_dummy1{lagind}, r_dummy2{lagind}] = nanpadvar_loc(numsamp_max, plotx{lagind}, ploty{lagind}, plotz{lagind}, r_dummy1{lagind}, r_dummy2{lagind});

end

pval_norm = pval_siglev-ccpv;
pval_norm(pval_norm<0) = 0;
if ~any(pval_norm)
    pval_norm = 1;
else
    rngpvalnorm = max(pval_norm)-min(pval_norm);
    if rngpvalnorm==0
        pval_norm = 0;
    else
        bar_contrast = 0.3; %to make difference between non-significant (white) and barely significant (0.05) clear in blue saturation 
        pval_norm = 1 - (pval_norm - min(pval_norm)) / rngpvalnorm + bar_contrast;
    end
end

switch lags_to_plot
    case 'zero'
        laginds_to_plot = zero_lag_index;
    case 'best'
        [~, laginds_to_plot] = max(abs(ccr));
    case 'zeroandbest'
        [~, ccrmaxabs] = max(abs(ccr));
        laginds_to_plot = [zero_lag_index ccrmaxabs];
    case 'all'
        laginds_to_plot = 1:numlags;
end


end




function [h, framecount] = plotvars(h, stack, lims, xi, yi, zi, ylim_constancy, roi_index, crosshair, gif_scope, framecount, laginds_to_plot, plotx, ploty, plotz, labx, laby, labz, labt, labr, cmp, r_dummy1, r_dummy2, polar_index, actual_lags_xy_sec, ccr, pval_norm, pthgif, roi_type, plot_z_as_color, figure_title)


h.htx.String = figure_title;

if strcmp(gif_scope, 'eachvar')
    framecount = 0;
end
for lagind = laginds_to_plot
    framecount = framecount+1;

    if isempty(polar_index)

        h.hplscc.XData = plotx{lagind};
        h.hplscc.YData = ploty{lagind};
        h.hplscc.CData = cmp{lagind};
        if ~plot_z_as_color
            h.hplscc.ZData = plotz{lagind};
        end

        h.haxscc.XLabel.String = ['\color{blue} ' labx];
        h.haxscc.YLabel.String = ['\color{red} ' laby];
        % h.haxscc.ZLabel.String = labz;

    else

        if polar_index==1
            h.hplscp1.ThetaData = plotx{lagind};
            h.hplscp1.RData = ploty{lagind};
            h.hplscp1.CData = cmp{lagind};
        elseif polar_index==2
            h.hplscp1.ThetaData = ploty{lagind};
            h.hplscp1.RData = plotx{lagind};
            h.hplscp1.CData = cmp{lagind};
        elseif isequal(polar_index, [1 2])
            h.hplscp1.ThetaData = plotx{lagind};
            h.hplscp1.RData = r_dummy1{lagind};
            h.hplscp2.ThetaData = ploty{lagind};
            h.hplscp2.RData = r_dummy2{lagind};
        end

        % if numel(laby)>maxlablength
        %     labt = cat(2, labt(1:maxlablength), '\newline', labt(maxlablength+1:end)))
        % end
        h.haxscp.ThetaAxis.Label.String = ['\color{blue} Theta:' labt];
        h.haxscp.RAxis.Label.String = ['\color{red} Rho: ' labr];
        if strcmp(ylim_constancy, 'eachvar')
            h.haxscp.RLim = lims.y.eachpad(yi,:);
            h.haxscp.RTick = sort([0, lims.y.each(yi,1), lims.y.each(yi,2)]);
            h.haxscp.RTickLabel = [];
            % for tti = 1:numel(h.haxscp.RTick)
            %     h.haxscp.RTickLabel{tti} = num2str(h.haxscp.RTick(tti), 4);%'%.2g'
            % end
        end

        if isempty(regexp(labt, ' CUE yaw'))
            h.hpllnp.LineStyle = 'none';
        else
            h.hpllnp.RData = [lims.y.each(yi,2) lims.y.eachpad(yi,2)]; %blindspot red line from data max to xtra max, to be sure it doesn't cover data 
            h.hpllnp.LineStyle = '-';
        end

    end


    h.haxbr.Title.String = ['LAGS (CURR: ' sprintf('%.2g', actual_lags_xy_sec(lagind)) ' SEC)']; 
    h.hplbr.FaceColor = 'flat';
    h.hplbr.XData = actual_lags_xy_sec;
    h.hplbr.YData = ccr;
    h.hplbr.CData = repmat([0 0 1], numel(pval_norm), 1);
    h.hplbr.CData(:,1) = pval_norm;
    h.hplbr.CData(:,2) = pval_norm;

    h.hplbrln.Value = actual_lags_xy_sec(lagind);

    h.hplts1.YData = plotx{lagind};
    h.hplts2.YData = ploty{lagind};
    h.haxts.XLabel.String = ['\color{blue} ' labx '    \color{red}' laby];
    if strcmp(ylim_constancy, 'eachvar')
        h.haxts.YAxis(1).Limits = lims.x.eachpad(xi,:);
        h.haxts.YAxis(2).Limits = lims.y.eachpad(yi,:);
        h.haxts.YAxis(1).TickValues = sort([0, lims.x.each(xi,1), lims.x.each(xi,2)]);
        h.haxts.YAxis(2).TickValues = sort([0, lims.y.each(yi,1), lims.y.each(yi,2)]);
        h.haxts.YAxis(1).TickLabels = [];
        h.haxts.YAxis(2).TickLabels = [];
        for tti = 1:numel(h.haxts.YAxis(2).TickValues)
            h.haxts.YAxis(1).TickLabels{tti} = num2str(h.haxts.YAxis(1).TickValues(tti), 4);%'%.2g'
            h.haxts.YAxis(2).TickLabels{tti} = num2str(h.haxts.YAxis(2).TickValues(tti), 4);%'%.2g'
        end
    end

    if roi_index

        for spind = 1:numel(h.hplfov)

            if strcmp(roi_type, 'rois') %roi_type pixels image never changes
                h.hplfov{spind}.CData = squeeze(stack(:,:,spind,:,roi_index));
            end

            if spind==crosshair{roi_index}(3)
                h.hplfovlny{spind}.Value = crosshair{roi_index}(1);
                h.hplfovlnx{spind}.Value = crosshair{roi_index}(2);
                h.hplfovlny{spind}.LineStyle = '-';
                h.hplfovlnx{spind}.LineStyle = '-';
            else
                h.hplfovlny{spind}.LineStyle = 'none';
                h.hplfovlnx{spind}.LineStyle = 'none';
            end
        end

    end

    fig2gif(h.hfg, framecount, pthgif)

end

if strcmp(gif_scope, 'eachvar')
    close all
end

end


