% use svd to find best linear fit to function defined by stimulus and response;
% stim - (m,n) array for stimulus at m spatial points and n time points;
% resp - (1,n) array for response to stimulus;
% lnth - number of time points for linear fit;  if lnth<=n/(m+1), fit is unique;
% pvar - fraction of the data variance that the linear fit should account for;
%        if not 1.0, pvar eliminates smaller singular values from pseudoinverse;
% notc - if not [], data is not centered (mean not subtracted) before fitting;
% lfit - (m,lnth) array for the coefficients of the linear fit;
% invp - (m*lnth,n-lnth+1) array for the pseudoinverse of the fitting problem;
function ft = fit_svd( stim, resp, pvar)

[ u, s, v ] = svd( stim, 'econ' );
i = find(s);
t = s(i);
r = cumsum( t.*t );
p = find( 1/r(end)*r>=pvar, 1 );
r = zeros( size(s) );
r( i(1:p) ) = 1 ./ t(1:p);
invp = v * r.' * u';
ft = invp*resp;

end
