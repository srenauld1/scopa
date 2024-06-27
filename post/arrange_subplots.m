function ax = arrange_subplots(subplot_layout, margins_subplot, margins_fig, splitdim, splitfrac, y_order)

% find xy positions and extents of subplots
% can split figure into sectors along x or y (not both yet); sectors can have different subplot arrangements
% each cell element of argument subplot_layout defines each sector's layout
% if subplot_layout cell element is 1d, it denotes [numrows, numcolumns] for that sector
% if subplot_layout cell element is 2d, 3d, 4d, 5d, or 6d, arrange_subplots assumes it is an image stack
% the image stack dims are assumed to be (y,x,z,t,p,c), and arrange_subplots will maximally fill sector area with z images, each size (y,x)
% note, for image stack layout style, there may be more than z subplot positions, if the space cannot be evenly tiled into z subplots; it is up to user to choose which of the available subplots to use  
% (i.e., will preserve images' aspect ratios, and maximize their size, given the sector area)
% output ax is struct, where each element is sector, and each field is x or y position or extent
% sectors are ordered top to bottom (if splitdim 'y') or left to right (if split dim 'x')
% fields in subfield rowmajor are x and y positions in row-major order; 'colmajor' subfield is for column major order
% use entries in subfield rowmajor and y_order 'down' to have subplot indices order left to right top to bottom
% use entries in subfield rowmajor and y_order 'up' to have subplot indices order left to right bottom to top
% use entries in subfield colmajor and y_order 'down' to have subplot indices order top to bottom left to right
% use entries in subfield colmajor and y_order 'up' to have subplot indices order bottom to top left to right 
% there is not an option for right to left 

arguments
    subplot_layout %cell array of vectors; cell element n (vector n), if length 2, denotes number of rows and columns, respectively, for sector n; if length
    margins_subplot double = 0.03 %scalar or vector; element n denotes x and y margins between subplots in sector n; if scalar, while numrows and numcolumns are vector, will apply scalar to all sectors
    margins_fig double = 0.03 %scalar; margins of entire figure (not sectors)
    splitdim char = 'x' %'x', or 'y', denoting whether sector(s) created by split along x or y axis
    splitfrac double = tern(numel(subplot_layout)==1, 1, repelem(1/numel(subplot_layout), numel(subplot_layout)-1)) %scalar or vector denoting each sector's fraction of splitdim extent; if num_sectors==1, default is 1; if num_sectors>1, default if is even split among num_sectors
    y_order char = 'down' %'up' or 'down'; direction of y position indices
end

if ~iscell(subplot_layout)
    subplot_layout = {subplot_layout};
end

if numel(splitfrac)~=numel(subplot_layout) && numel(splitfrac)~=numel(subplot_layout)-1  
    error("splitfrac must be length subplot_layout, or length subplot_layout -1 ");
end

num_sectors = numel(subplot_layout);
if num_sectors==1 && splitfrac~=1
    error("for single sector, don't pass splitfrac argument, or pass value of 1")
end
if isempty(margins_fig) %handle empty argument for margins_fig (not handled in arguments block above)
    margins_fig = 0.03;
end
if numel(margins_fig)==1
    margins_fig = repelem(margins_fig, num_sectors); %repeat singleton margins_fig to match num_sectors
end
if num_sectors~=numel(margins_fig)
    error("margins fig length must be 1 or numel(num_sectors)")
end
if isempty(margins_subplot) %handle empty argument for margins_subplot (not handled in arguments block above)
    margins_subplot = repelem(0.03, num_sectors);
end
if numel(margins_subplot)==1 && num_sectors~=1 %repeat singleton margins_subplot to match num_sectors
    margins_subplot = repelem(margins_subplot, num_sectors);
end



for j = 1:num_sectors
    if numel(subplot_layout{j})==2
        subplot_layout_struct(j).x = subplot_layout{j}(2);
        subplot_layout_struct(j).y = subplot_layout{j}(1);
    else
        if ndims(subplot_layout{j})>6
            error("error, you've passed an array with more than 6 dimensions")
        end
        subplot_layout_struct(j).stack = [size(subplot_layout{j}, 1) size(subplot_layout{j}, 2) size(subplot_layout{j}, 3)];
    end
    splitfracfull(j).x = 1;
    splitfracfull(j).y = 1;
    margins_fig_full(j).x = [margins_fig(j) margins_fig(j)];
    margins_fig_full(j).y = [margins_fig(j) margins_fig(j)];
    if num_sectors>1
        if j==1
            margins_fig_full(j).(splitdim) = [margins_fig(j) 0];
        elseif j==num_sectors
            margins_fig_full(j).(splitdim) = [0 margins_fig(j)];
        else
            margins_fig_full(j).(splitdim) = [0 0];
        end
    end
    if j==num_sectors && num_sectors>1 && numel(splitfrac)==num_sectors-1 %fill in final splitfrav if user omitted it
        splitfracfull(j).(splitdim) = 1-sum(splitfrac);
    else
        splitfracfull(j).(splitdim) = splitfrac(j);
    end
end
startpos.x = 0;
startpos.y = 0;

% if strcmp(splitdim,'y')
%     subplot_layout = flip(subplot_layout);% hack to make subplot_layout cell indices order top to bottom 
%     subplot_layout = flip(subplot_layout);% hack to make subplot_layout cell indices order top to bottom 
%     subplot_layout = flip(subplot_layout);% hack to make subplot_layout cell indices order top to bottom 
% end

for j = 1:num_sectors

    [ax(j), maxpos] = arrange_subplots_onesector(subplot_layout_struct(j), margins_fig_full(j), margins_subplot(j), splitfracfull(j), startpos);
    startpos.(splitdim) = maxpos.(splitdim);

end

for j = 1:num_sectors

    if strcmp(y_order, 'down')
        ax(j).yp = flip(ax(j).yp); %make y order top to bottom
    end

    [p,q] = meshgrid(ax(j).xp, ax(j).yp); %transform into 2d array
    tmp = [p(:) q(:)];

    ax(j).xp = tmp(:,1);
    ax(j).yp = tmp(:,2);

    ax(j).margins_subplot = margins_subplot(j);
    ax(j).margins_fig = margins_fig(j);
    
    ax(j).numsubplot = numel(ax(j).xp);
    [~, uu1, uu2] = unique(ax(j).xp);
    ax(j).numrows = numel(find(uu2==uu1(1)));
    ax(j).numcolumns = numel(uu1);

    ax(j).sector_index = j;

    for si = 1:numel(ax(j).yp) %make row-major version of same 
        [ci, ri] = ind2sub([ax(j).numcolumns, ax(j).numrows], si);
        sit = sub2ind([ax(j).numrows, ax(j).numcolumns], ri, ci);
        ax(j).rowmajor.xp(si,1) = ax(j).xp(sit);
        ax(j).rowmajor.yp(si,1) = ax(j).yp(sit);
        ax(j).colmajor.xp(si,1) = ax(j).xp(si);
        ax(j).colmajor.yp(si,1) = ax(j).yp(si);
    end

end

ax = rmfield(ax, 'xp');
ax = rmfield(ax, 'yp');

ax = orderfields_recursive(ax);


end


function [ax, maxpos] = arrange_subplots_onesector(subplot_layout_struct, margins_fig, margins_subplot, splitfrac, startpos)

fn = fieldnames(subplot_layout_struct);
for fi = 1:numel(fn)
    if ~isempty(subplot_layout_struct.(fn{fi}))
        if strcmp(fn{fi}, 'stack')
            [ax, maxpos] = arrange_subplots_stack(subplot_layout_struct.(fn{fi}), margins_fig, margins_subplot, splitfrac, startpos);
        else
            [ax.([fn{fi} 'p']), ax.([fn{fi} 'e']), maxpos.(fn{fi})] = arrange_subplots_onedim(subplot_layout_struct.(fn{fi}), margins_fig.(fn{fi}), margins_subplot, splitfrac.(fn{fi}), startpos.(fn{fi}));
        end
    end
end


end


function [position, extent_multiples, maxpos] = arrange_subplots_onedim(subplot_layout_struct, margins_fig, margins_subplot, splitfrac, startpos)

minpos = 0+startpos+margins_fig(1);
maxpos = 1*splitfrac+startpos-margins_fig(2);

position = linspace( minpos, maxpos, subplot_layout_struct+1 ) ;
position = position(1:end-1); %position including labels (outer position)

extent_with_labels = maxpos - position(end); %extent including labels
extent_smallest = extent_with_labels - margins_subplot;

if extent_smallest<=0
    error("cannto have negative extent")
end

for k = 1:numel(position)
    extent_multiples(k) = extent_smallest*k+(k-1)*margins_subplot;
end

end

function [ax, maxpos] = arrange_subplots_stack(subplot_layout_struct, margins_fig, margins_subplot, splitfrac, startpos)

sectorwidth = 1*splitfrac.x - margins_fig.x(1) - margins_fig.x(2);
sectorheight = 1*splitfrac.y - margins_fig.y(1) - margins_fig.y(2);
numsubplot = subplot_layout_struct(3);
aspect_subplot = subplot_layout_struct(2) / subplot_layout_struct(1);

numrows = 1;
while numrows>0
    numcolumns = ceil(numsubplot/numrows);
    hgt = (sectorheight - (numrows - 1)*margins_subplot)/numrows;
    wid = hgt*aspect_subplot;

    if numcolumns * wid + (numcolumns - 1)*margins_subplot > sectorwidth
        numrows = numrows + 1;
    else
        break
    end
end

numcolumns2 = 1;
while numcolumns2>0
    numrows2 = ceil(numsubplot/numcolumns2);
    wid2 = (sectorwidth - (numcolumns2 - 1)*margins_subplot)/numcolumns2;
    hgt2 = wid2/aspect_subplot;

    if numrows2 * hgt2 + (numrows2 - 1)*margins_subplot > sectorheight
        numcolumns2 = numcolumns2 + 1;
    else
        break
    end
end

if wid2*hgt2>wid*hgt %overwrite if 2nd loop found larger area subfigures
    wid = wid2;
    hgt = hgt2;
    numrows = numrows2;
    numcolumns = numcolumns2;
end


minposx = 0 + startpos.x + margins_fig.x(1);
maxposx = minposx + sectorwidth; %sectorwidth computed above, already accounts for margins_fig

minposy = 0 + startpos.y + margins_fig.y(1);
maxposy = minposy + sectorheight; %sectorwidth computed above, already accounts for margins_fig

xpos = minposx : wid+margins_subplot : maxposx;
xpos = xpos(1:numcolumns);

ypos = minposy : hgt+margins_subplot : maxposy;
ypos = ypos(1:numrows);

for k = 1:numel(xpos)
    wids(k) = wid*k+(k-1)*margins_subplot;
end
for k = 1:numel(ypos)
    hgts(k) = hgt*k+(k-1)*margins_subplot;
end

maxpos.x = maxposx;
maxpos.y = maxposy;
ax.xp = xpos;
ax.xe = wids;
ax.yp = ypos;
ax.ye = hgts;

end

