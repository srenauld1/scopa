
function plots_imdata(inp, mask, sindz, tindz, tindz_sub, szo, filename_prefix)

disp("this function is very old and needs to be updated")

filename_prefix = filename_prefix(1:end-4);

numbin = 100;

% could try median + k x MAD x 1.482

inpsub = inp(:,:,:,tindz_sub);

sz = size(inp);
szsub = size(inpsub);
ncol = 128;

sindz_str = sprintf('%.0f,' , sindz);
sindz_str = sindz_str(1:end-1);% strip final comma

if isempty(mask)
    masked = 0;
    maskstring = 'withoutmask';
    mask = boolean(ones(size(inp, 1), size(inp, 2), size(inp, 3)));
else
    masked = 1;
    maskstring = 'withmask';
    mask = boolean(sum(mask, 4));
end

inp = inp .* mask;
inpsub = inpsub .* mask;

[masky, maskx, maskz] = ind2sub(size(mask), find(mask));

maskrept = repmat(mask, [1 1 1 sz(4)]);
[maskrepty, maskreptx, maskreptz, maskreptt] = ind2sub(size(maskrept), find(maskrept));

maskreptsub = repmat(mask, [1 1 1 szsub(4)]);
[maskreptsuby, maskreptsubx, maskreptsubz, maskreptsubt] = ind2sub(size(maskreptsub), find(maskreptsub));

%%  single slice 

numpixmask_max = 0;
for sli = sindz
    subcond = find(maskreptz==sli);
    numpixmask_max = max([numpixmask_max length(subcond)]);
end
histinp = nan(numpixmask_max, 1, length(sindz));
for sli = sindz
    subcond = find(maskreptz==sli);
    maskvecinds = sub2ind(size(maskrept), maskrepty(subcond),maskreptx(subcond),maskreptz(subcond),maskreptt(subcond));
    histinp(1:length(maskvecinds),1,sli) = inp(maskvecinds);
    if masked 
        tlev(sli) = multithresh(histinp(~isnan(histinp)));
    end
end

title_hist = {['pixel intensities for slices ' sindz_str]; ['all frames of ' num2str(szo(4)) ' total']; maskstring};
filename_hist_gif = [filename_prefix '_slicehistallframe_' maskstring '_.gif'];

plot_histogram_gif(histinp, numbin, title_hist, filename_hist_gif)


%% single frame histograms

numpixmask_max = 0;
for sli = sindz
    for i = 1:szsub(4)
        subcond = find(maskreptsubz==sli & maskreptsubt==i);
        numpixmask_max = max([numpixmask_max length(subcond)]);
    end
end
histinp = nan(numpixmask_max, length(sindz), szsub(4));
for sli = sindz
    for i = 1:szsub(4)
        subcond = find(maskreptsubz==sli & maskreptsubt==i);
        maskvecinds = sub2ind(size(maskreptsub), maskreptsuby(subcond),maskreptsubx(subcond),maskreptsubz(subcond),maskreptsubt(subcond));
        histinp(1:length(maskvecinds), sli, i) = inpsub(maskvecinds);
        if masked
            tlev(sli) = multithresh(histinp(~isnan(histinp)));
        end
    end
end

title_hist = {['pixel intensities for slices ' sindz_str]; [num2str(length(tindz_sub)) ' equidistant frames from ' num2str(tindz(tindz_sub(1))) ' to ' num2str(tindz(tindz_sub(end))) ' of ' num2str(szo(4)) ' total']; maskstring};
filename_hist_gif = [filename_prefix '_framehist_' maskstring '_.gif'];

plot_histogram_gif(histinp, numbin, title_hist, filename_hist_gif)

%% mean frame histogram

meanframe_3d = mean(inp, 4);

numpixmask_max = 0;
for sli = sindz
    subcond = find(maskz==sli);
    numpixmask_max = max([numpixmask_max length(subcond)]);
end
histinp = nan(numpixmask_max, length(sindz));
for sli = sindz
    subcond = find(maskz==sli);
    maskvecinds = sub2ind(size(mask), masky(subcond),maskx(subcond),maskz(subcond));
    histinp(1:length(maskvecinds),sli) = meanframe_3d(maskvecinds);
    if masked
        tlev(sli) = multithresh(histinp(~isnan(histinp)));
    end
end

title_hist = {['pixel intensities for slices ' sindz_str]; ['mean frame of ' num2str(length(tindz)) ' equidistant frames from ' num2str(tindz(1)) ' to ' num2str(tindz(end)) ' of ' num2str(szo(4)) ' total']; maskstring};
filename_hist_gif = [filename_prefix '_meanframehist_' maskstring '_.gif'];

plot_histogram_gif(histinp, numbin, title_hist, filename_hist_gif)

%% movie with varied clipping

out = inpsub;

ctop = 100;
cbot = 0;
ctopvec = fliplr(ctop:5:100);
cbotvec = 0:5:cbot;

outall = zeros([size(out) length(ctopvec)*length(cbotvec)]);

numdims_out = ndims(out); %find time dimension (last dimension), since input dimensionality varies
otherdims = repmat({':'},1,numdims_out);

idx = out~=0; %in case there was a mask applied we want to ignore outside
countz = 0;
for iiii = ctopvec
    for ii2 = cbotvec
        countz = countz + 1;
        if masked
            out(idx) = filloutliers(out(idx), 'clip', 'percentiles', [ii2 iiii]); %do this after the time averaging
            out(idx) = rescale(out(idx));
        else
            out = filloutliers(out, 'clip', 'percentiles', [ii2 iiii]); %do this after the time averaging
            out = rescale(out);
        end
        outall(otherdims{:},countz) = out;
    end
end

plot_gif(outall, [filename_prefix '_mov_' maskstring '_.gif'])


%% plot image with the brightest pixel

[maxval, maxind] = max(inp(:));
[maxy, maxx, maxz, maxt] = ind2sub(size(inp), maxind);

h = figure;
imagesc(inp(:,:, maxz, maxt));
title({['brightest pixel is ' num2str(maxval) ' at xyzt position ' num2str([maxy maxx maxz tindz(maxt)])]; maskstring})
filename_gif = [filename_prefix '_brightestpixim_' maskstring '_.gif'];
plot_gif_singleframe(h, ncol, filename_gif)

%% pixel percentiles

colord = distinguishable_colors(length(sindz));
edge_pix_to_crop = 4;
pixinc = 6;
avgwin = [30 30];
prcnts = [70 80 90];
rp1 = edge_pix_to_crop:pixinc:sz(1)-(edge_pix_to_crop-1);
rp2 = edge_pix_to_crop:pixinc:sz(2)-(edge_pix_to_crop-1);
maskcroptmp = boolean(zeros(size(mask, 1), size(mask, 2)));
maskcroptmp(rp1, rp2) = 1;

maskcrop = boolean(mask.*maskcroptmp);
[~, ~, maskcropz, ~] = ind2sub(size(maskcrop), find(maskcrop));

maskreptcrop = boolean(maskrept.*maskcroptmp);
[maskreptcropy, maskreptcropx, maskreptcropz, maskreptcropt] = ind2sub(size(maskreptcrop), find(maskreptcrop));

if masked
    inpcrop_allslice = inp.*maskreptcrop;
    pix_timeseries_all = reshape(inpcrop_allslice(find(maskreptcrop)), [], sz(4));
else
    inpcrop_allslice = inp(rp1, rp2, :, :);
    pix_timeseries_all = reshape(inpcrop_allslice, [], sz(4));
end

%plot_gif(rescale(inpcrop_allslice(:,:,:,round(linspace(1, sz(4), 10)))), [filename_prefix '_movcrop_' maskstring '_.gif'])

pix_mean_all = mean(pix_timeseries_all, 2);
ylnew = [min(pix_mean_all(:)) max(pix_mean_all(:))];

numpixmask_max = 0;
for sli = sindz
    subcond = find(maskcropz==sli);
    numpixmask_max = max([numpixmask_max length(subcond)]);
end

pix_timeseries_allslice = nan(numpixmask_max, length(sindz), sz(4));
pix_mean_sort_inds_allslice = nan(numpixmask_max, length(sindz));

h = figure(30);
for sli = sindz

    subcond = find(maskreptcropz==sli);
    maskvecinds = sub2ind(size(maskreptcrop), maskreptcropy(subcond),maskreptcropx(subcond),maskreptcropz(subcond),maskreptcropt(subcond));
    inpcrop = inp(maskvecinds);
    pix_timeseries = reshape(inpcrop, [], sz(4));
    pix_timeseries_allslice(1:size(pix_timeseries,1),sli,:) = pix_timeseries;
    
    [pix_mean_sorted, pix_mean_sort_inds] = sort(mean(pix_timeseries, 2));
    pix_mean_sort_inds_allslice(1:length(pix_mean_sort_inds),sli) = pix_mean_sort_inds;

    [~, kneeidx_mean(sli)] = knee_pt(pix_mean_sorted,[],1);

    pix_timeseries_sorted = sort(pix_timeseries, 2);
    pix_timeseries_sorted = pix_timeseries_sorted(pix_mean_sort_inds,:);

    centile = zeros(1, size(pix_timeseries_sorted, 1));
    for pii = 1:size(pix_timeseries_sorted, 1)
        [~, kneeidx_each] = knee_pt(pix_timeseries_sorted(pii,:)',[],1);
        centile(pii) = find_centile(pix_timeseries_sorted(pii, :), pix_timeseries_sorted(pii, kneeidx_each));
    end
    [centile, centile_sorted] = sort(centile, 'descend');
    [~, kneeidx_of_kneeidx(sli)] = knee_pt(centile,[],1);
    goodpix_perslice{sli} = centile_sorted(kneeidx_of_kneeidx(sli):end);
    pix_timeseries_sorted = pix_timeseries_sorted(centile_sorted,:); %more precise sorting (SNR basically) than mean intensity 

    figure(30); hold on
    plot(centile, 'k')
    scatter(kneeidx_of_kneeidx(sli), centile(kneeidx_of_kneeidx(sli)), 'k', 'filled');

    if sli==sindz(end)
        filename_plot_gif = [filename_prefix '_intsthreshthresh_allslice_' maskstring '_.gif'];
        plot_gif_singleframe(h, ncol, filename_plot_gif)
    end

    h2 = figure; hold on
    for pii = 1:size(pix_timeseries_sorted, 1)
        if ismember(pii, goodpix_perslice{sli})
            plot(pix_timeseries_sorted(pii,:)', 'm')
            scatter(kneeidx_each, pix_timeseries_sorted(pii, kneeidx_each), 'm', 'filled');
        else
            plot(pix_timeseries_sorted(pii,:)', 'k')
            scatter(kneeidx_each, pix_timeseries_sorted(pii, kneeidx_each), 'k', 'filled');        
        end
    end
    filename_plot_gif = [filename_prefix '_intsthreshed_slice' num2str(sli) '_' maskstring '_.gif'];
    plot_gif_singleframe(h2, ncol, filename_plot_gif)

%     figure(31); hold on
%     pp1 = plot(pix_mean_sorted, 'color', colord(sli, :));
%     pp2 = scatter(kneeidx_mean(sli), pix_mean_sorted(kneeidx_mean(sli)), 50, colord(sli, :), 'filled');
%     ylim(ylnew)
%     title(['sorted pixel timeseries/kneepoint for slices ' sindz_str])


    %delete(pp1)
    %delete(pp2)

end

%%

pix_timeseries_allslice = pix_timeseries_allslice(~isnan(pix_timeseries_allslice));
[pix_allslice_sorted, pix_allslice_sort_inds] = sort(pix_timeseries_allslice);

[~, kneeidx_allslice] = knee_pt(pix_allslice_sorted,[],1);

startidx = kneeidx_allslice;

signal_inds = pix_allslice_sort_inds(startidx:end);

pix_timeseries_allslice_sorted_signal = pix_timeseries_allslice(signal_inds, :);

pix_allslice_sorted_signal_mean = mean(pix_timeseries_allslice_sorted_signal, 2);

figure; hold on
plot(pix_allslice_sorted_signal_mean, 'k')
scatter(kneeidx_mean, pix_mean_sorted(kneeidx_mean), 50, 'k', 'filled');
title({[' mean frame intensity for "signal" pixels ']; maskstring})

allvar = var(sort(pix_timeseries_allslice_sorted_signal, 2));
[~, minvar] = min(allvar);
blf = mean(pix_timeseries_allslice_sorted_signal(:,minvar));
nless = sum(pix_timeseries_allslice_sorted_signal < blf, 2);
nequal = sum(pix_timeseries_allslice_sorted_signal == blf, 2);
centile = 100 * (nless + 0.5*nequal) ./ size(pix_timeseries_allslice_sorted_signal, 2);
meancentile = mean(centile);

%%

numplotpix = 40;
colord = distinguishable_colors(numplotpix);

pixindsplot = round(linspace(1, size(pix_timeseries_allslice_sorted_signal, 1), numplotpix));
allchosen = pix_timeseries_allslice_sorted_signal(pixindsplot, :);
maxall = max(allchosen(:));

figure; hold on
countz = 0;
for pxii = pixindsplot
    countz = countz+1;
    plot(sort(pix_timeseries_allslice_sorted_signal(pxii, :)), 'color', colord(countz, :))
    %plot(pix_signal_timeseries_meansorted(pxii, :), 'color', colord(countz, :))
    %scatter(mean(pixintsub(pxii, :), 2), 1500, 'color', colord(countz,:))
    %scatter(prctile(pixintsub(pxii, :), 10, 2), 1500, 'color', colord(countz,:))
    %pause(0.2)
end
xline(minvar)
title({['baseline intensity ' num2str(round(blf)) ', ' num2str(round(meancentile)) 'th percentile']; maskstring})


figure
countz = 0;
for pxii = pixindsplot
    countz = countz+1;
    subplot(numplotpix,1,countz);
    histogram(pix_timeseries_allslice_sorted_signal(pxii, :), 'NumBins', numbin, 'FaceColor', colord(countz, :));
    set(gca,'YScale','log');
    mygca(countz) = gca;
end

yl = cell2mat(get(mygca, 'Ylim'));
ylnew = [min(yl(:,1)) max(yl(:,2))];
set(mygca, 'Ylim', ylnew)

xl = cell2mat(get(mygca, 'Xlim'));
xlnew = [min(xl(:,1)) max(xl(:,2))];
set(mygca, 'Xlim', xlnew)

%%

pixintsubz = zscore(pix_timeseries_allslice_sorted_signal,1,2);

allchosen = pixintsubz(pixindsplot, :);
maxall = max(allchosen(:));

figure; hold on
countz = 0;
for pxii = pixindsplot
    countz = countz+1;
    plot(sort(pixintsubz(pxii, :)), 'color', colord(countz, :))
    %scatter(mean(pixintsubz(pxii, :)), 1500, 'color', colord(countz,:))
    %scatter(prctile(pixintsubz(pxii, :), 10), 1500, 'color', colord(countz,:))
    %pause(0.2)
end
xline(minvar)
title({['baseline intensity ' num2str(round(blf)) ', ' num2str(round(meancentile)) 'th percentile']; maskstring})

figure
countz = 0;
for pxii = pixindsplot
    countz = countz+1;
    subplot(numplotpix,1,countz);
    histogram(pixintsubz(pxii, :), 'NumBins', numbin, 'FaceColor', colord(countz, :));
    set(gca,'YScale','log');
    mygca(countz) = gca;
end

yl = cell2mat(get(mygca, 'Ylim'));
ylnew = [min(yl(:,1)) max(yl(:,2))];
set(mygca, 'Ylim', ylnew)

xl = cell2mat(get(mygca, 'Xlim'));
xlnew = [min(xl(:,1)) max(xl(:,2))];
set(mygca, 'Xlim', xlnew)

%%
