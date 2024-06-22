
clear all
close all
clc

format long

maxsec = 300;
minsec = 90;
numnumelfac = 0.95;
slopelen_sec = 0.5;
slopeorder = 2;
ball_radius = 4.5;
limfac = 1;
gif_visibility = 'on';
figsidelength = 0.75; %figure size as proportion of your available screen small dimension (i cannot find the available size of your monitor bc it is not same as full size, so to be safe, keep this under 0.75 to prevent overfilling / causing nonsquare aspect)
fontmedium = 12;
threshmagvel = 5; %mm/s
staticlims = [0 1 1];
plotside = 1;

pthprefix = '~/stacks/*/FicTracData/**/';
% pthprefix2 = '/Volumes/neurobio/wilsonlab/Wenyi/2pData/R37G12/';
fngif_xyfs = '~/stacks/xyfs.gif';
fngif_paths = '~/stacks/paths.gif';

fnp = rdir([pthprefix '**' filesep '*dat']);
% fn2 = rdir([pthprefix2 '**' filesep '*dat']);
% fn = [fn; fn2];
for j = 1:numel(fnp)
    fn{j} = fnp(j).name;
end
fn = unique(fn);
fn = natsortfiles(fn);

for j = 1:numel(fn)
    ft = readFictracCSV(fn{j});
    if ~strcmp(ft.Properties.VariableNames{15}, 'posX') && ~strcmp(ft.Properties.VariableNames{15}, 'posY') ...
            && ~strcmp(ft.Properties.VariableNames{15}, 'intX') && ~strcmp(ft.Properties.VariableNames{15}, 'intY') ...
            && strcmp(ft.Properties.VariableNames{25}, 'altTimestamp')
        error("wrong")
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



for j = 1:numel(allposx)
    if numel(allposx{j})>numposxmax*numnumelfac && allt{j}(end)>minsec*1e3
        slopelen_samp = round(slopelen_sec/dt(j));

        % tmp = alldrlx{j};
        % alldrlxcrop{j} = smoothdata(tmp, 'gaussian', slopelen_samp, 'omitmissing');
        % tmp = alldrly{j};
        % alldrlycrop{j} = smoothdata(tmp, 'gaussian', slopelen_samp, 'omitmissing');

        allposxcrop{j} = allposx{j}*ball_radius;
        allposycrop{j} = allposy{j}*ball_radius;

        % allintxcrop{j} = allintx{j}*ball_radius;
        % allintycrop{j} = allinty{j}*ball_radius;

        allvelx{j} = differentiate_timeseries('circular', allintx{j}, slopelen_samp, slopeorder, 1)*ball_radius/dt(j); %same as (smoothed) alldrlycrop

        allvelxthresh{j} = allvelx{j};
        allvelxthresh{j}( allvelxthresh{j}>-threshmagvel & allvelxthresh{j}<threshmagvel) = 0;
        cumvelxthreshtmp = cumsum(allvelxthresh{j});
        cumvelxthresh(j) = cumvelxthreshtmp(end);

        allvely{j} = differentiate_timeseries('circular', allinty{j}, slopelen_samp, slopeorder, 1)*ball_radius/dt(j); %same as (smoothed) -alldrlxcrop

        allvelythresh{j} = allvely{j};
        allvelythresh{j}( allvelythresh{j}>-threshmagvel & allvelythresh{j}<threshmagvel) = 0;
        cumvelythreshtmp = cumsum(allvelythresh{j});
        cumvelythresh(j) = cumvelythreshtmp(end);


        cumdisttmp = zeros(numposxmin-1, 2, 2);
        cumdisttmp(:,1,1) = allposxcrop{j}(1:numposxmin-1);
        cumdisttmp(:,2,1) = allposycrop{j}(1:numposxmin-1);
        cumdisttmp(:,1,2) = allposxcrop{j}(2:numposxmin);
        cumdisttmp(:,2,2) = allposycrop{j}(2:numposxmin);
        cumdistdiff = cumdisttmp(:,:,2)-cumdisttmp(:,:,1);
        cumdist = sqrt(sum(cumdistdiff .* cumdistdiff, 2));
        cumdist = cumsum(cumdist);
        cumdistend(j) = cumdist(end);
        cumdistend2(j) = sum(allspd{j});

    end
end


minposx = min(cellfun(@min, allposxcrop));
maxposx = max(cellfun(@max, allposxcrop));
minposy = min(cellfun(@min, allposycrop));
maxposy = max(cellfun(@max, allposycrop));

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

% figure; plot(allvely{j}); yyaxis right; plot(-alldrlxcrop{j});
% figure; plot(allvelx{j}); yyaxis right; plot(alldrlycrop{j});
% figure; plot(cumsum(allvelx{j})); yyaxis right; plot(allintxcrop{j});

dummyvec = nan(numposxmax, 1);

subplot_layout = {[4,4]};
margins_fig = 0.05;
margins_subplot = 0.05;
ax = arrange_subplots(subplot_layout, margins_fig, margins_subplot);


hfg = figure;
aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
close(hfg)


hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
if aspect_screen>1
    hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
else
    hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
end
haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );

sector_ind = 1;
for subfig_ind = 1:3
    hax{subfig_ind} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');

    if subfig_ind==1
        subplot_pos_ind = 2;
        widthfac = 2;
        heightfac = 2;
        hax{subfig_ind}.InnerPosition(1) = ax(sector_ind).xp(subplot_pos_ind);
        hax{subfig_ind}.InnerPosition(2) = ax(sector_ind).yp(subplot_pos_ind);
        hax{subfig_ind}.InnerPosition(3) = ax(sector_ind).ye*widthfac;
        hax{subfig_ind}.InnerPosition(4) = ax(sector_ind).ye*heightfac;
    else
        if subfig_ind==2
            subplot_pos_ind = 3;
        elseif subfig_ind==3
            subplot_pos_ind = 4;
        end
        widthfac = 4;
        heightfac = 1;
        hax{subfig_ind}.InnerPosition(1) = ax(sector_ind).xp(subplot_pos_ind);
        hax{subfig_ind}.InnerPosition(2) = ax(sector_ind).yp(subplot_pos_ind);
        hax{subfig_ind}.InnerPosition(3) = ax(sector_ind).xe*widthfac;
        hax{subfig_ind}.InnerPosition(4) = ax(sector_ind).ye*heightfac;
    end

    hold(hax{subfig_ind}, 'on')
    % yyaxis left
    hpl1{subfig_ind} = plot(hax{subfig_ind}, dummyvec, dummyvec, 'b-');
    if plotside
        hpl2{subfig_ind} = plot(hax{subfig_ind}, dummyvec, dummyvec, 'r-');
    end
    % yyaxis right
    % hpl3 = plot(hax, dummyvec, dummyvec, 'm-');
    % hpl4 = plot(hax, dummyvec, dummyvec, 'k-');

    hpt{subfig_ind} = patch(hax{subfig_ind}, dummyvec, dummyvec, dummyvec, 'EdgeColor','interp','LineWidth',1,'LineJoin','round');
    if subfig_ind~=1
        yline(hax{subfig_ind}, 5, 'k')
    end
    title('');
    hold(hax{subfig_ind}, 'off')

end


for j = 1:numel(allposxcrop)
    if ~isempty(allposxcrop{j})
        for subfig_ind = 1:3
            if subfig_ind==1
                hpl1{subfig_ind}.XData = dummyvec;
                hpl1{subfig_ind}.YData = dummyvec;
                hpl1{subfig_ind}.CData = dummyvec;
                allposxcrop{j}(end) = nan; %do this to make patch coloring work
                allposycrop{j}(end) = nan; %do this to make patch coloring work
                hpl1{subfig_ind}.XData(1:numel(allposxcrop{j})) = allposxcrop{j};
                hpl1{subfig_ind}.YData(1:numel(allposxcrop{j})) = allposycrop{j};
                hpt{subfig_ind}.XData(1:numel(allposxcrop{j})) = allposxcrop{j};
                hpt{subfig_ind}.YData(1:numel(allposxcrop{j})) = allposycrop{j};
                hpt{subfig_ind}.CData(1:numel(allposxcrop{j})) = 1:numel(allposycrop{j});
                if staticlims(subfig_ind)
                    hax{subfig_ind}.XLim = [minposx, maxposx];
                    hax{subfig_ind}.YLim = [minposy, maxposy];
                end
            elseif subfig_ind==2
                hpl1{subfig_ind}.YData = dummyvec;
                hpl1{subfig_ind}.XData(1:numel(allposxcrop{j})) = 1:numel(allvelx{j});
                hpl1{subfig_ind}.YData(1:numel(allposxcrop{j})) = allvelx{j};
                hax{subfig_ind}.YLim = [minvelx, maxvelx];
                if staticlims(subfig_ind)
                    hpl2{subfig_ind}.YData = dummyvec;
                end
                if plotside
                    hpl2{subfig_ind}.XData(1:numel(allposxcrop{j})) = 1:numel(allvely{j});
                    hpl2{subfig_ind}.YData(1:numel(allposxcrop{j})) = allvely{j};
                    if staticlims(subfig_ind)
                        hax{subfig_ind}.YLim = [minvelall, maxvelall];
                    end
                end
            elseif subfig_ind==3
                hpl1{subfig_ind}.YData = dummyvec;
                hpl1{subfig_ind}.XData(1:numel(allposxcrop{j})) = 1:numel(allvelxthresh{j});
                hpl1{subfig_ind}.YData(1:numel(allposxcrop{j})) = allvelxthresh{j};
                if staticlims(subfig_ind)
                    hax{subfig_ind}.YLim = [minvelx, maxvelx];
                end
                if plotside
                    hpl2{subfig_ind}.YData = dummyvec;
                    hpl2{subfig_ind}.XData(1:numel(allposxcrop{j})) = 1:numel(allvelythresh{j});
                    hpl2{subfig_ind}.YData(1:numel(allposxcrop{j})) = allvelythresh{j};
                    if staticlims(subfig_ind)
                        hax{subfig_ind}.YLim = [minvelall, maxvelall];
                    end
                end
            end
        end
        htx.String = strrep(fn{j}, '_', ' ');
        fig2gif(hfg, j, fngif_xyfs)
    end
end


% figure; plot(cumvelx)
% xline(12)
% xline(88)
% xline(240)
% median(cumvelx(1:88))
% median(cumvelx(89:240))
% median(cumvelx(240:end))



figure; plot(cumdistend);
%
% cc = sort(cumdistend(1:88), 'descend');
% cw = sort(cumdistend(89:108), 'descend');
% cp = sort(cumdistend(109:end), 'descend');
%
% median(cc(:))
% median(cw(:))
% median(cp(:))
%
% median(cc(1:20))
% median(cw(1:20))
% median(cp(1:20))
%
% median(cc(:))
% median(cp(1:88))
