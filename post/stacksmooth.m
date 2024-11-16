function stacksmooth(stack, opt)

arguments
    stack
    opt.dim = []
    opt.method = 'gaussian'
    opt.window = []
    opt.smsdtime = []
    opt.imrate = []
    opt.smsdspace = []
end
dim = opt.dim;
method = opt.method;
window = opt.window;
smsdspace = opt.smsdspace;
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
        smsd = [smsdspace smsdtime];
    else
        smsd = smsdspace;
    end

    for m = 1:numel(smsd)
        if smsd(m)
            %FOR NOW HACKING THIS WITH DTYPE CONVERSION TO UINT16, BUT NEED TO JUST MULTIPLY BY A GAUSSIAN TO DO THIS DTYPE FLEXIBLY
            stack = uint16(smoothdata(stack, m, 'gaussian', smsd(m)));
        end
    end

end