function filt = linear_filter_1d(numsamp, filtnorm, doplots, varargin)


padlen = 5;

tau1 = varargin{1};
shift = varargin{2};
if nargin==5
    tau2 = 1; %dummy
    tc = 0; %dummy
elseif nargin==7
    tau2 = varargin{3};
    tc = varargin{4};
else
    error("need 5 or 7 inputs")
end


x = 0:numsamp-1; 


b1 = x./tau1^2.*exp(-x./tau1);
b1 = b1 / norm(vec(b1(:)),1);
tau2new = tau1+tau1*tau2;
b2 = x./tau2new^2.*exp(-x./tau2new);
b2 = b2 / norm(vec(b2(:)),1) * tc;

filt = b1-b2;

if doplots
    filtplot = filt / norm(vec(filt(:)),1) * filtnorm; %normalize by L1
    figure; plot(x, filtplot); hold on;
end

filt = [zeros(1, padlen) filt zeros(1, padlen)];
x = 0:length(filt)-1;

filt = spline(x+shift,filt,x);

filt = filt(padlen+1:end-padlen);
x = 0:length(filt)-1;

% filt = fraccircshift(filt,shift); %circshift with non-integer allowed, but this linear interp isn't differentiable 

filt = filt / norm(vec(filt(:)),1) * filtnorm; %normalize by L1

if doplots
    plot(x, filt);
end

end