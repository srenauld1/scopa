function [y, t] = exponential_filter( n, dt, a1, tau1, t0, b )

% single exponential function
%n: number samples
%dt: sample period
% a1: "amplitude"
% t0:  when x = t0, y = a1 + b
% tau1: "time constant" - when x increases by tau1, y decreases by factor a1 * e
% b: as x --> inf, y --> b

T = dt*(n-1);
t = 0:dt:T;
tshift = t-t0;

y = a1 * exp(-1 / tau1 * tshift) + b;

end
