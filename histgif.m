function histgif(inp, nbin)

vals = zeros(size(inp,1), nbin);
for k = 1:size(inp,1)
    vals(k,:) = histcounts(inp(k,:), nbin);
    maxcnt(k) = max(vals(k,:));
end

pthgif = pathauto(suffix='.gif', usetime=1);
hfg = figure;
hax = axes(Parent=hfg);
hpl = histogram(hax, inp(1,:), nbin);
xlim([-max(abs(inp(:))) max(abs(inp(:)))])
ylim([0 max(maxcnt)])
for k = 1:size(inp,1)
    [~,BinEdges] = histcounts(inp(k,:),hpl.NumBins);
    BinLimits = [min(BinEdges),max(BinEdges)];
    hpl.Data= inp(k,:);
    hpl.BinEdges= BinEdges;
    hpl.BinLimits= BinLimits;

    fig2gif(hfg,k,pthgif)
end
