function stacksmooth(stack, opt)

arguments
    stack
    opt.dim = []
    opt.method = 'gaussian'
    opt.window = []
    opt.smlensec = []
    opt.imrate = []
    opt.smlenpx = []
end
dim = opt.dim;
method = opt.method;
window = opt.window;
smlenpx = opt.smlenpx;
smlensec = opt.smlensec;
imrate = opt.imrate;

if isempty(dim) && ~isempty(window)
    dim = 1:numel(window);
end

if isempty(imrate)
    imrate = 1; %if empty, interpret smlensec as samples
end


    if smlensec
        smlensec = smlensec*imrate;
        smsd = [smlenpx smlensec];
    else
        smsd = smlenpx;
    end

    for m = 1:numel(smsd)
        if smsd(m)
            %FOR NOW HACKING THIS WITH DTYPE CONVERSION TO UINT16, BUT NEED TO JUST MULTIPLY BY A GAUSSIAN TO DO THIS DTYPE FLEXIBLY
            stack = uint16(smoothdata(stack, m, 'gaussian', smsd(m)));
        end
    end

end