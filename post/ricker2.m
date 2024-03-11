function [rw,t] = ricker2(f,n,dt,t0)

T = dt*(n-1);
t = 0:dt:T;
tau = t-t0;
rw = (1-tau.*tau*f^2*pi^2).*exp(-tau.^2*pi^2*f^2);
