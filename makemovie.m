% make a matlab movie from a 3d array and a colormap;
% a - (m,n,p) array of p (m,n) data planes;
% c - if not [], (256,3) colormap array;  default: greyscale;
% b - if not [], (1,2) array of data values at ends of c,
%     by default equal to the minimum and maximum values of a;
% f - if not [], fileroot for avi file to store the movie;
% v - (1,p) array of structures, one for each matlab movie frame;
function v = makemovie( a, c, b, f )
    [m,n,p] = size(a);
    if isempty(c)
        c = colorMap( [[0,0,0];[1,1,1]], 256 );
    end
    if isempty(b)
        b = [min(a,[],'all'),max(a,[],'all')];
    end
    if ~isempty(f)
        vf = VideoWriter( string(f)+".avi", 'Uncompressed AVI' );
        open( vf );
    end
    d = interp1( linspace(double(b(1)),double(b(2)),256).', c, double(a), ...
        'nearest', 'extrap' );
    v(p) = struct( 'cdata', [], 'colormap', [] );
    for i = 1 : p
        v(i) = im2frame( squeeze(d(:,:,i,:)) );
        if ~isempty(f)
            writeVideo( vf, v(i) );
        end
    end
    if ~isempty(f)
        close( vf );
    end
end
