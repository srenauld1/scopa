function [resprs, angrs] = compassrs(resp, ang, numangrs, maxangrs, doplt, pthgif)

% resp should be roi x time, and the rois represent positions on a circle,
% and their sampling may not be uniform, so this function resamples to make it uniform, 
% so later the PVA can be computed with less bias
% range(ang) cannot exceed 2pi

arguments
    resp %neural response, (roi,time), each roi represents an angle of a circle
    ang {mustBeVector} %vector of angles represented by each roi; length must equal size(resp,1)
    numangrs = 16 %number angles in resampled output
    maxangrs = 8 %max number resolvable ("unaliased") angles in resampled output (ie 1/maxangrs is highest frequency you wish to capture in output)
    doplt = 0 %do plots
    pthgif = []
end

fprintf("resampling compass from " + num2str(numel(ang)) + " rois to " + num2str(numangrs) + " rois, with 2pi domain (whether it's 4pi PB or not)" + newline)

if range(ang)>2*pi
    error("in compassrs range(ang) cannot exceed 2pi")
end
if numangrs>numel(ang)
    error("in compassrs numangrs must not exceed numel(ang)")
end
if numangrs<2*maxangrs
    error("fs should be at least double fmax")
end
if iscolumn(ang)
    ang = ang(:)'; %ang must be row vector
end

fs = numangrs/(2*pi);
fmax = maxangrs/(2*pi);

[ang, idx] = sort(ang);
resp = resp(idx,:);
ang = [ang-2*pi ang ang+2*pi]; %bookend with the entire circle before calling resample; since ang is sorted, this makes angle monotonic increasing (not wrapped)
resp = repmat(resp, [3 1]);

[p,q] = rat(fs/fmax);
[resprs, angrs] = resample(resp, ang, fs, p, q);
kp = ang>-pi & ang<pi;
ang = ang(kp);
resp = resp(kp,:);
kp = angrs>-pi & angrs<pi;
angrs = angrs(kp);
resprs = resprs(kp,:);

if doplt
    nfr = 30;
    if isempty(pthgif)
        pthgif = pathauto(suffix='discont.gif', usetime=1);
    end
    hfg = figure;
    hax = axes(Parent=hfg);
    fcnt = 0;
    for k = round(linspace(1,size(resp,2), nfr))
        fcnt = fcnt+1;
        if fcnt==1
            hpl1 = plot(hax, ang, resp(:,k));
            hold on;
            hpl2 = plot(hax, angrs, resprs(:,k));
        else
            hpl1.YData = resp(:,k);
            hpl2.YData = resprs(:,k);
        end
        fig2gif(hfg, fcnt, pthgif)
    end

    pthgif = strrep(pthgif, 'discont', 'cont');
    nfr = 60;

    hfg = figure;
    hax = axes(Parent=hfg);
    pltinds = round(size(resp,2)/2:(size(resp,2)/2)+nfr);
    pltinds(pltinds>size(resp,2)) = [];
    fcnt = 0;
    for k = pltinds
        fcnt = fcnt+1;
        if fcnt==1
            hpl1 = plot(hax, ang, resp(:,k));
            hold on;
            hpl2 = plot(hax, angrs, resprs(:,k));
        else
            hpl1.YData = resp(:,k);
            hpl2.YData = resprs(:,k);
        end
        fig2gif(hfg, fcnt, pthgif)
    end
end



