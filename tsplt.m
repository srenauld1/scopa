function [hfg, hax] = tsplt(ts, opt)

% plot one or more timeseries on one figure; if 2 or more timeseries, first goes onto one axis, the rest go onto the other (allowing them to have different length x)
% option to sequentially display over one or more segments of x (if xseg>1), optionally saving each segment as frame of gif
% option to pass existing figure handle and add axes to that, in which case figure will not save within this function

arguments (Repeating)
    ts
end

arguments
    opt.xall = [] %x for all y, will interpret repeating xy arguments as all y arguments; if this is empty, will interpret them as alternating x,y
    opt.xseg {mustBeNumeric} = 1 %(n,2) vector of x axis limits as fraction range 0-1, or scalar n for partitioning x axis into n segments; will plot each n and optionally save each as different frame in gif
    opt.yconst {mustBeNumeric} = 0 %0 or 1 whether to update y limits for each xlim subset (if 1, will set to [min max], or length 2 vector defining constant ylim
    opt.ix = [] %[min,max] x to plot
    opt.ylimtype = 'all'
    opt.yroomfac {mustBeNumeric} = 0.1 %percentage of y range to pad above and below
    opt.xmark = [] %x positions to draw markers (style set by mkr2); nearest interp to x; no extrapolation performed (outside domain is discarded); if vector, will apply to all timeseries; if cell, cell index indicates which timeseries to mark; nested cell will draw multiple sets of marks on same timeseries; will error if there is not a common x
    opt.xln = []
    opt.tsp = 0
    opt.mkr {mustBeText} = 'diamond' %marker for plotting optional argument 'xmark',  length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.col = []; %color,  length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.lst {mustBeText} = '-' %linestyle, length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.minsampperseg = 5 %min samples per xseg
    opt.maxnumts = 20 %max number timeseries
    opt.maxnumxmark = 20 %max number timeseries
    opt.titlein {mustBeText} = '' %title
    opt.pthgif {mustBeText} = '' %figure save path
    opt.gifvis {mustBeText} = 'on'
    opt.hfg = [] %can pass figure handle to add to existing figure
    opt.axpos = []; %axis position
end
xall = opt.xall;
xseg = opt.xseg;
yconst = opt.yconst;
ix = opt.ix;
ylimtype = opt.ylimtype;
yroomfac = opt.yroomfac;
xmark = opt.xmark;
xln = opt.xln;
tsp = opt.tsp;
col = opt.col;
lst = opt.lst;
mkr = opt.mkr;
titlein = opt.titlein;
pthgif = opt.pthgif;
gifvis = opt.gifvis;
hfg = opt.hfg;
axpos = opt.axpos;
minsampperseg = opt.minsampperseg;
maxnumts = opt.maxnumts;
maxnumxmark = opt.maxnumxmark;

dosqueeze = 1; %iof requested ix are discontiguous, squeeze and renumber indices (if you don't there will be separated regiones where discontiguous, which might be nice sometimes to mark discontinuity

fprintf("WARNING FUNCTION tsplt MOSTLY WORKS BUT IS STILL BEING WRITTEN" + newline)

for k = 1:numel(ts)
    if isduration(ts{k})
        ts{k} = seconds(ts{k});
    end
end

%% ORGANIZE ts

for k = 1:numel(ts)
    if isvector(ts{k})
        if iscolumn(ts{k})
            ts{k} = ts{k}';
        end
    end
end

x_is_index = 0;
if isempty(xall)
    if isscalar(ts)
        x_is_index = 1;
        if tsp
            x{1} = 1:size(ts{1},1);
            y{1} = transpose(ts{1});
        else
            x{1} = 1:size(ts{1},2);
            y{1} = ts{1};
        end
    else
        if mod(numel(ts),2)~=0
            error("if xall is empty, number ts inputs must be multiple of 2 (pairs of x and y, with any x allowed to be empty vector [])")
        end
        for k = 1:numel(ts)/2
            if isempty(ts{1+2*(k-1)})
                x_is_index = 1;
                if tsp
                    x{k} = 1:size(ts{2+2*(k-1)},1);
                else
                    x{k} = 1:size(ts{2+2*(k-1)},2);
                end
            else
                if tsp
                    x{k} = transpose(ts{1+2*(k-1)});
                else
                    x{k} = ts{1+2*(k-1)};
                end
            end
            if tsp
                y{k} = transpose(ts{2+2*(k-1)});
                % if size(x{k},1)~=size(y{k},1)
                %     error(sprintf("name-value argument xall is empty or not used, so positional arguments are interpreted as repeating xy pairs; " + newline + "each pair must match in size of 2nd dimension, but x and y in xy pair number " + num2str(k) + " do not match in size of their 2nd dimension"))
                % end
            else
                y{k} = ts{2+2*(k-1)};
                if size(x{k},2)~=size(y{k},2)
                    error(sprintf("name-value argument xall is empty or not used, so positional arguments are interpreted as repeating xy pairs; " + newline + "each pair must match in size of 2nd dimension, but x and y in xy pair number " + num2str(k) + " do not match in size of their 2nd dimension"))
                end
            end
        end
    end
else
    for k = 1:numel(ts)
        x{k} = xall;
        if tsp
            y{k} = transpose(ts{k});
        else
            y{k} = ts{k};
        end
    end
end


%% CHECK INPUTS

szone = cellfun(@(x) size(x,1), y);
if any(szone>1)
    multidim = 1;
else
    multidim = 0;
end

if multidim && xseg>1
    error("all ts must be vector timeseries if xseg is greater than 1 (at least one y timeseries is not singleton first dimension")
end

% if any(cellfun(@(x) size(x,1), x)>1)
%     error("all x timeseries must have singleton first dimension")
% end


if any(cellfun(@isstring, x)) || any(cellfun(@isstring, y))
    error("x and/or y contains a string, but shold be numeric, you may have misspelled a name-value argument or used the wrong term")
end
if isempty(pthgif)
    pthgif = pthauto(suffix='.gif', usetime=1, usefun=1);
end
if ~isempty(axpos) && isempty(hfg)
    error("must not pass axpos without hfg")
end
if isempty(axpos)
    if isempty(hfg)
        axpos = [0.1300 0.1100 0.7750 0.8150];
    else
        error("must pass axpos if you pass hfg")
    end
end


if isscalar(xseg)
    if mod(xseg,1)~=0 || xseg<1
        error("xseg input argument must be integer, if it is scalar")
    end
    xseg = linspace(0, 1, xseg+1); %x axis limits as fraction of total, since two x axes are plotted
    xseg = [xseg(1:end-1); xseg(2:end)];
end

if size(xseg, 1)==2 %this will fail to fix transposed (2,2) xseg, but keeping this check to avoid complexity
    xseg = xseg';
end

if isempty(hfg)
    dosave = 1;
    hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
else
    dosave = 1; %1 for now but eventually 0 here; not set up to save outside this function because of the loop, but that would be better
end

%% INERPOLATE TIMESERIES ONTO SAME RANGE

default_xtrue = 0;
if isempty(xall)
    szx = cellfun(@(x) size(x,2), x, 'UniformOutput', false);
    if ~isscalar(x) && ~isequal(szx{:}) %if user didnt pass in xall, and the x are not equal in length, interpolate them onto single x axis (0-1)
        xaxis_true_lims = [0 1];
        limx = axlim(x{:}, limtype='all', roomfac=0);
        x = rescale2(x, limx, xaxis_true_lims);
        for k = 1:numel(x)
            x{k} = interp1(1:numel(x{k}), x{k}, limx(1):limx(end), 'linear', 'extrap');
        end
    end
    for k = 1:numel(y)
        if tsp
            if size(x{k},1)~=size(y{k},1)
                y{k} = interp1(1:size(y{k},1), y{k}, linspace(1, size(y{k},1), numel(x{k})), 'linear');
            end
        else
            if size(x{k},2)~=size(y{k},2)
                y{k} = transpose(interp1(1:size(y{k},2), transpose(y{k}), linspace(1, size(y{k},2), numel(x{k})), 'linear'));
                y{k} = y{k}';
            end
        end
    end
else
    for k = 1:numel(y)
        if isempty(x{k}) || isempty(y{k})
            error("you passed an empty array as an x or y argument, but also passed name-value argument xall; delete the empty argument to use xall, since xall reinterprets all xy arguments as y, and applies xall to all of them; using an empty array is valid for x when you don't use xall because it sets x to 1:numel(y) for it's corresponding y")
        end
        if tsp
            error("")
        else
            if size(x{k},2)~=size(y{k},2)
                y{k} = transpose(interp1(1:size(y{k},2), transpose(y{k}), linspace(1, size(y{k},2), numel(x{k})), 'linear'));
                y{k} = y{k}';
            end
        end
        % y{k} = y{k};
    end
end

num_xy_pairs = numel(x);
numsamp = numel(x{1});

if tsp
    tdim = 1;
else
    tdim = 2;
end
if any(cellfun(@numel, x)~=numsamp) || any(cellfun(@(x) size(x,tdim), y)~=numsamp)
    error("after interpolation, all timeseries must match in length")
end
if ~all(cellfun(@isvector, x)) % || ~all(cellfun(@isvector, y)) %check this after all the manipulations, just to be sure
    error("all x-timeseries must be vectors")
end
if num_xy_pairs>maxnumts
    error("number timeseries (x-y pairs, counted after applying all input arguments) exceeds maxnumts")
end
if any(size(xseg, 1)>=cellfun(@numel, x)/minsampperseg)
    error(sprintf("you've requested an xseg that will only show " + num2str(minsampperseg) + " true samples (not interpolated samples) on each frame; if that's really what you want, change minsampperseg (default, or as name-value argument)"))
end


%% YLIM

if numel(yconst)>1
    yaxis_true_lims = yconst;
else
    yaxis_true_lims = [0 1];
end
lim = axlim(y, limtype=ylimtype, roomfac=yroomfac);
y = rescale2(y, lim, yaxis_true_lims);


%% INDEX

idx = [];
if ~isempty(ix)
    for k = 1:num_xy_pairs
        if numel(ix)==2
            idx = x{k}>ix(1) & x{k}<ix(2);
        else
            if x_is_index
                idx = indsmake(ix, indsall=numel(x{1})); %in this situation all x should be same length, so just reference x{1} (right??)
            else
                error("since x is not just an index, ix must be 2-element vector representing min and max x indices to plot")
            end
        end
        if sum(idx)==0
            error("ix is out of range for xy pair " + num2str(k))
        end
        if tsp
            if dosqueeze && any(diff(idx)>1)
                error("what do we do here?")
            else
                y{k} = y{k}(idx,:);
                x{k} = x{k}(idx,:);
            end
        else
            if dosqueeze && any(diff(idx)>1)
                x{k} = x{k}(:,1:numel(idx));
            else
                x{k} = x{k}(:,idx);
            end
            y{k} = y{k}(:,idx);
        end
    end
end

%% markx

[xmark,ymark] = xfeatproc(xmark, idx, x, y, num_xy_pairs, tsp);
[xln, ~] = xfeatproc(xln, idx, x, y, num_xy_pairs, tsp);

numxmark = max(numel(xmark), numel(xln));


%% STYLE

if isempty(col)
    col = brewermap(maxnumts, 'Dark2'); %i prefer to keep the color order constant, regardless of number of inputs (assuming user doesn't change maxnumts); another option is distinguishable_colors(maxnumts);
    col = col(1:num_xy_pairs,:);
    col2 = brewermap(numxmark, 'Pastel1'); %i prefer to keep the color order constant, regardless of number of inputs (assuming user doesn't change maxnumts); another option is distinguishable_colors(maxnumts);
    col2 = col2(1:numxmark,:);
end
col = checkspec(col, num_xy_pairs);
col2 = checkspec(col2, numxmark);
lst = checkspec(lst, num_xy_pairs);
mkr = checkspec(mkr, num_xy_pairs);



%% PLOT

maxnumplt = max(cellfun(@(x) size(x,1), y));
hax = axes(Parent=hfg, Position=axpos, XColor='k', YColor='k', Box='off');
fcnt = 0;
for fi = 1:size(xseg, 1)


    %%%% PLOT EVERYTHING FIRST %%%%

    hold(hax, 'on')
    % fcnt = 0; %why was this here?
    for k2 = 1:maxnumplt
        for k = 1:numel(x)

            if k2<=size(y{k},1)

                if k2==1
                    if tsp
                        hpl{k} = plot(hax, 1:numel(y{k}(1,:)), y{k}(1,:), Color=col{k}, LineStyle=lst{k}); %cell expansion of ts for any number of xy pairs
                    else
                        hpl{k} = plot(hax, x{k}, y{k}(1,:), Color=col{k}, LineStyle=lst{k}); %cell expansion of ts for any number of xy pairs
                    end
                    if ~isempty(cell2mat(cellflat(xmark))) && ~isempty(xmark{k})
                        hsc{k} = scatter(hax, xmark{k}{1}, ymark{k}{1}, 'filled', MarkerFaceColor=col2{1}, Marker=mkr{1}); %cell expansion of ts for any number of xy pairs
                    end
                    if ~isempty(cell2mat(cellflat(xln))) && ~isempty(xln{k})
                        hln{k} = xline(hax, xln{k}{1}, Color=col2{1}); %cell expansion of ts for any number of xy pairs
                    end
                    hax.XLim = [x{k}(1) x{k}(end)];
                    xlmcurr = hax.XLim; %change x lim on subsequent frames (if there are any)
                else
                    hpl{k}.YData = y{k}(k2,:);
                    if ~isempty(cell2mat(cellflat(xmark))) && ~isempty(xmark{k})
                        hsc{k}.YData = ymark{k}{k2};
                    end
                    if ~isempty(cell2mat(cellflat(xln))) && ~isempty(xln{k})
                        hln{k}.Value = xln{k}{k2};
                    end
                end

                %%%% LOOP OVER XSEG, ADJUSTING AXES IF NECESSARY, AND WRITING TO GIF IF REQUESTED %%%%

                xlmseg = range(xlmcurr) .* xseg(fi,:) + xlmcurr(1);
                hax.XLim = xlmseg;

                if isequal(yconst,1) || numel(yconst)>1
                    ylm1 = yaxis_true_lims; %[min(y{1}) max(y{1})];
                else
                    % error("something is wrong with this limit computation when constany_ylim==0, maybe only with nans")
                    if default_xtrue
                        % THIS WAS FOR WHEN X WAS SAMPLES RIGHT?
                        xrangenew1 = floor(hax.XLim(1)):ceil(hax.XLim(2));
                        xrangenew1(xrangenew1==0) = []; %remove 0 if it exists
                    else
                        xrangenew1 = find(x{1}>=hax.XLim(1) & x{1}<=hax.XLim(2));
                    end

                    %was this, but if not constant y, this can clip some ts, since it's only ts{1}
                    % ylm1 = [min(y{1}(xrangenew1), [], 'all', 'omitmissing') max(y{1}(xrangenew1), [], 'all', 'omitmissing')];

                    ylm1(1) = min(cellfun(@(x) min(x(xrangenew1), [], 'all', 'omitmissing'), y));
                    ylm1(2) = max(cellfun(@(x) max(x(xrangenew1), [], 'all', 'omitmissing'), y));

                end


                if all(isfinite(ylm1)) %why did i do this? nans from dividing by zero when rescaling?
                    if ylm1(1)~=ylm1(2) %in case segment is constant, just skip setting new scale
                        hax.YLim = [ylm1(1) - range(ylm1)*yroomfac, ylm1(2) + range(ylm1)*yroomfac];
                    end
                end

                hax.Title.String = strrep(titlein, '_', ' ');

            end

            if dosave && k==numel(x)
                fcnt = fcnt + 1;
                fig2gif(hfg, fcnt, pthgif)
            end

        end
    end
    hold(hax, 'off')

end


end

function spec = checkspec(spec, num)

vnm = inputname(1);
if ~iscell(spec)
    for k = 1:size(spec,1)
        spectmp{k} = spec(k,:);
    end
    spec = spectmp;
end
if isscalar(spec)
    spec = repelem(spec, num);
end
if numel(spec)~=num
    error(vnm + "must be length 1, 2, or num_xy_pairs")
end

end



function [xfeat,yfeat] = xfeatproc(xfeat, idx, x, y, num_xy_pairs, tsp)

if ~iscell(xfeat)
    xfeat = {{xfeat}}; %xmark must be cell of cell
end
numxmark = numel(xfeat);
for k = 1:numxmark
    if ~isempty(xfeat{k}) && ~iscell(xfeat{k})
        xfeat{k} = {xfeat{k}};
    end
end

if isscalar(xfeat)
    xfeat = repelem(xfeat, num_xy_pairs);
else
    if ~isequal(numxmark, num_xy_pairs)
        error("xmark must have same number of outer cells as xy pairs")
    end
end

yfeat = [];
for k = 1:num_xy_pairs
    if ~isempty(cell2mat(cellflat(xfeat{k}))) && ~isempty(xfeat{k})
        if isscalar(xfeat{k})
            if ~tsp
                xfeat{k} = repelem(xfeat{k}, size(y{k},1));
            end
        else
            if ~isequal(numel(xfeat{k}), size(y{k},1))
                error("xmark must have same number of outer cells as xy pairs")
            end
        end
        for m = 1:numel(xfeat{k})
            if tsp
                xref = linspace(min(xfeat{k}{m}), max(xfeat{k}{m}), numel(x{k})+1);
                xref = xref(1:end-1);
                tmp = interp1(xref, x{k}, xfeat{k}{m}(idx), 'linear', 'extrap'); %match mark to input x
                xfeat{k} = num2cell(tmp);
                yfeat{k}{m} = interp1(x{k}, y{k}(:,m), xfeat{k}{m}, 'nearest'); %then find corresponding y
            else
                tmp = interp1(x{k}, x{k}, xfeat{k}{m}, 'nearest'); %match mark to input x
                xfeat{k}{m} = tmp(~isnan(tmp));
                yfeat{k}{m} = transpose(interp1(x{k}, transpose(y{k}(m,:)), xfeat{k}{m}, 'nearest')); %then find corresponding y
            end
        end
    end
end

end