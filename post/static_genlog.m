
function out = static_genlog(x, C, Q, varargin)

if nargin==8
    B = varargin{1};
    A = varargin{2};
    K = varargin{3};
    V = varargin{4};
    M = varargin{5};
else
    error("currently (temporarily) written to accept 8 inputs")
end

out = A + ( (K - A) ./ ( C + Q * exp( -B * (x-M) ) .^ 1/V ) );

end


