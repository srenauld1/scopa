function plot_gif_fast(inp, swapdim, fngif, titall, plotinds_z, plotinds_t, ncolors)

szo = size(inp);
numdims = ndims(inp);


if ~exist('ncolors', 'var')
    ncolors = 128;
end

if ~exist('swapdim', 'var') || isempty(swapdim)
    swapdim = 0;
end


if numdims==2
    sznew = [size(inp) 1];
elseif numdims==3
    sznew = size(inp);
elseif numdims>3
    if swapdim
        inp = permute(inp, [1 2 4 3]);
        szo = size(inp);
    end
    inp = reshape(inp, size(inp,1), size(inp,2), []);
    sznew = size(inp);
end

if exist('plotinds_z', 'var') & exist('plotinds_t', 'var')
    titopt = repelem(plotinds_z, length(plotinds_t));
    for ti = 1:length(titopt)
        titallnew{ti} = cat(1, titall, ['z slice ' num2str(titopt(ti))]);
    end
else
    titallnew{1} = titall;
    titallnew = repelem(titallnew, sznew(end));
end

h = figure;
for i = 1:sznew(end)

    if i==1
        himg = imshow(inp(:,:,i), 'InitialMagnification', 'fit');
    else
        himg.CData = inp(:,:,i);
    end
    axis off; axis image;

    sgtitle(titallnew{i}, 'FontSize', 10)

    fig2gif(h, i, fngif)

end

end