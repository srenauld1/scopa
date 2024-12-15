% use svd to find best linear fit to function defined by indv and depv;
% indv - (n,m) array for independent variable, n samples, m features, 
%        where m = d*l, where d is number features and l is number samples into the past;
% depv - (n,1) array for dependent variable, n samples;
% pvar - fraction of the data variance that the linear fit should account for;
%        if not 1.0, pvar eliminates smaller singular values from pseudoinverse;
% ft - (m,lnth) array for the coefficients of the linear fit, ;
% invp - (m*lnth,n-lnth+1) array for the pseudoinverse of the fitting problem;
function ft = objective_svd( indv, depv, pvar)

[ u, s, v ] = svd( indv, 'econ' );
i = find(s);
t = s(i);
r = cumsum( t.*t );
p = find( 1/r(end)*r>=pvar, 1 );
r = zeros( size(s) );
r( i(1:p) ) = 1 ./ t(1:p);
pseudoinv = v * r.' * u';
ft = pseudoinv*depv;

end
