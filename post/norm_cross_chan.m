
function norm_cross_chan(resp, t, fngif_prefix)

numseg = 10;
titlein = '';
constant_ylim = 1;
ylim_padfac = 0.1;
ls1 = '-k';
ls2 = '-r';
match_ylim = 0;

plotcropsec = 10;
dur = max(t);
sampinds = find(t<=dur);
numsamp = numel(sampinds);
plotinds = find(t>=t(1)+plotcropsec & t<=t(end)-plotcropsec);
lev = floor(log2(numel(sampinds)));
fngif = [fngif_prefix(1:end-4) 'resp_mra_.gif'];

%% 

imdt = median(diff(t));
wcoherence(resp(1,sampinds,1), resp(1,sampinds,2), seconds(imdt), 'numscales',32,'phasedisplaythreshold',0.5);

[wcoh,~,P,coi] = wcoherence(resp(1,sampinds,1), resp(1,sampinds,2), seconds(imdt), 'numscales',16, 'phasedisplaythreshold',0.7);
helperPlotCoherence(wcoh,t(sampinds),seconds(P),seconds(coi),'Time (secs)','Periods (Seconds)')

%% 

w = modwt(resp(1,sampinds,1),lev); %decompose into lev(k) subbands
mra = modwtmra(w); %multiresolution analysis

w2 = modwt(resp(1,sampinds,2),lev); %decompose into lev(k) subbands
mra2 = modwtmra(w2); %multiresolution analysis

numsegall = [150, 75, 37, 18, 9, 6, 4, 1, 1, 1, 1, 1, 1];

for m = 1:size(mra,1)

    cfs = w;
    rem = [1 5:13];
    cfs(rem,:) = 0; %set approximation coefficients for level lev to zero
    respnew = imodwt(cfs); % inverse modwt with zeroed coeffs to remove trend

    if m==1
        hfg = figure( 'Units', 'Normalized');
        hax = axes('Parent', hfg, 'Units', 'Normalized', 'Position',[0.1 0.6 0.85 0.35]);
        hold(hax, 'on')
        yyaxis left
        hpl1 = plot(hax, t(plotinds), resp(1,plotinds,1), 'k-');
        hpl2 = plot(hax, t(plotinds), respnew(plotinds), 'r-');
        yyaxis right
        hpl3 = plot(hax, t(plotinds), mra(m,plotinds), 'b-');
        hpl4 = plot(hax, t(plotinds), mra(m,plotinds)+mean(mra(m,plotinds)), 'c-');
        hold(hax, 'off')
        hax.YAxis(1).Color = 'k';
        hax.YAxis(2).Color = 'b';
        hax2 = axes('Parent', hfg, 'Units', 'Normalized', 'Position',[0.1 0.1 0.85 0.35]);
        hold(hax2, 'on')
        yyaxis left
        % hpl21 = plot(hax2, t(plotinds), resp(1,plotinds,1), 'k-');
        % hpl22 = plot(hax2, t(plotinds), resp(1,plotinds,2), 'r-');
        yyaxis right
        hpl23 = plot(hax2, t(plotinds), w(m,plotinds), 'b-');
        hpl24 = plot(hax2, t(plotinds), w2(m,plotinds), 'c-');
        hold(hax2, 'off')
        hax2.YAxis(1).Color = 'k';
        hax2.YAxis(2).Color = 'b';
    else
        hpl2.YData = respnew(plotinds);
        hpl3.YData = mra(m,plotinds);
        hpl4.YData = mra(m,plotinds)+mean(mra(m,:)); %don't apply plotinds when computing the mean
        hpl23.YData = w(m,plotinds);
        hpl24.YData = w2(m,plotinds);
    end
    hax.Title.String = ['lev ' num2str(lev) ', mra ' num2str(m) ', chan 1 sig (black) & recon (red), approx blue, approx cent. cyan)'];
    hax2.Title.String = ['lev ' num2str(lev) ', mra ' num2str(m) ', chan 1 & 2 coeffs blue & cyan'];
    % hax2.Title.String = ['chan 1 (black) & 2(red), lev ' num2str(lev) ', mra ' num2str(m) ', coeffs blue & cyan'];

    fig2gif(hfg,m,fngif)

    numseg = ceil((log2(size(mra,1)-m)+1).^1.9);
    numseg = numsegall(m);

    % fngif2 = [fngif_prefix(1:end-4) 'resp_mracoeffs_' num2str(m) '_.gif'];
    % plot_multi_timeseries(w(m,plotinds), w2(m,plotinds), fngif2, numseg, titlein, constant_ylim, ylim_padfac, ls1, ls2, match_ylim)

    fngif3 = [fngif_prefix(1:end-4) 'resp_rec_' num2str(m) '_.gif'];
    plot_multi_timeseries(resp(1,plotinds,1), respnew(plotinds), fngif3, numseg, titlein, constant_ylim, ylim_padfac, ls1, ls2, match_ylim)


end

end

