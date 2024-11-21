function stack = stacksmooth(stack, opt)

arguments
    stack
    opt.method = 'gaussian'
    opt.smlenpx = []
    opt.smsdtime = []
    opt.imrate = []
end
method = opt.method;
smlenpx = opt.smlenpx;
smsdtime = opt.smsdtime;
imrate = opt.imrate;

if ~iscell(method)
    method = {method};
end

if isempty(imrate)
    imrate = 1; %if empty, interpret smsdtime as samples
end

if isempty(smlenpx)
    smlenpx = [0 0 0];
else
    if numel(smlenpx)~=3 && ~isvector(smlenpx)
        error("smlenpx must be 3-element vector")
    end
end

if isempty(smsdtime)
    smsdtime = 0;
else
    if ~isscalar(smsdtime)
        error("smsdtime must be scalar")
    end
end

smsdtime = smsdtime*imrate;
smsd = [smlenpx smsdtime];
dtype = class(stack);

numchan = size(stack, 5);

for m = 1:numel(method)
    for c = 1:numchan %do one channel at a time to keep temporary double output from crashing matlab if stack is big 2-channel
        for w = 1:numel(smsd)
            if smsd(w) %in case stack is large, looping over each dimension and converting dtype as we go
                switch dtype
                    case 'int16'
                        stack(:,:,:,:,c) = int16(smoothdata(stack(:,:,:,:,c), w, method{m}, smsd(w)));
                    case 'uint16'
                        stack(:,:,:,:,c) = uint16(smoothdata(stack(:,:,:,:,c), w, method{m}, smsd(w)));
                    case 'single'
                        stack(:,:,:,:,c) = single(smoothdata(stack(:,:,:,:,c), w, method{m}, smsd(w)));
                    case 'double'
                        stack(:,:,:,:,c) = smoothdata(stack(:,:,:,:,c), w, method{m}, smsd(w));
                    otherwise
                        error("stacksmooth only supports uint16, int16, single, and double")
                end
            end
        end
    end
end