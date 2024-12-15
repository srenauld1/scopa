function [filtall, t] = filter_bank(T,dt,f,t0,f2,tc,t02,type,doplt)

n = (T/dt)+1;
t = 0:dt:T;
tshift = t-t0;
t02 = t02/dt;
% f = f/dt;
useless_shift = 0;
filtnorm = 1;
padlen = 20;
tmppad = zeros(1, length(tshift)+padlen*2);
filtall = zeros(length(type),length(tshift));

for i = 1:length(type)
    tmp = [];

    switch type{i}

        case 'ricker'
            %ricker (f is bandwidth)
            tmp = (1-tshift.*tshift*f^2*pi^2).*exp(-tshift.^2*pi^2*f^2);

        case 'gaus'
            %gaussian(f is bandwidth)
            tmp = 1/(sqrt(2*pi)*f)*exp(-1*tshift.^2/(2*f^2));

        case 'exp'
            %exponential (f is time constant here, not bandwidth)
            tmp = tshift./f^2.*exp(-tshift./f);

        case 'diff'
            %difference of exponentials (f is time constant here, not bandwidth)
            tmp1 = tshift./f^2.*exp(-tshift./f);
            tmp1 = tmp1 / norm(tmp1(:),1);
            f2new = f+f*f2;
            tmp2 = tshift./f2new^2.*exp(-tshift./f2new);
            tmp2 = tmp2 / norm(vec(tmp2(:)),1) * tc;
            tmp = tmp1-tmp2;
        case 'deriv'
            %difference of exponentials (f is time constant here, not bandwidth)
            tmp = tshift./f^2.*exp(-tshift./f);
            tmp = [0 diff(tmp)];
            

        case 'bspline0'
            %orthonormal bsplines
            doplotsbspline = 0;
            nnew = n - 2;
            [tmp, ~, ~] = make_bspline(nnew, doplotsbspline);

        case 'bspline1'
            %orthonormal bsplines
            doplotsbspline = 0;
            nnew = n - 2;
            [~, tmp, tmp2] = make_bspline(nnew, doplotsbspline);

    end

    tmp = tmp / norm(tmp(:),1);

    if doplt
        tmpplot = tmp / norm(tmp(:),1) * filtnorm; %normalize by L1
        figure; plot(tshift, tmpplot); hold on;
    end

    tmppad(padlen+1:end-padlen) = tmp;
    tnew = 0:length(tmppad)-1;
    tmppad = spline(tnew+t02,tmppad,tnew);
    filt = tmppad(padlen+1:end-padlen);
    filt = filt / norm(filt(:),1) * filtnorm; %normalize by L1

    if doplt
        plot(tshift, filt);
    end   

    filtall(i,:) = filt;

end


