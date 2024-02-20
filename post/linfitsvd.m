% use svd to find best linear fit to function defined by stimulus and response;
% stim - (m,n) array for stimulus at m spatial points and n time points;
% resp - (1,n) array for response to stimulus;
% lnth - number of time points for linear fit;  if lnth<=n/(m+1), fit is unique;
% pvar - fraction of the data variance that the linear fit should account for;
%        if not 1.0, pvar eliminates smaller singular values from pseudoinverse;
% notc - if not [], data is not centered (mean not subtracted) before fitting;
% lfit - (m,lnth) array for the coefficients of the linear fit;
% invp - (m*lnth,n-lnth+1) array for the pseudoinverse of the fitting problem;
function [ lfit, invp, resppred ] = linfit_scopasvd( stim, resp, lnth, pvar, notc, respnorm )



doplots = 0;
if isempty(notc) || notc==0
    %stim = stim - mean(stim,2); %zero mean per "pixel"
    stim = stim - mean(stim(:)); %zero mean
    %stim = (stim - mean(stim(:))) / std(stim(:)); zero mean unit var
end

switch respnorm
    case 'rescale'
        resp = rescale(resp);
    case 'standnorm'
        resp = (resp - mean(resp(:))) / std(resp(:));
end

[ m, n ] = size( stim );
d = [ m*lnth; n-lnth+1 ];
a = zeros( d(1), d(2) );
for i = 1 : d(2)
    a(:,i) = reshape( flip(stim(:,i:i+lnth-1),2), [], 1 );
end
a = a.';
[ u, s, v ] = svd( a, 'econ' );
i = find(s);
t = s(i);
r = cumsum( t.*t );
p = find( 1/r(end)*r>=pvar, 1 );
r = zeros( size(s) );
r( i(1:p) ) = 1 ./ t(1:p);
invp = v * r.' * u';
respcrop = resp(lnth:end);
lfittmp = invp*respcrop.';
lfit = reshape( lfittmp, m, lnth );
resppred = a*lfittmp;

if doplots
    
    figure;
    scatter(respcrop, resppred);
    va = axis; % get current values
    lbnd = min( va(1:2:end) ); % lower limit
    ubnd = max( va(2:2:end) ); % uppper limit
    axis( [lbnd ubnd lbnd ubnd] );
    hold on;
    plot(respcrop,respcrop)

end

end
