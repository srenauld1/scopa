function [idx, idxvol, idxslice, idxframe] = daqidxmake(frameon, t, opt)

%{

make imaging slice indices and imaging volume indices for resampling (aligning) daq timeseries with imaging
frameon is logical vector indicating when imaging frame is acquiring
frames have flyback lines, volumes have flyback frames, slices are frames mod numslice_withflyback, numslice is number slices without flyback
output idx is struct holding idxvol, idxslice, idxframe; also output each separately, for convenience

%}

arguments
    frameon %logical vector, 1 when frame is acquiring
    t %timestamps
    opt.usefbl = 0 %1 to include flyback lines
    opt.usefbf = 0 %1 to include flyback frames
    opt.pthstack = [] %path to stack, can use this to find numvol, numslice, and numslice_withflyback (instead of passing them in)
    opt.numvol = [] %number volumes
    opt.numslice = [] %number slices (z planes)
    opt.numslice_withflyback = [] %number slices (z planes) including flyback frames
    opt.doplt = 0 %plot figure
    opt.pthfig = [] %path to save figure
    opt.maxtplot = 2; %max number of t samples to include in plot
end
usefbl = opt.usefbl;
usefbf = opt.usefbf;
pthstack = opt.pthstack;
numvol = opt.numvol;
numslice = opt.numslice;
numslice_withflyback = opt.numslice_withflyback;
doplt = opt.doplt;
pthfig = opt.pthfig;
maxtplot = opt.maxtplot;

if isempty(numvol) && isempty(numslice) && isempty(numslice_withflyback)
    if isempty(pthstack)
        error("must pass in pthstack if numvol, numslice, and numslice_withflyback are empty")
    else
        md = mdsild(pthstack);
        numslice_withflyback = md.numslice_withflyback;
        numslice = md.numslice;
        numvol = md.numvol;
    end
else
    if isempty(numvol) || isempty(numslice) || isempty(numslice_withflyback)
        error("must pass in numvol, numslice, and numslice_withflyback, or pass in none of them and pass in nonempty pthstack")
    end
end


%%%%%%%% frame indices %%%%%%%%

idxframe = bin2ind(frameon);

numvol_daq = max(idxframe)/numslice_withflyback;

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
if idxframe(1) == 1
    sprintf("warning, first daq sample is during an imaging frame; disregard if you're running daq in background and daq record has been cropped to start when frame starts")
end


%%%%%%%% slice indices %%%%%%%%

if usefbl
    idxframe = assign_flyback(idxframe, t); %assign flyback lines the nearest frame index (ie recenter frame)
    idxslice = mod(idxframe-1, numslice_withflyback)+1; %get one-indexed slice indices
else
    idxslice = idxframe; %for clarity let's make a copy and not modify idxframe
    idxslice(idxslice==0) = nan;
    idxslice = mod(idxslice-1, numslice_withflyback)+1; %get one-indexed slice indices
    idxslice(isnan(idxslice)) = 0;
end

stmp = idxslice(idxslice~=0);
if stmp~=numslice_withflyback
    error("final daq volume is not complete . . . is this a problem? if you don't care just comment out this error")
end

%%%%%%%% volume indices %%%%%%%%

idxvol = idxslice; %since we might use idxslice let's make a copy and not modify idxslice
idxvol(idxvol==0) = nan; %replace zeros (if they exist) with nan, then . . .
idxvol = fillmissing(idxvol, 'nearest'); %fill in zeros (which are between slices in idxslice if usefbl=0, and absent otherwise) to help define volume; for this, precision is not important, since it just fills in flyback lines (not frames, where precision is more important)
idxvol(idxvol>numslice) = 0;
idxvol = bin2ind(logical(idxvol));
if usefbf
    idxvol = assign_flyback(idxvol, t);  %assign flyback frames the nearest volume index (ie recenter volume)
else
    idxframe(idxslice>numslice) = 0; %remove frame flyback in idxframe if usefbf=0
    idxslice(idxslice>numslice) = 0; %remove frame flyback in idxslice if usefbf=0
end

vtmp = idxvol(idxvol~=0);
if vtmp(end)~=numvol
    error("number stack volumes in metadata does not match number recorded in daq")
end

if any(isnan([idxframe; idxslice; idxvol]))
    error("there should be no nans in any idx")
end

%%%%%%%% put output in struct %%%%%%%%

idx.frame = single(idxframe); %don't do uint16 for idxframe since they can exceeed 65535
idx.slice = uint16(idxslice);
idx.vol = uint16(idxvol);

%%%%%%%% plotting (optional) %%%%%%%%

if doplt
    if isduration(t)
        t = seconds(t);
    end
    t = t-t(1); %zero, just for plotting, so maxtplot works as intended
    kp = find(t<maxtplot);
    subt = t(kp);
    figure;
    sgtitle( ['use flyback lines: ' num2str(usefbl), '; use flyback frames: ' num2str(usefbf)])
    subplot(311);
    plot(subt, idx.frame(kp));
    title(['idx.frame for first ' num2str(numel(subt)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(idx.frame) max(idx.frame)]) ])
    subplot(312);
    plot(subt, idx.slice(kp));
    title(['idx.slice for first ' num2str(numel(subt)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(idx.slice) max(idx.slice)]) ])
    subplot(313);
    plot(subt, idx.vol(kp))
    title(['idx.vol for first ' num2str(numel(subt)) ' daq samples (' num2str(maxtplot) ' seconds); [min, max] (all samples): ' mat2str([min(idx.vol) max(idx.vol)]) ])
    figsuffix = 'idx_.png';
    if isempty(pthfig)
        pthfig = pthauto(suffix=figsuffix, usetime=0);
    end
    saveas(gca, pthfig, 'png');
end


end


function idx = assign_flyback(idx, t)
kp = idx==0;
idx(kp) = interp1(t(~kp),idx(~kp),t(kp), 'nearest', 'extrap'); %extrap for the final samples
end

