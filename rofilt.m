function y = rofilt(x, N, p)

%adapted from RankOrderFilter to take integer input, and run a little faster

%RankOrderFilter Rank order filter for 1D signals
%  y = RankOrderFilter(x, window, thd) runs a rank-order filtering of order
%  N on x. y is the same size as x. To avoid edge effects, the x is expanded
%  by repeating the first and the last samples N/2 times. if x is a matrix,
%  RankOrderFilter operates along the columns of x.
%
%  Rank-order filter calculates the p'th percentile of the data on a N
%  sized window round each point of x. p can be a number between 0 and 100.
%
%  When p is equal to 50, the output of this function will be the same as 
%  MATLAB's MEDFILT1(x,N); however, RankOrderFilter is almost always much
%  faster and needs less memory. 
%
%  When p is close to 0 (or to 100), a RankOrderFilter calculates an
%  approximate lower (or upper) envlope of the signal.
%
%  Copyright 2008, Arash Salarian
%  mailto://arash.salarian@ieee.org
%

if ndims(x)>2
    error("x must be 1d or 2d")
end

classx = class(x);

[m, n] = size(x);
y = zeros(m,n,classx);

if rem(N,2) == 1
    k = (N-1)/2;
else
    k = N/2;
end

tmp = ones(k,1,classx);

for i=1:n
    X = [x(1,i)*tmp; x(:,i); x(end,i)*tmp];
     for j=1:m
         y(j,i) = prctilevec(X(j:j+N-1), p);
    end
end







