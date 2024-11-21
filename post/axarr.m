function ax = axarr(layout, opt)

%{
find xy positions and xy extents of subplots
can split figure into sectors along x or y (not both yet); sectors can have different subplot arrangements
each cell element of argument layout defines each sector's layout
if layout cell element is 1d, it denotes [numrow, numcol] for that sector
if layout cell element is 2d, 3d, 4d, 5d, or 6d, axarr assumes it is an image stack
the image stack dims are assumed to be (y,x,z,t,p,c), and axarr will maximally fill sector area with z images, each size (y,x)
note, for image stack layout style, there may be more than z subplot positions, if the space cannot be evenly tiled into z subplots; it is up to user to choose which of the available subplots to use  
(i.e., will preserve images' aspect ratios, and maximize their size, given the sector area)
output ax is struct, where each element is sector, and each field is x or y position or extent
sectors are ordered top to bottom (if splitdim 'y') or left to right (if split dim 'x')
fields in subfield rm are x and y positions in row-major order (default matlab subplot order); 
'colmaj' subfield is for column-major subplot order
xy order:
    if ydir='down', subplot indices are ordered left to right top to bottom
    if ydir='up', subplot indices are ordered left to right bottom to top
    use entries in subfield colmaj, with ydir 'down', to have subplot indices order top to bottom left to right
    use entries in subfield colmaj, with ydir 'up', to have subplot indices order bottom to top left to right 
    there is not an option for right-to-left order
%}

arguments
    layout %cell array of vectors; cell element n (vector n), if length 2, denotes number of rows and columns, respectively, for sector n; if not length 2, it is considered a stack of images, and by default k images are arranged, where k is size of 3rd dim 
    opt.marginax double = 0.03 %scalar or vector; element n denotes x and y margins between axes in sector n; if scalar, while numrow and numcol are vector, will apply scalar to all sectors; no effect if there is only one plot
    opt.marginfg double = 0.03 %scalar; margins of entire figure (not sectors)
    opt.splitdim char = 'x' %'x', or 'y', denoting whether sector(s) created by split along x or y axis; if y, first element of layout refers to the bottom sector (direction is up)
    opt.splitfrac double = []  %scalar or vector denoting each sector's fraction of splitdim extent; if num_sectors==1, default is 1; if num_sectors>1, default if is even split among num_sectors
    opt.ydir char = 'down' %'up' or 'down'; direction of y position indices
    opt.stackjust = 'none' %'none', 'center', 'minimize'
end
marginax = opt.marginax;
marginfg = opt.marginfg;
splitdim = opt.splitdim;
splitfrac = opt.splitfrac;
ydir = opt.ydir;
stackjust = opt.stackjust;


if ~iscell(layout)
    layout = {layout};
end

if isempty(splitfrac)
    if numel(layout)==1
        splitfrac = 1;
    else
        splitfrac = repelem(1/numel(layout), numel(layout)-1);
    end
end

if numel(splitfrac)~=numel(layout) && numel(splitfrac)~=numel(layout)-1  
    error("splitfrac must be length layout, or length layout -1 ");
end

num_sectors = numel(layout);
if num_sectors==1 && splitfrac~=1
    error("for single sector, don't pass splitfrac argument, or pass value of 1")
end
if isempty(marginfg) %handle empty argument for marginfg (not handled in arguments block above)
    marginfg = 0.03;
end
if numel(marginfg)==1
    marginfg = repelem(marginfg, num_sectors); %repeat singleton marginfg to match num_sectors
end
if num_sectors~=numel(marginfg)
    error("margins fig length must be 1 or numel(num_sectors)")
end
if isempty(marginax) %handle empty argument for marginax (not handled in arguments block above)
    marginax = repelem(0.03, num_sectors);
end
if numel(marginax)==1 && num_sectors~=1 %repeat singleton marginax to match num_sectors
    marginax = repelem(marginax, num_sectors);
end

for k = 1:num_sectors
    if numel(layout{k})==2
        subplot_layout_struct(k).x = layout{k}(2);
        subplot_layout_struct(k).y = layout{k}(1);
    else
        if ndims(layout{k})>6
            error("error, you've passed an array with more than 6 dimensions")
        end
        subplot_layout_struct(k).stack = [size(layout{k}, 1) size(layout{k}, 2) size(layout{k}, 3)];
    end
    splitfracfull(k).x = 1;
    splitfracfull(k).y = 1;
    margins_fig_full(k).x = [marginfg(k) marginfg(k)];
    margins_fig_full(k).y = [marginfg(k) marginfg(k)];
    if num_sectors>1
        if k==1
            margins_fig_full(k).(splitdim) = [marginfg(k) 0];
        elseif k==num_sectors
            margins_fig_full(k).(splitdim) = [0 marginfg(k)];
        else
            margins_fig_full(k).(splitdim) = [0 0];
        end
    end
    if k==num_sectors && num_sectors>1 && numel(splitfrac)==num_sectors-1 %fill in final splitfrav if user omitted it
        splitfracfull(k).(splitdim) = 1-sum(splitfrac);
    else
        splitfracfull(k).(splitdim) = splitfrac(k);
    end
end
startpos.x = 0;
startpos.y = 0;

for k = 1:num_sectors

    [ax(k), maxpos] = arrange_subplots_onesector(subplot_layout_struct(k), margins_fig_full(k), marginax(k), splitfracfull(k), startpos);

    if isfield(subplot_layout_struct(k), 'stack') && ~strcmp(stackjust, 'none') %center 'stack' subplot group
        if strcmp(stackjust, 'center')
            justfac = 2;
        elseif strcmp(stackjust, 'minimize')
            justfac = 1;
        end
        ax(k).x = ax(k).x + (ax(k).x(1)+(maxpos.x-ax(k).x(1))/justfac) - (ax(k).x(1)+ax(k).w(end)/justfac); %actual x center plus goal x center minus actual x center
        ax(k).y = ax(k).y + (ax(k).y(1)+(maxpos.y-ax(k).y(1))/justfac) - (ax(k).y(1)+ax(k).h(end)/justfac); %actual y center plus goal y center minus actual y center
    end

    startpos.(splitdim) = maxpos.(splitdim);

end

for k = 1:num_sectors

    if strcmp(ydir, 'down')
        ax(k).y = flip(ax(k).y); %make y order top to bottom
    end

    [p,q] = meshgrid(ax(k).x, ax(k).y); %transform into 2d array
    tmp = [p(:) q(:)];

    ax(k).x = tmp(:,1);
    ax(k).y = tmp(:,2);

    ax(k).marginax = marginax(k);
    ax(k).marginfg = marginfg(k);
    
    ax(k).numsubplot = numel(ax(k).x);
    [~, uu1, uu2] = unique(ax(k).x);
    ax(k).numrow = numel(find(uu2==uu1(1)));
    ax(k).numcol = numel(uu1);

    ax(k).sector_index = k;

    for m = 1:numel(ax(k).y) %put output in column-major subfield (non default for matlab)
        ax(k).colmaj.x(m,1) = ax(k).x(m);
        ax(k).colmaj.y(m,1) = ax(k).y(m);
    end
    for m = 1:numel(ax(k).colmaj.y) %make row-major version (don't put in subfield since it's matlab default)
        [ci, ri] = ind2sub([ax(k).numcol, ax(k).numrow], m);
        sit = sub2ind([ax(k).numrow, ax(k).numcol], ri, ci);
        ax(k).x(m,1) = ax(k).colmaj.x(sit);
        ax(k).y(m,1) = ax(k).colmaj.y(sit);
    end

end

ax = structsort(ax);


end


function [ax, maxpos] = arrange_subplots_onesector(subplot_layout_struct, marginfg, marginax, splitfrac, startpos)

fn = fieldnames(subplot_layout_struct);
for fi = 1:numel(fn)
    if ~isempty(subplot_layout_struct.(fn{fi}))
        if strcmp(fn{fi}, 'stack')
            [ax, maxpos] = arrange_subplots_stack(subplot_layout_struct.(fn{fi}), marginfg, marginax, splitfrac, startpos);
        else
            if strcmp(fn{fi}, 'x')
                [ax.x, ax.w, maxpos.(fn{fi})] = arrange_subplots_onedim(subplot_layout_struct.(fn{fi}), marginfg.(fn{fi}), marginax, splitfrac.(fn{fi}), startpos.(fn{fi}));
            elseif strcmp(fn{fi}, 'y')
                [ax.y, ax.h, maxpos.(fn{fi})] = arrange_subplots_onedim(subplot_layout_struct.(fn{fi}), marginfg.(fn{fi}), marginax, splitfrac.(fn{fi}), startpos.(fn{fi}));
            end
        end
    end
end


end


function [position, extent_multiples, maxpos] = arrange_subplots_onedim(subplot_layout_struct, marginfg, marginax, splitfrac, startpos)

minpos = 0+startpos+marginfg(1);
maxpos = 1*splitfrac+startpos-marginfg(2);

position = linspace( minpos, maxpos, subplot_layout_struct+1 ) ;
position = position(1:end-1); %position including labels (outer position)

extent_with_labels = maxpos - position(end); %extent including labels
extent_smallest = extent_with_labels - marginax;

if extent_smallest<=0
    error("cannto have negative extent")
end

for k = 1:numel(position)
    extent_multiples(k) = extent_smallest*k+(k-1)*marginax;
end

end

function [ax, maxpos] = arrange_subplots_stack(subplot_layout_struct, marginfg, marginax, splitfrac, startpos)

sectorwidth = 1*splitfrac.x - marginfg.x(1) - marginfg.x(2);
sectorheight = 1*splitfrac.y - marginfg.y(1) - marginfg.y(2);
numsubplot = subplot_layout_struct(3);
aspect_subplot = subplot_layout_struct(2) / subplot_layout_struct(1);

numrow = 1;
while numrow>0
    numcol = ceil(numsubplot/numrow);
    htmp = (sectorheight - (numrow - 1)*marginax)/numrow;
    wtmp = htmp*aspect_subplot;

    if numcol * wtmp + (numcol - 1)*marginax > sectorwidth
        numrow = numrow + 1;
    else
        break
    end
end

numcolumns2 = 1;
while numcolumns2>0
    numrow2 = ceil(numsubplot/numcolumns2);
    wtmp2 = (sectorwidth - (numcolumns2 - 1)*marginax)/numcolumns2;
    htmp2 = wtmp2/aspect_subplot;

    if numrow2 * htmp2 + (numrow2 - 1)*marginax > sectorheight
        numcolumns2 = numcolumns2 + 1;
    else
        break
    end
end

if wtmp2*htmp2>wtmp*htmp %overwrite if 2nd loop found larger area subfigures
    wtmp = wtmp2;
    htmp = htmp2;
    numrow = numrow2;
    numcol = numcolumns2;
end


minposx = 0 + startpos.x + marginfg.x(1);
maxposx = minposx + sectorwidth; %sectorwidth computed above, already accounts for marginfg

minposy = 0 + startpos.y + marginfg.y(1);
maxposy = minposy + sectorheight; %sectorwidth computed above, already accounts for marginfg

xpos = minposx : wtmp+marginax : maxposx;
xpos = xpos(1:numcol);

ypos = minposy : htmp+marginax : maxposy;
ypos = ypos(1:numrow);

for k = 1:numel(xpos)
    wids(k) = wtmp*k+(k-1)*marginax;
end
for k = 1:numel(ypos)
    hgts(k) = htmp*k+(k-1)*marginax;
end

% if numsubplot==1 %center 'stack' subplot group
%     xpos = xpos + (xpos+(maxposx-xpos)/2) - (xpos+wids/2); %actual x center plus goal x center minus actual x center
%     ypos = ypos + (ypos+(maxposy-ypos)/2) - (ypos+hgts/2); %actual y center plus goal y center minus actual y center
% end

maxpos.x = maxposx;
maxpos.y = maxposy;
ax.x = xpos;
ax.w = wids;
ax.y = ypos;
ax.h = hgts;

end

