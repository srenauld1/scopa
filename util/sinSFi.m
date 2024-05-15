function s = sinSFi(fqs,n,method,P)
% sine wave with specified frequencies at each interval
%
% s = sinRFi(fqs,n)
% s = sinRFi(...,method,P)
%
% fqs: a vector of frequencies in order of their appearance
% n:   signal length in samples
% method: optional input that determins if each frequency is realized for a
%   fixed amount of time ('time') or a fixed number of periods
%   ('period'). If 'time', P is the fixed time, if 'period', P is the
%   number of periods. Defaults are 2*pi and 1 respectively.
%
% s: sine wave output
%
% EXAMPLE:
% fqs = [2 5 10 0.5 1 0.1]; % vector of frequencies
% n = 2e3; % number of samples
% st = sinSFi(fqs,n,'time',2*pi);
% sp = sinSFi(fqs,n,'period',1);
% figure
% subplot(2,1,1); plot(st,'-b.'); title('fixed time: 2\pi')
% subplot(2,1,2); plot(sp,'-b.'); title('fixed period: 1')
%
%
% %%% ZCD March 2013 %%%
%
% check inputs
fsize = size(fqs);
if all(fsize>1) || length(fsize)>2
    error('fqs must be a vector')
elseif fsize(2)>1
    fqs = fqs'; % reorient when needed
end
if nargin==2
    method = 'period';
end
if nargin==4
    if P<=0 || ~isreal(P)
        error('P must be real and greater than 0')
    end
end
    
    
% number of frequencies (periods)
nf = length(fqs);
npf = ceil(n/nf); % samples per frequency
switch method
    case 'time'
        if nargin<4, P=2*pi; end
        
        % time vectors
        tm = repmat(linspace(0,(P-P/npf),npf),[nf 1]);
        % frequency vectors
        vf = (tm.*repmat(fqs,[1 npf]))';
        % generate wave
        s = sin(vf(:));
    case 'period'
        if nargin<4, P=1; end
        
        % period lengths
        pls = (2*pi*P)./fqs;
        % samples per period
        npp = ceil(pls./sum(pls)*n);
        % frequency vector
        vf = arrayfun(@(a,b) ones(1,a)*b,npp,fqs,'unif',false);
        vf = [vf{:}];
        % times
        vt = arrayfun(@(a,b) linspace(0,b-(b/a),a),npp,pls,'unif',false);
        vt = [vt{:}];
        % generate wave
        s = sin(vf.*vt);
    otherwise
        error(['undefined method: ' method])
end
% resample signal to specified number of samples
s = interp1(s,1:n);
