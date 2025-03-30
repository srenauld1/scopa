function cmapshow(inp)

arguments
    inp = axes()
end
if isobject(inp)
    cmap = get(inp, 'colororder');
else
    if size(inp,2)~=3
        error("if input is not axis, must be nx3 colormap")
    end
    cmap = inp;
end
cmap = permute(cmap, [1 3 2]);
cmaprs = imresize(cmap, 50.0, 'nearest');
figure; imshow(cmaprs);