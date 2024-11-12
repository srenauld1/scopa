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
    opt.ylimtype = 'all'
    opt.yroomfac {mustBeNumeric} = 0.1 %percentage of y range to pad above and below
    opt.col = []; %color,  length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.lst {mustBeText} = '-' %linestyle, length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.mkr {mustBeText} = 'none' %marker,  length 1 if same for all, or length 2 if one for first, another for all subsequent, or length matching number plots
    opt.minsampperseg = 5 %min samples per xseg
    opt.maxnumts = 8 %max number timeseries
    opt.titlein {mustBeText} = '' %title
    opt.pthgif {mustBeText} = '' %figure save path
    opt.gifvis {mustBeText} = 'on'
    opt.hfg = [] %can pass figure handle to add to existing figure
    opt.axpos = []; %axis position
end
xall = opt.xall;
xseg = opt.xseg;
yconst = opt.yconst;
ylimtype = opt.ylimtype;
yroomfac = opt.yroomfac;
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


if isempty(xall)
    if mod(numel(ts),2)~=0
        error("if xall is empty, number ts inputs must be multiple of 2 (pairs of x and y, with any x allowed to be empty vector [])")
    end
    for k = 1:numel(ts)/2
        x{k} = ts{1+2*(k-1)};
        y{k} = ts{2+2*(k-1)};
        if numel(x{k})~=numel(y{k})
            error(sprintf("name-value argument xall is empty or not used, so positional arguments are interpreted as repeating xy pairs; " + newline + "each pair must match in length, but x and y in xy pair number " + num2str(k) + " do not match in length"))
        end
    end
else
    for k = 1:numel(ts)
        x{k} = xall;
        y{k} = ts{k};
    end
end


%% CHECK INPUTS


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

%% PARSE X AND Y INPUT DATA

default_xtrue = 0;
if isempty(xall)
        % if k==1
        %     if isempty(x{k})
        %         default_xtrue = 1;
        %         xtrue = 1:numel(y{k});
        %     else
        %         xtrue = x{k};
        %     end
        % end
        % if isempty(x{k})
        %     x{k} = linspace(1, numel(y{k}), numel(xtrue)); %for k==2, this will not change anything, but anything after might
        %     y{k} = interp1(1:numel(y{k}), y{k}, x{k}, 'linear');
        % else
        %     x{k} = linspace(1, numel(y{k}), numel(xtrue)); %for k==2, this will not change anything, but anything after might
        %     y{k} = interp1(1:numel(y{k}), y{k}, x{k}, 'linear');
        % end
        xaxis_true_lims = [0 1];
        limx = axlim(x, limtype='all', roomfac=0);
        x = rescale_to_range(x, limx, xaxis_true_lims);
    for k = 1:numel(y)
        y{k} = interp1(1:numel(y{k}), y{k}, linspace(1, numel(y{k}), numel(xtrue)), 'linear');
        tsx{k} = x{k};
        tsy{k} = y{k};
    end
else
    for k = 1:numel(y)
        if isempty(x{k}) || isempty(y{k})
            error("you passed an empty array as an x or y argument, but also passed name-value argument xall; delete the empty argument to use xall, since xall reinterprets all xy arguments as y, and applies xall to all of them; using an empty array is valid for x when you don't use xall because it sets x to 1:numel(y) for it's corresponding y")
        end
        if numel(xall)~=numel(y{k})
            xnew = linspace(1, numel(y{k}), numel(xall));
            y{k} = interp1(1:numel(y{k}), y{k}, xnew, 'linear');
        end
        tsx{k} = xall;
        tsy{k} = y{k};
    end
end

num_xy_pairs = numel(tsx);

numsamp = numel(tsx{1});
if any(cellfun(@numel, tsx)~=numsamp) || any(cellfun(@numel, tsy)~=numsamp)
    error("after interpolation, all timeseries must match in length")
end
if ~all(cellfun(@isvector, tsx)) || ~all(cellfun(@isvector, tsy)) %check this after all the manipulations, just to be sure
    error("all timeseries must be vectors")
end
if num_xy_pairs>maxnumts
    error("number timeseries (x-y pairs, counted after applying all input arguments) exceeds maxnumts")
end
if any(size(xseg, 1)>=cellfun(@numel, tsx)/minsampperseg)
    error(sprintf("you've requested an xseg that will only show " + num2str(minsampperseg) + " true samples (not interpolated samples) on each frame; if that's really what you want, change minsampperseg (default, or as name-value argument)"))
end


if isempty(col)
    col = brewermap(maxnumts, 'Dark2'); %i prefer to keep the color order constant, regardless of number of inputs (assuming user doesn't change maxnumts); another option is distinguishable_colors(maxnumts);
    col = col(1:num_xy_pairs,:);
end
col = checkspec(col, num_xy_pairs);
lst = checkspec(lst, num_xy_pairs);
mkr = checkspec(mkr, num_xy_pairs);

if numel(yconst)>1
    yaxis_true_lims = yconst;
else
    yaxis_true_lims = [0 1]; 
end

lim = axlim(tsy, limtype=ylimtype, roomfac=yroomfac);

tsy = rescale_to_range(tsy, lim, yaxis_true_lims);


%% PLOT EVERYTHING FIRST

hax = axes(Parent=hfg, Position=axpos, XColor='k', YColor='k', Box='off');
hold(hax, 'on')
for k = 1:num_xy_pairs
    hpl{k} = plot(hax, tsx{k}, tsy{k}, Color=col{k}, LineStyle=lst{k}, Marker=mkr{k}); %cell expansion of ts for any number of xy pairs
end
hold(hax, 'off')

%% LOOP OVER XSEG, ADJUSTING AXES IF NECESSARY, AND WRITING TO GIF IF REQUESTED

for fi = 1:size(xseg, 1)

    if fi==1 %plot on first frame, change x lim on subsequent frames (if there are any)
        xlmcurr = hax.XLim;
    end

    xlmseg = xlmcurr(2) .* xseg(fi,:) + xlmcurr(1);
    hax.XLim = xlmseg;

    if isequal(yconst,1) || numel(yconst)>1
        ylm1 = yaxis_true_lims; %[min(tsy{1}) max(tsy{1})];
    else
        % error("something is wrong with this limit computation when constany_ylim==0, maybe only with nans")
        if default_xtrue
            % THIS WAS FOR WHEN X WAS SAMPLES RIGHT?
            xrangenew1 = floor(hax.XLim(1)):ceil(hax.XLim(2));
            xrangenew1(xrangenew1==0) = []; %remove 0 if it exists
        else
            xrangenew1 = find(tsx{1}>=hax.XLim(1) & tsx{1}<=hax.XLim(2));
        end
        ylm1 = [min(tsy{1}(xrangenew1), [], 'all', 'omitmissing') max(tsy{1}(xrangenew1), [], 'all', 'omitmissing')];

    end


    if all(isfinite(ylm1)) %why did i do this? nans from dividing by zero when rescaling?
        if ylm1(1)~=ylm1(2) %in case segment is constant, just skip setting new scale
            hax.YLim = [ylm1(1) - range(ylm1)*yroomfac, ylm1(2) + range(ylm1)*yroomfac];
        end
    end
   
    hax.Title.String = strrep(titlein, '_', ' ');

    if dosave
        fig2gif(hfg, fi, pthgif)
    end

end


end

function spec = checkspec(spec, num_xy_pairs)

vnm = inputname(1);
if ~iscell(spec)
    for k = 1:size(spec)
        spectmp{k} = spec(k,:);
    end
    spec = spectmp;
end
if numel(spec)==1
    spec = repelem(spec, num_xy_pairs);
end
if numel(spec)~=num_xy_pairs
    error(vnm + "must be length 1, 2, or num_xy_pairs")
end

end


