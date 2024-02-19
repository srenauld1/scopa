function [axx, axy, axw, axh] = cx_arrange_subplots(numrows, numcolumns, margins_fig, margins_subfig)


minx = 0+margins_subfig+margins_fig;
maxx = 1-margins_subfig-margins_fig;

axx = linspace( minx, maxx, numcolumns+1 ) ;
axx = axx(1:end-1); %xposition including labels (outer position)

axwlab = maxx - axx(end); %width including labels
axw = axwlab - margins_subfig;


miny = 0+margins_subfig+margins_fig;
maxy = 1-margins_subfig-margins_fig;

axy = linspace( miny, maxy, numrows+1 ) ;
axy = axy(1:end-1); %xposition including labels (outer position)

axhlab = maxy - axy(end); %width including labels
axh = axhlab - margins_subfig;


axy = flip(axy); %make y order top to bottom (first epoch is on top)


[p,q] = meshgrid(axx, axy);
tmp = [p(:) q(:)];

axx = tmp(:,1);
axy = tmp(:,2);


end