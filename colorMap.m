% make colormap that interpolates a sequence of colors;
% c - (m,3) array defining m colors;
% n - number of colors for the interpolated colormap;
% r - (n,3) array for the interpolated colormap;
function r = colorMap(c,n)
    r = interp1( c, linspace(1,size(c,1),n) );
end

