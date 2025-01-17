
function y = prctilevec(x, k)

% k'th percentile of x. 
% similar to MATLAB's prctile function, but faster for integer vector 
% when called with dim argument 'all' 
% taken from RankOrderFilter by
% Copyright 2008, Arash Salarian
% mailto://arash.salarian@ieee.org

if ~isvector(x)
    error("x must be vector")
end
if ~iscolumn(x)
    x = x';
end

x = sort(x);
n = size(x,1);

p = 1 + (n-1) * k / 100;

if p == fix(p)
    y = x(p);
else
    r1 = floor(p); r2 = r1+1;
    y = x(r1) + (x(r2)-x(r1)) * k / 100;
end