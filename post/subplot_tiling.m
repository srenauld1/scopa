function [nrows, ncols] = subplot_tiling(numsubfig)

%find at least 2:1 distribution of rows and columns

rcreldiff = 1;
fracrowempty = 1;
countz = 0;
while rcreldiff>=0.5 %| fracrowempty>=0.75
    numsubfig_new = numsubfig+countz;
    alldiv = alldivisors(numsubfig_new);
    [~, tmp] = min(abs(alldiv - median(alldiv)));
    nrows = alldiv(tmp);
    ncols = numsubfig_new / nrows;
    rcreldiff = abs((nrows - ncols) / max([nrows ncols]));
    fracrowempty = (numsubfig_new-numsubfig) / ncols;
    countz = countz+1;
    if countz>1000
        error
    end
end
dun = 1;