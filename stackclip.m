function stack = stackclip(stack, opt)

% clip by percentile (optionally ignore zeros, optionally rescale output to range 0-1

arguments
    stack
    opt.clip = [0 100] % (1,2) vector; bottom and top percentiles for clipping (adjusting contrast); to adjust contrast, this function rescales the image rather than adjusting image property CLim because
    opt.rs = 0 % 1 will rescale after clipping
    opt.skipzero = 0 % 1 will ignore zeros in computing percentiles
    opt.pthgif = ''; % path for plot
    opt.doplt (1,1) {mustBeMember(opt.doplt,[0,1]), mustBeNonempty} = 0 % 1 will do plot; requires double memory
end
clip = opt.clip;
rs = opt.rs;
skipzero = opt.skipzero;
pthgif = opt.pthgif;
doplt = opt.doplt;


if isequal(clip, -1)

    stack(stack<0) = 0; %if clip==-1, clip negatives to zero

else

    if clip(1)<0 || clip(2)>1 || clip(1)>=clip(2) || numel(clip)~=2 || ~isnumeric(clip)
        error("if not -1, clip must be 2 numbers, increasing, range 0-1")
    end
    numchan = size(stack,5);
    sz = size(stack);
    stack = reshape(stack, [], numchan);

    chan = 1;
    if clip(1)==-1
        minnew(chan) = 0;
    else
        minnew(chan) = quantile(stack(:,chan), clip(1), 1); %index minnew into chan in case you want to see these values for each channel
    end
    maxnew(chan) = quantile(stack(:,chan), clip(2), 1); %index maxnew into chan in case you want to see these values for each channel
    if skipzero
        if contains(class(stack), 'int')
            fprintf("WARNING, IN STACKCLIP, skipzero=1, AND STACK IS INTEGER TYPE; ZEROS MAY REPRESENT DATA (NOT MASK)")
        end
        idxz = stack(:,chan)==0;
    else
        idxz = [];
    end
    idx = stack(:,chan)<minnew(chan);
    stack(idx,chan) = minnew(chan);
    idx = stack(:,chan)>maxnew(chan);
    stack(idx,chan) = maxnew(chan);
    stack(idxz,chan) = 0;

    if numchan==2 %don't make single chan function for both channels because this can be big array and the indexing inside function will create large temporary variable
        chan = 2;
        if clip(1)==-1
            minnew(chan) = 0;
        else
            minnew(chan) = quantile(stack(:,chan), clip(1), 1); %index minnew into chan in case you want to see these values for each channel
        end
        maxnew(chan) = quantile(stack(:,chan), clip(2), 1); %index maxnew into chan in case you want to see these values for each channel
        if skipzero
            idxz = stack(:,chan)==0;
        else
            idxz = [];
        end
        idx = stack(:,chan)<minnew(chan);
        stack(idx,chan) = minnew(chan);
        idx = stack(:,chan)>maxnew(chan);
        stack(idx,chan) = maxnew(chan);
        stack(idxz,chan) = 0;
    end

    stack = reshape(stack, sz);

end

if rs
    stack = rescale(stack);
end


if doplt
    if isequal(clip, -1)
        clipstr = 'clipneg';
        dr = [0 1];
    else
        clipstr = strrep([num2str(clip(1)) '_' num2str(clip(2))], '.', 'p');
        dr = clip;
    end
    if isempty(pthgif)
        pthgif = pthauto(suffix=['_50equidistantframes_dr_' clipstr '_.gif'], usetime=1);
    end
    stackplt(stack, dmplt='yxz(t)', it=-50, dr=dr, pthgif=pthgif)
end
