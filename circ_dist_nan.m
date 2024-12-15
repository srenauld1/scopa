function r =  circ_dist_nan(x,y)
%
% r = circ_dist(alpha, beta)
%   Pairwise difference x_i-y_i around the circle computed efficiently.
%
%   Input:
%     alpha      sample of linear random variable
%     beta       sample of linear random variable or one single angle
%
%   Output:
%     r       matrix with differences

% adapted to deal with nans from 
% Circular Statistics Toolbox for Matlab
% Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html


nanindsx = isnan(x);
nanindsy = isnan(y);
x(nanindsx) = 0;
y(nanindsy) = 0;

if size(x,1)~=size(y,1) && size(x,2)~=size(y,2) && length(y)~=1
  error('Input dimensions do not match.')
end

r = angle(exp(1i*x)./exp(1i*y));

r(nanindsx | nanindsy) = nan;