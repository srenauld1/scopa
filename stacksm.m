function stack = stacksm(stack, opt)

% uses matlab function smoothdata to smooth any number of stack dimensions, independently, in sequence;
% currently does not suport multidimensional smoothing (e.g. with a 2d gaussian, etc)
% can applying filtering methods in sequence (e.g. gaussian smooth, then moving median)
% can prevent ram from exceeding input ram

arguments
    stack
    opt.method = 'gaussian'
    opt.smlenpx = []
    opt.smlensec = []
    opt.imrate = []
    opt.memthr = 1e9 %work in progress, leave as 0; operate in batches to prevent ram from exceeding input stack size (since smoothdata converts from int)
end
method = opt.method;
smlenpx = opt.smlenpx;
smlensec = opt.smlensec;
imrate = opt.imrate;
memthr = opt.memthr;

if ndims(stack)<4
    error("stack must be 4d or 5d")
end

if ~iscell(method)
    method = {method};
end

if ~isempty(smlensec) && isempty(imrate)
    error("if smlensec is nonempty, must input imrate")
end

if isempty(smlenpx)
    smlenpx = [0 0 0];
else
    if numel(smlenpx)~=3 || ~isvector(smlenpx)
        error("smlenpx must be 3-element vector")
    end
end

if isempty(smlensec)
    smlensec = 0;
else
    if ~isscalar(smlensec)
        error("smlensec must be scalar")
    end
end

smlensamp = smlensec*imrate;
smlen = [smlenpx smlensamp];
dtype = class(stack);

numchan = size(stack, 5);

if any(strcmp(dtype, {'single', 'double'}))
    memthr = 0;
end

varsz = whos('stack');
numseg = ceil(varsz.bytes/memthr);
numframes = size(stack,4);

for m = 1:numel(method)
    for c = 1:numchan %do one channel at a time to keep temporary double output from crashing matlab if stack is big 2-channel
        for w = 1:numel(smlen)
            if smlen(w) %in case stack is large, looping over each dimension and converting dtype as we go
                if isfinite(numseg) && numseg>1 %if stack is larger than memthr, convert to single (double or single required for mtimes, which is by far fastest way to do this part) in segments to use less ram, since respnew, even though it is also single precision, is generally much smaller than stack
                    seglen = ceil(numframes/numseg);
                    k = 0;
                    while true
                        k = k+1;
                        if w==4
                            idx = [1:seglen]+(seglen-ceil(smlen(w)))*(k-1);
                        else
                            idx = [1:seglen]+seglen*(k-1);
                        end
                        idx(idx>numframes) = [];
                        if isempty(idx)
                            break
                        end
                        if any(strcmp(dtype, {'single', 'double'}))
                            stack(:,:,:,idx,c) = smoothdata(stack(:,:,:,idx,c), w, method{m}, smlen(w));
                        else
                            stack(:,:,:,idx,c) = stacktype(smoothdata(stack(:,:,:,idx,c), w, method{m}, smlen(w)), dtype);
                        end
                    end
                else
                    if any(strcmp(dtype, {'single', 'double'}))
                        stack(:,:,:,:,c) = smoothdata(stack(:,:,:,:,c), w, method{m}, smlen(w));
                    else
                        stack(:,:,:,:,c) = stacktype(smoothdata(stack(:,:,:,:,c), w, method{m}, smlen(w)), dtype);
                    end
                end
            end
        end
    end
end