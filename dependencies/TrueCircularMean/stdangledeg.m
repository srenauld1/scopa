function [mean_out mean_out2 std_out] = stdangledeg(in, dim, sens);
%
% function [mean_out mean_out2 std_out] = stdangledeg(in <,dim <,sens>>);
%
% calculates the mean and standard of a set of angles (in degrees) using
% conventional sine/cosine approach
%
% in is a vector or matrix of angles (in degrees)
% mean_out is the trigonometric mean of the angles along the dimension dim
% mean_out2 is the mean of the difference between trig mean and angles in
% std_out is the standard deviation of the difference angles
%
% dim is the optional dimension indicator. if dim is not specified, first 
% non-singleton dimension used
%
% sens it the sensitivity factor used to determine how close the magnitude
% of the complex representations of the angles is to zero before being
% called zero with nan returned for the direction value. Default sensitivity
% value is 1e-12, which works for most cases. Override by specifying sens value.
%
% The circular standard deviation std_out is given here by
%
%   std_out=sqrt( Sum distance_function(a_i,mean_out)^2 / N - mean_out2^2)
%            i
%
% where N is the number of angles, mean_out is the conventional angle mean 
% given by
% 
% mean_out = atan2(sum(sin(a*pi/180)), sum(cos(a*pi/180))) -equivalent to-
% mean_out = atan2(mean(sin(a*pi/180)), mean(cos(a*pi/180))) -or-
% mean_out = angle(exp(j*a*pi/180)) (in Matlab)
%
% and mean_out2 is the std mean error given by
%
%   mean_out2=Sum distance_function(a_i,mean_out) / N
%
% Note that this differs from common approximations for the angle
% standard deviation used by others [1],[2]. The signed distance function
% is given by
%
% distance_function(a_i,m)=mod(m-a_i+180,360)-180
%
% References:
%
% [1] Mori, Y., 1986. Evaluation of Several Single-Pass Estimators of the 
%     Mean and the Standard Deviation of Wind Direction. J Climate Appl. 
%     Metro., Vol. 25, pp. 1387-1397.
% [2] Yamartino, R.J., 1984. A Comparison of Several "Single-Pass" Estimators
%     of the Standard Deviation of Wind Direction". Journal of Climate and 
%     Applied Meteorology. Vol. 23(9), pp. 1362-1366. 
%     doi:10.1175/1520-0450(1984)023<1362:ACOSPE>2.0.CO;2.

% Written by D.G. Long, 07 Jul 2023 

% check input args
if nargin<3
  sens = 1e-12;
end
if nargin<2
  ind = min(find(size(in)>1));
  if isempty(ind) % scalar case
    out = in;
    return
  end
  dim = ind;
end

% first compute trigonometric mean angle
Ein = exp(i*in*pi/180);
mid = mean(Ein,dim,'omitnan');
mean_out = real(atan2(imag(mid),real(mid))*180/pi);
mean_out(abs(mid)<sens) = nan;

% compute signed angular difference of angle and the trigonometric mean in deg
% in the range [-180..180]
dif = mod(in-mean_out+180,360)-180;

% compute mean of angular difference from trig mean
mean_out2 = mean(dif,dim,'omitnan');

% compute standard deviation of angular difference from trig mean
std_out = std(dif,1,dim,'omitnan'); % use 1/N rather than 1/(N-1)
