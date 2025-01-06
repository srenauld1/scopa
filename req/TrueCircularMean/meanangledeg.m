function out = meanangledeg(in,dim,sens);
%
% function out = meanangledeg(in <,dim <,sens>>);
%
% calculates the mean of a set of angles (in degrees) using
% conventional sine/cosine approach. 
%
% in is a vector or matrix of angles (in degrees)
% out is the mean of these angles along the dimension dim (in degrees)
%
% optional dimension indicator. if dim is not specified, first 
% non-singleton dimension used
%
% A sensitivity factor is used to how close the magnitude of the complex 
% representations of the angles is to zero before being called zero with
% nan returned for value. Default sensitivity value is 1e-12, which works 
% for most cases. Override by specifying sens value.
%
% written by D.G. Long, 11-27-17 

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

in = exp(i*in*pi/180);
mid = mean(in,dim,'omitnan');
out = real(atan2(imag(mid),real(mid))*180/pi);
out(abs(mid)<sens) = nan;
