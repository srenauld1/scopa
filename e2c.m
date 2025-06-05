function z = e2c(x, m, doplt)

arguments
    x
    m = 32
    doplt = 0
end

b = linspace( -pi, pi, m+1 );
b = b(1:m);
p = polyshape( x );
[ u, v ] = centroid( p );
a = atan2( x(:,2)-v, x(:,1)-u );
[ a, i ] = sort( a );
z = interp1( a, x(i,:), b, 'linear', 'extrap' );
y = [ u, v ];

if doplt
    hfg = figure;  hold on;  axis equal;
    plot( x(:,1), x(:,2) );
    for i = 1 : m
        plot( [y(1),z(i,1)], [y(2),z(i,2)], 'k' );
    end
    fig2gif(hfg)
end

end