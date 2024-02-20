

function out = nonlinearity_softplus(x, a, b, c, d, k)


out = c * log( 1 + exp(a*x + b) ).^k + d;


end