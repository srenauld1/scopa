function daqinds = daqindsmake(frameon, t, usefbl, usefbf, numvol, numslice, numslice_withflyback, doplt, pthfigpre, maxtplot)

arguments
    frameon
    t
    usefbl
    usefbf
    numvol
    numslice
    numslice_withflyback
    doplt = 0
    pthfigpre = []
    maxtplot = 2;
end

% make imaging slice indices and imaging volume indices for resampling (aligning) daq timeseries with imaging 
% frameon is logical indicating when imaging frame is acquiring 
% frames have flyback lines, volumes have flyback frames, slices are frames mod numslice_withflyback, numslice is number slices without flyback


%%%%%%%% frame indices %%%%%%%%

frameinds = bin2ind(frameon);

numvol_daq = max(frameinds)/numslice_withflyback;

if numvol_daq~=numvol
    daq_underflow = numvol-numvol_daq;
    if daq_underflow>0
        if daq_underflow<1
            fprintf("number of volumes computed from daq frames does not match number of stack volumes reported in scanimage metadata; will proceed because it is less than one frame underflow" + newline)
        else
            error("number of volumes computed from daq frames is less than number of stack volumes reported in scanimage metadata; since there are more than one underflow frames, will not proceed" + newline)
        end
    else
        error("number of volumes computed from daq frames is greater than number of stack volumes reported in scanimage metadata; overflow should not occur" + newline)
    end
end
if frameinds(1) == 1
    sprintf("warning, first daq sample is during an imaging frame; disregard if you're running daq in background and daq record has been cropped to start when frame starts")
end


%%%%%%%% slice indices %%%%%%%%

if usefbl
    frameinds = assign_flyback(frameinds, t); %assign flyback lines the nearest frame index (ie recenter frame)
    sliceinds = mod(frameinds-1, numslice_withflyback)+1; %get one-indexed slice indices
else
    sliceinds = frameinds; %for clarity let's make a copy and not modify frameinds 
    sliceinds(sliceinds==0) = nan;
    sliceinds = mod(sliceinds-1, numslice_withflyback)+1; %get one-indexed slice indices
    sliceinds(isnan(sliceinds)) = 0;
end

stmp = sliceinds(sliceinds~=0);
if stmp~=numslice_withflyback
    error("final daq volume is not complete . . . is this a problem? if you don't care just comment out this error")
end

%%%%%%%% volume indices %%%%%%%%

volinds = sliceinds; %since we might use sliceinds let's make a copy and not modify sliceinds 
volinds(volinds==0) = nan; %replace zeros (if they exist) with nan, then . . .
volinds = fillmissing(volinds, 'nearest'); %fill in zeros (which are between slices in sliceinds if usefbl=0, and absent otherwise) to help define volume; for this, precision is not important, since it just fills in flyback lines (not frames, where precision is more important)
volinds(volinds>numslice) = 0;
volinds = bin2ind(logical(volinds));
if usefbf
    volinds = assign_flyback(volinds, t);  %assign flyback frames the nearest volume index (ie recenter volume)
else
    frameinds(sliceinds>numslice) = 0; %remove frame flyback in frameinds if usefbf=0
    sliceinds(sliceinds>numslice) = 0; %remove frame flyback in sliceinds if usefbf=0
end

vtmp = volinds(volinds~=0);
if vtmp(end)~=numvol
    error("number stack volumes in metadata does not match number recorded in daq")
end

if any(isnan([frameinds; sliceinds; volinds]))
    error("there should be no nans in any daqinds")
end

%%%%%%%% put output in struct %%%%%%%%

daqinds.frame = single(frameinds); %don't do uint16 for frameinds since they can exceeed 65535
daqinds.slice = uint16(sliceinds);
daqinds.vol = uint16(volinds);

%%%%%%%% plotting (optional) %%%%%%%%

if doplt
    if isduration(t)
        t = seconds(t);
    end
    t = t-t(1); %zero, just for plotting, so maxtplot works as intended
    kp = find(t<maxtplot);
    tsub = t(kp);
    figure;
    sgtitle( ['use flyback lines: ' num2str(usefbl), '; use flyback frames: ' num2str(usefbf)])
    subplot(311);
    plot(tsub, daqinds.frame(kp));
    title(['daqinds.frame for first ' num2str(numel(tsub)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(daqinds.frame) max(daqinds.frame)]) ])
    subplot(312);
    plot(tsub, daqinds.slice(kp));
    title(['daqinds.slice for first ' num2str(numel(tsub)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(daqinds.slice) max(daqinds.slice)]) ])
    subplot(313);
    plot(tsub, daqinds.vol(kp))
    title(['daqinds.vol for first ' num2str(numel(tsub)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(daqinds.vol) max(daqinds.vol)]) ])
    figsuffix = 'daqinds_.png';
    if isempty(pthfigpre)
        pthfig = pthauto(suffix=figsuffix, usetime=0);
    else
        pthfig = [pthfigpre figsuffix];
    end
    saveas(gca, pthfig, 'png');
end


end


function inds = assign_flyback(inds, t)
kp = inds==0;
inds(kp) = interp1(t(~kp),inds(~kp),t(kp), 'nearest', 'extrap'); %extrap for the final samples
end

