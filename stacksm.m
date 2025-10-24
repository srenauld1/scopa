function stack = stacksm(stack, opt)

%{

uses matlab function smoothdata to smooth any number of stack dimensions, independently, in sequence;
currently does not suport multidimensional smoothing (e.g. smoothing with a 2d gaussian, etc)
can applying filtering methods in sequence (e.g. movmedian smooth, then gaussian smooth, for example)
can prevent ram from exceeding input ram

%}

arguments
    stack
    opt.method = 'gaussian' %smoothing method for smoothdata function; can be sequence of multiple (cell array of char vectors)
    opt.lenpx = [] % length-3 vector, yxz smoothing window size
    opt.lensec = [] % scalar, seconds to smooth (does not have to be integer)
    opt.imrate = [] %imaging rate in hz, only required if lensec is nonempty; can be approximate (just determines window size from lensec)
    opt.memthr = 1e9 %memory threshold; if stack size (in bytes) exceeds memthr, we operate on stack in batches to prevent RAM crash; 1e9 is 1 gb; operate in batches to prevent ram from exceeding input stack size (since smoothdata converts from integer data inside function)
end
method = opt.method;
lenpx = opt.lenpx;
lensec = opt.lensec;
imrate = opt.imrate;
memthr = opt.memthr;

if ndims(stack)<4
    error("stack must be 4d or 5d")
end

if ~iscell(method)
    method = {method};
end

if ~isempty(lensec) && isempty(imrate)
    error("if lensec is nonempty, must input imrate")
end

if isempty(lenpx)
    lenpx = [0 0 0];
else
    if numel(lenpx)~=3 || ~isvector(lenpx)
        error("lenpx must be 3-element vector")
    end
end

if isempty(lensec)
    lensec = 0;
else
    if ~isscalar(lensec)
        error("lensec must be scalar")
    end
end

lensampt = lensec*imrate;
lenall = [lenpx lensampt];
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
        for w = 1:numel(lenall)
            if lenall(w) %in case stack is large, looping over each dimension and converting dtype as we go
                if isfinite(numseg) && numseg>1 %if stack is larger than memthr, convert to single (double or single required for mtimes, which is by far fastest way to do this part) in segments to use less ram, since respnew, even though it is also single precision, is generally much smaller than stack
                    seglen = ceil(numframes/numseg);
                    k = 0;
                    while true
                        k = k+1;
                        if w==4
                            idx = [1:seglen]+(seglen-ceil(lenall(w)))*(k-1);
                        else
                            idx = [1:seglen]+seglen*(k-1);
                        end
                        idx(idx>numframes) = [];
                        if isempty(idx)
                            break
                        end
                        if any(strcmp(dtype, {'single', 'double'}))
                            stack(:,:,:,idx,c) = smoothdata(stack(:,:,:,idx,c), w, method{m}, lenall(w));
                        else
                            stack(:,:,:,idx,c) = stacktype(smoothdata(stack(:,:,:,idx,c), w, method{m}, lenall(w)), dtype);
                        end
                    end
                else
                    if any(strcmp(dtype, {'single', 'double'}))
                        stack(:,:,:,:,c) = smoothdata(stack(:,:,:,:,c), w, method{m}, lenall(w));
                    else
                        stack(:,:,:,:,c) = stacktype(smoothdata(stack(:,:,:,:,c), w, method{m}, lenall(w)), dtype);
                    end
                end
            end
        end
    end
end