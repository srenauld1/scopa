function std_out = weighted_circular_std(ang, w)
%
% function [mean_out std_out] = weighted_circular_std(ang, weights)
%
% return the weighted circular mean and standard devidation of a
% vector input of angles ang (in deg) where the reported mean is the
% weighted circular mean [0..360) computed using Kogan's algorithm [1].
%
% See circular_mean.m, weighted_circular_mean.m and description.txt
%
% Reference:
%
% [1] Lior Kogan "Circular Values Math and Statistics with C++11", (27 Apr 2013)
%     https://www.codeproject.com/Articles/190833/Circular-Values-Math-and-Statistics-with-Cplusplus (downloaded 1 Jul 2023)
%
% script calls weighted_circular_mean.m

% written by D.Long 31 Jul 2023 

% first compute the weighted circular mean
mean_out = weighted_circular_mean(ang, w);

% compute the absolute value of the minimum difference of two angles in deg
dif = 180-abs(180-abs(mod(ang-mean_out(1),360)));

% compute weighted standard deviation (error known to be zero mean)
if length(dif)>0
  std_out=sum(dif.^2.*w(:)')/sum(w(:));
  if std_out>0
    std_out=sqrt(std_out);
  end
else
  std_out=0;
end
