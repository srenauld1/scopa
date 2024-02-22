function [mean_out std_out] = circular_std(ang)
%
% function [mean_out std_out] = circular_std(ang)
%
% return the circular mean and standard devidation of a vector input of 
% angles ang (in deg) where the reported mean is the circular mean [0..360)
% computed using Kogan's algorithm [1].  See circular_mean.m
%
% The absolute value of the distance_function for two angles a_i and m
% can be written as
%
%  |distance_function(a_i,m)|=180-abs(180-abs(mod(a_i-m,360))).
%
% The true circular standard deviation S is given by
%
%  S=sqrt( Sum distance_function(a_i,Mt)^2 / N)           (5)
%           i
%
% where Mt is the true circular mean and N is the number of angles in the
% set {a_i}. Note that this differs from common approximations for the angle
% standard deviation used by others [2],[3]. In computing the circular 
% standard deviation, this code uses the definition in Eq. (5)
%
% reference:
% [1] Lior Kogan "Circular Values Math and Statistics with C++11", (27 Apr 2013)
%     https://www.codeproject.com/Articles/190833/Circular-Values-Math-and-Statistics-with-Cplusplus (downloaded 1 Jul 2023)
% [2] Mori, Y., 1986. Evaluation of Several Single-Pass Estimators of the 
%     Mean and the Standard Deviation of Wind Direction. J Climate Appl. 
%     Metro., Vol. 25, pp. 1387-1397.
% [3] Yamartino, R.J., 1984. A Comparison of Several "Single-Pass" Estimators
%     of the Standard Deviation of Wind Direction". Journal of Climate and 
%     Applied Meteorology. Vol. 23(9), pp. 1362-1366. 
%     doi:10.1175/1520-0450(1984)023<1362:ACOSPE>2.0.CO;2.
%
% script calls circular_mean.m

% written by D.Long 07 Jul 2023 
% revised by D.Long 31 Jul 2023 

if nargin<1
  error('*** requires at least one input');
end

% first compute circular mean
mean_out = circular_mean(ang);

% compute the absolute value of the minimum difference of two angles in deg
dif = 180-abs(180-abs(mod(ang-mean_out(1),360)));

% compute standard deviation (mean is already known to be zero)
if length(dif)>1
  std_out=sqrt(sum(dif.^2)/length(dif));
else
  std_out=0;
end
