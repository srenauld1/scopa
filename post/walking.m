
clear all
close all
clc

format long

maxsec = 300;
minsec = 90;
numnumelfac = 0.95;
slopelensec = 0.5;
slopeord = 2;
ball_radius = 4.5;
limfac = 1;
gifvis = 'on';
figsidelength = 0.75; %figure size as proportion of your available screen small dimension (i cannot find the available size of your monitor bc it is not same as full size, so to be safe, keep this under 0.75 to prevent overfilling / causing nonsquare aspect)
fontmedium = 12;
threshmagvel = 5; %mm/s
threshmagvel2 = 3; %mm/s
staticlims = [0 1 1 1 1];
plotside = 0;
patchalpha = 0.1;
doall = 1;
numgoodinds = 86;
numax = 5;
nbin = 20;
plotpaths = 0;


if doall
    pthinsert = '*';
else
    pthinsert = '1';
end

timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

parent_path = '~/walking/';
pthprefix = [parent_path '**/walking' pthinsert '/FicTracData/**/'];
pthgif_paths = [parent_path 'paths_' timestr  '.gif'];
pthgif_stats = [parent_path 'stats_' timestr  '.gif'];
pthgif_hists = [parent_path 'hists_' timestr  '.gif'];

fnp = rdir([pthprefix '**' filesep '*dat']);
for j = 1:numel(fnp)
    fn{j} = fnp(j).name;
end
fn = unique(fn);
fn = natsortfiles(fn);

for j = 1:numel(fn)
    ft = readFictracCSV(fn{j});
    if ~strcmp(ft.Properties.VariableNames{15}, 'posX') && ~strcmp(ft.Properties.VariableNames{15}, 'posY') && strcmp(ft.Properties.VariableNames{25}, 'altTimestamp')
        error("wrong fictrac variables")
    end
    tmpt = ft.altTimestamp-ft.altTimestamp(1);
    dt(j) = mean(diff(tmpt))/1000;
    allt{j} = tmpt(tmpt<maxsec*1e3);
    % alldrlx{j} = ft.deltaRotationVectorLabX(tmpt<maxsec*1e3);
    % alldrly{j} = ft.deltaRotationVectorLabY(tmpt<maxsec*1e3);
    allposx{j} = ft.posX(tmpt<maxsec*1e3);
    allposy{j} = ft.posY(tmpt<maxsec*1e3);
    allintx{j} = ft.intX(tmpt<maxsec*1e3);
    allinty{j} = ft.intY(tmpt<maxsec*1e3);
    allspd{j} = ft.speed(tmpt<maxsec*1e3);
end

numposxmax = max(cellfun(@numel, allposx));
numposxmin = min(cellfun(@numel, allposx));

count = 0;
for j = 1:numel(allposx)
    if numel(allposx{j})>numposxmax*numnumelfac && allt{j}(end)>minsec*1e3
        count = count+1;
        slopelen_samp = round(slopelensec/dt(j));

        % tmp = alldrlx{j};
        % alldrlxgood{count} = smoothdata(tmp, 'gaussian', slopelen_samp, 'omitmissing');
        % tmp = alldrly{j};
        % alldrlygood{count} = smoothdata(tmp, 'gaussian', slopelen_samp, 'omitmissing');

        allposxgood{count} = allposx{j}*ball_radius;
        allposygood{count} = allposy{j}*ball_radius;

        % allintxgood{count} = allintx{j}*ball_radius;
        % allintygood{count} = allinty{j}*ball_radius;

        allvelx{count} = tsdv('circular', allintx{j}, slopelensec, slopeord, dt(j))*ball_radius/dt(j); %same as (smoothed) alldrlygood
        cumvelxtmp = cumsum(allvelx{count});
        cumvelx(count) = cumvelxtmp(end);

        allvelxthresh{count} = allvelx{count};
        allvelxthresh{count}( allvelxthresh{count}>-threshmagvel2 & allvelxthresh{count}<threshmagvel2) = 0;
        cumvelxthreshtmp = cumsum(allvelxthresh{count});
        cumvelxthresh(count) = cumvelxthreshtmp(end);
        allvelxthresh{count}( allvelxthresh{count}>-threshmagvel & allvelxthresh{count}<threshmagvel) = 0;
        cumvelxthreshtmp = cumsum(allvelxthresh{count});
        cumvelxthresh2(count) = cumvelxthreshtmp(end);

        allvely{count} = tsdv('circular', allinty{j}, slopelensec, slopeord, dt(j))*ball_radius/dt(j); %same as (smoothed) -alldrlxgood
        cumvelytmp = cumsum(allvely{count});
        cumvely(count) = cumvelytmp(end);

        allvelythresh{count} = allvely{count};
        allvelythresh{count}( allvelythresh{count}>-threshmagvel2 & allvelythresh{count}<threshmagvel2) = 0;
        cumvelythreshtmp = cumsum(allvelythresh{count});
        cumvelythresh(count) = cumvelythreshtmp(end);
        allvelythresh{count}( allvelythresh{count}>-threshmagvel & allvelythresh{count}<threshmagvel) = 0;
        cumvelythreshtmp = cumsum(allvelythresh{count});
        cumvelythresh2(count) = cumvelythreshtmp(end);

        cumdistend(count) = sum(allspd{j}); %cumulative distance

        %alternative computation for cumulative distance
        % cumdisttmp = zeros(numposxmin-1, 2, 2);
        % cumdisttmp(:,1,1) = allposxgood{count}(1:numposxmin-1);
        % cumdisttmp(:,2,1) = allposygood{count}(1:numposxmin-1);
        % cumdisttmp(:,1,2) = allposxgood{count}(2:numposxmin);
        % cumdisttmp(:,2,2) = allposygood{count}(2:numposxmin);
        % cumdistdiff = cumdisttmp(:,:,2)-cumdisttmp(:,:,1);
        % cumdist = sqrt(sum(cumdistdiff .* cumdistdiff, 2));
        % cumdist = cumsum(cumdist);
        % cumdistend2(count) = cumdist(end);

    end
end


minposx = min(cell2mat(cellfun(@min, allposxgood, 'UniformOutput', false)), [], 'omitmissing');
maxposx = max(cell2mat(cellfun(@max, allposxgood, 'UniformOutput', false)), [], 'omitmissing');
minposy = min(cell2mat(cellfun(@min, allposygood, 'UniformOutput', false)), [], 'omitmissing');
maxposy = max(cell2mat(cellfun(@max, allposygood, 'UniformOutput', false)), [], 'omitmissing');

% minintx = min(cellfun(@min, allintx));
% maxintx = max(cellfun(@max, allintx));
% mininty = min(cellfun(@min, allinty));
% maxinty = max(cellfun(@max, allinty));


minvelx = min(cell2mat(cellfun(@min, allvelx, 'UniformOutput', false)), [], 'omitmissing');
maxvelx = max(cell2mat(cellfun(@max, allvelx, 'UniformOutput', false)), [], 'omitmissing');
minvely = min(cell2mat(cellfun(@min, allvely, 'UniformOutput', false)), [], 'omitmissing');
maxvely = max(cell2mat(cellfun(@max, allvely, 'UniformOutput', false)), [], 'omitmissing');
minvelall = min([minvelx, minvely]);
maxvelall = max([maxvelx, maxvely]);

% figure; plot(allvely{j}); yyaxis right; plot(-alldrlxgood{j});
% figure; plot(allvelx{j}); yyaxis right; plot(alldrlygood{j});
% figure; plot(cumsum(allvelx{j})); yyaxis right; plot(allintxgood{j});

dummyvec = nan(numposxmax, 1);

subplot_layout = {[6,4]};
margins_subplot = 0.05;
margins_fig = 0.05;
ax = figarr(subplot_layout, margins_subplot, margins_fig);


hfg = figure;
aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
close(hfg)


hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gifvis) ;
if aspect_screen>1
    hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
else
    hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
end
haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );

sector_ind = 1;
for axcount = 1:numax
    hax{axcount} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

    if axcount==1
        subplot_pos_ind = 2;
        widthfac = 2;
        heightfac = 2;
        hax{axcount}.InnerPosition(1) = ax(sector_ind).xp(subplot_pos_ind);
        hax{axcount}.InnerPosition(2) = ax(sector_ind).yp(subplot_pos_ind);
        hax{axcount}.InnerPosition(3) = ax(sector_ind).ye(widthfac);
        hax{axcount}.InnerPosition(4) = ax(sector_ind).ye(heightfac);
    else
        subplot_pos_ind = axcount+1;
        widthfac = 4;
        heightfac = 1;
        hax{axcount}.InnerPosition(1) = ax(sector_ind).xp(subplot_pos_ind);
        hax{axcount}.InnerPosition(2) = ax(sector_ind).yp(subplot_pos_ind);
        hax{axcount}.InnerPosition(3) = ax(sector_ind).xe(widthfac);
        hax{axcount}.InnerPosition(4) = ax(sector_ind).ye(heightfac);
    end

    hold(hax{axcount}, 'on')
    % yyaxis left
    hpl1{axcount} = plot(hax{axcount}, dummyvec, dummyvec, 'b-');
    if plotside
        error("need to put hpl2 below")
        hpl2{axcount} = plot(hax{axcount}, dummyvec, dummyvec, 'r-');
    end
    % yyaxis right
    % hpl3 = plot(hax, dummyvec, dummyvec, 'm-');
    % hpl4 = plot(hax, dummyvec, dummyvec, 'k-');

    hpt{axcount} = patch(hax{axcount}, dummyvec, dummyvec, dummyvec, 'EdgeColor',' interp', 'LineWidth', 0.5, 'LineJoin', 'round');
    if axcount~=1
        yline(hax{axcount}, 5, 'k')
    end
    title('');
    hold(hax{axcount}, 'off')

end

if plotpaths
    for j = 1:numel(allposxgood)
        indsplot = 1:numel(allposxgood{j});
        for axcount = 1:numax
            hpl1{axcount}.XData = dummyvec;
            hpl1{axcount}.YData = dummyvec;
            hpt{axcount}.XData = dummyvec;
            hpt{axcount}.YData = dummyvec;
            hpt{axcount}.CData = dummyvec;

            if axcount==1
                hpl1{axcount}.XData(indsplot) = allposxgood{j};
                hpl1{axcount}.YData(indsplot) = allposygood{j};
            elseif axcount==2
                hpl1{axcount}.XData(indsplot) = 1:numel(allvelx{j});
                hpl1{axcount}.YData(indsplot) = allvelx{j};
            elseif axcount==3
                hpl1{axcount}.XData(indsplot) = 1:numel(allvelxthresh{j});
                hpl1{axcount}.YData(indsplot) = allvelxthresh{j};
            elseif axcount==4
                hpl1{axcount}.XData(indsplot) = 1:numel(allvely{j});
                hpl1{axcount}.YData(indsplot) = allvely{j};
            elseif axcount==5
                hpl1{axcount}.XData(indsplot) = 1:numel(allvelythresh{j});
                hpl1{axcount}.YData(indsplot) = allvelythresh{j};
            end

            if axcount==1 && staticlims(axcount)
                hax{axcount}.XLim = [minposx, maxposx];
                hax{axcount}.YLim = [minposy, maxposy];
            elseif axcount~=1 && staticlims(axcount) && ~plotside
                hax{axcount}.YLim = [minvelx, maxvelx];
            elseif axcount~=1 && staticlims(axcount) && plotside
                hax{axcount}.YLim = [minvelall, maxvelall];
            end

            hpt{axcount}.XData(indsplot) = [hpl1{axcount}.XData(indsplot(1:end-1)) nan]; %need the nan to make patch work
            hpt{axcount}.YData(indsplot) = [hpl1{axcount}.YData(indsplot(1:end-1)) nan]; %need the nan to make patch work
            hpt{axcount}.CData(indsplot) = [indsplot(1:end-1) nan]; %need the nan to make patch work

        end
        htx.String = strrep(fn{j}, '_', ' ');
        fig2gif(hfg, j, pthgif_paths)
    end
end
%%

numrecs = numel(cumdistend);
if numrecs~=numgoodinds
    indies = randperm(numrecs-numgoodinds, numgoodinds)+numgoodinds-1;
else
    indies = [];
end
cumdistend_sort = [sort(cumdistend(1:numgoodinds), 'descend') sort(cumdistend(indies), 'descend')];
cumvelx_sort = [sort(cumvelx(1:numgoodinds), 'descend') sort(cumvelx(indies), 'descend')];
cumvely_sort = [sort(cumvely(1:numgoodinds), 'descend') sort(cumvely(indies), 'descend')];
cumvelxthresh_sort = [sort(cumvelxthresh(1:numgoodinds), 'descend') sort(cumvelxthresh(indies), 'descend')];
cumvelythresh_sort = [sort(cumvelythresh(1:numgoodinds), 'descend') sort(cumvelythresh(indies), 'descend')];
cumvelxthresh2_sort = [sort(cumvelxthresh2(1:numgoodinds), 'descend') sort(cumvelxthresh2(indies), 'descend')];
cumvelythresh2_sort = [sort(cumvelythresh2(1:numgoodinds), 'descend') sort(cumvelythresh2(indies), 'descend')];



hfg = figure;

spl = subplot(2,4,1); hold on;
plot(spl, cumdistend_sort);
title("total distance (not trip vector magnitude), sorted") %cumdistend2
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,2); hold on;
plot(spl, cumvelx_sort);
title("sum of forward velocities, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,6); hold on;
plot(spl, cumvely_sort);
title("sum of side velocities, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,3); hold on;
plot(spl, cumvelxthresh_sort);
title("sum of forward velocities > +/- 3 mm/s, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,7); hold on;
plot(spl, cumvelythresh_sort);
title("sum of side velocities > +/- 3 mm/s, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,4); hold on;
plot(spl, cumvelxthresh2_sort);
title("sum of forward velocities > +/- 5 mm/s, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);

spl = subplot(2,4,8); hold on;
plot(spl, cumvelythresh2_sort);
title("sum of side velocities > 5 +/- mm/s, sorted")
ylm = ylim;
patch(spl, [1 numgoodinds numgoodinds 1], [ylm(1) ylm(1) ylm(2) ylm(2)], 'm', 'EdgeColor', 'none', 'FaceAlpha', patchalpha);
fig2gif(hfg, 1, pthgif_stats)



cumdistend_sort = cumdistend(1:numgoodinds);
cumdistend_sort_o = cumdistend(indies);
cumvelx_sort = cumvelx(1:numgoodinds);
cumvelx_sort_o = cumvelx(indies);
cumvely_sort = cumvely(1:numgoodinds);
cumvely_sort_o = cumvely(indies);
cumvelxthresh_sort = cumvelxthresh(1:numgoodinds);
cumvelxthresh_sort_o = cumvelxthresh(indies);
cumvelythresh_sort = cumvelythresh(1:numgoodinds);
cumvelythresh_sort_o = cumvelythresh(indies);
cumvelxthresh2_sort = cumvelxthresh2(1:numgoodinds);
cumvelxthresh2_sort_o = cumvelxthresh2(indies);
cumvelythresh2_sort = cumvelythresh2(1:numgoodinds);
cumvelythresh2_sort_o = cumvelythresh2(indies);



hfg = figure;

spl = subplot(2,4,1); hold on;
histogram(spl, cumdistend_sort, nbin);
histogram(spl, cumdistend_sort_o, nbin);
title("total distance (not trip vector magnitude)") %cumdistend2

spl = subplot(2,4,2); hold on;
histogram(spl, cumvelx_sort, nbin);
histogram(spl, cumvelx_sort_o, nbin);
title("sum of forward velocities")

spl = subplot(2,4,6); hold on;
histogram(spl, cumvely_sort, nbin);
histogram(spl, cumvely_sort_o, nbin);
title("sum of side velocities")

spl = subplot(2,4,3); hold on;
histogram(spl, cumvelxthresh_sort, nbin);
histogram(spl, cumvelxthresh_sort_o, nbin);
title("sum of forward velocities > +/- 3 mm/s")

spl = subplot(2,4,7); hold on;
histogram(spl, cumvelythresh_sort, nbin);
histogram(spl, cumvelythresh_sort_o, nbin);
title("sum of side velocities > +/- 3 mm/s")

spl = subplot(2,4,4); hold on;
histogram(spl, cumvelxthresh2_sort, nbin);
histogram(spl, cumvelxthresh2_sort_o, nbin);
title("sum of forward velocities > +/- 5 mm/s")

spl = subplot(2,4,8); hold on;
histogram(spl, cumvelythresh2_sort, nbin);
histogram(spl, cumvelythresh2_sort_o, nbin);
title("sum of side velocities > 5 +/- mm/s")

fig2gif(hfg, 1, pthgif_hists)

%%


