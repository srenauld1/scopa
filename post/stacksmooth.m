function stacksmooth(stack, opt)

arguments
    stack
    opt.dim = []
    opt.method = 'gaussian'
    opt.window = []
    opt.smsdtime = []
    opt.imrate = []
    opt.smlenpx = []
end
dim = opt.dim;
method = opt.method;
window = opt.window;
smlenpx = opt.smlenpx;
smsdtime = opt.smsdtime;
imrate = opt.imrate;

if isempty(dim) && ~isempty(window)
    dim = 1:numel(window);
end

if isempty(imrate)
    imrate = 1; %if empty, interpret smsdtime as samples
end


    if smsdtime
        smsdtime = smsdtime*imrate;
        smsd = [smlenpx smsdtime];
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