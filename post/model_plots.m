
function model_plots(hsvmap, stim, resp, predresp, stackmean, ...
    epochinds, pixinds_roi, plotinds, hsv_background, ...
    max_tinds, timeseries_numsegments, ...
    ignorehue, ignoresat, ignoreval, ...
    responseplot_norm, plot_class, epochinds_str, ...
    pth_prefix, gif_visibility, objfcn, ft, supp, doplots)



%plots a square figure to make it easier to ensure native aspect ratios in subfigure
%it may not appear to be a square, but it is, as long as figsidelength does not exceed
%proportion of your screen's drawing area in its smaller dimension,
% which i've been unable to find programmatically so i recommend staying under 0.75

%top region is for FOV plots, which show each slice of the imaging top,
%either grayscale intensity, or hsv map of model fit params
%top plots can show pixels, or rois (multi-pixel regions)

% when the top aspect ratio is positive (larger
%width than height), as it usually is for our 2p imaging,
% it seems that top plots can be larger if the top plot region is at top, rather than at left
% so that is where they are plotted

%detail plots on individual rois/pixel are in the bottom section of the figure
%if there are multiple stim epochs, each row of the detail plots is a different epoch

%layout on bottom plots is constrained to make all y axes same length, and
%the unity plot square (same x and y axis length), then the fov plots fill
%the remaining space at top, at max size each without changing their aspect
%ratio (which is assumed constant, since they are slices from a single
%imaging movie)

%%plotting dimensions are:
% z slices in fov (can be all on one frame)
% stim dimensions in tuning curve (should be across frames, unless maybe if less than 5ish)
% model params as hsv in fov (can be all on one frame, esp if z slice is not)
% stim epochs in all plots (should be across frames since all plots, but can be all on one frame if z slice / model params are not)
% rois / pixels, in detail and crosshair (should be across frames)
% default should be all z slices on each frame, then across frames, in
% nested order from fastest to slowest changing: stim dim, model params, stim epochs, rois/pixels
% next priority is to make this nesting order variable with user input string
% next priority is changing from this general arrangement (e.g. something
% other than z slices be the param that appears all on one frame (first
% thought is stim epochs, since those are likely least numerous)
% define layout with "all_on_one_frame" string (zslice default), and
% "across_frame_nesting_order" with cell array of strings {stim dim, model
% params, stim epochs, rois/pixels}




%% params

hackstimdim = 1;

predresp_linewidth = 0.5;
predresp_transparency = 1;
numsampnan = 20;
figsidelength = 0.75; %figure size as proportion of your available screen small dimension (i cannot find the available size of your monitor bc it is not same as full size, so to be safe, keep this under 0.75 to prevent overfilling / causing nonsquare aspect)
mkrsz = 5;
r_val_dummy_single = 0.5;
fontsmall = 8;
fontmedium = 12;
fontlarge = 16;
fonthuge = 20;
quivercenter_xy = [1, 1];
quivermaxlen = 1;
supp_line_width = 2;
ncolgif = 128;
% axroomstim = range(stim(:))*0.1;
num_grayscales_bg = 256; %arbitrary


hfg = figure;
aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
close all



%% positions/sizes for detail plots on bottom (one row per epoch)

marginsbottom = 0.02;
leftmost_extra_margin = 0.04;

switch plot_class
    case 'hsv'
        numrowsbottom = 1;
    case 'epochs'
        numrowsbottom = length(epochinds);
end

numcolumnsbottom = 5; %really number grid lines in which the plots are arranged
numplotsbottom = numrowsbottom*numcolumnsbottom;

bottomregionminx = 0+marginsbottom+leftmost_extra_margin;
bottomregionmaxx = 1-marginsbottom;

xbot = linspace( bottomregionminx, bottomregionmaxx, numcolumnsbottom+1 ) ;
xbot = xbot(1:end-1); %xposition including labels (outer position)

wbotlab = bottomregionmaxx - xbot(end); %width including labels
wbot = wbotlab - marginsbottom;

hbotlab = wbotlab;
hbot = wbot; %force height to equal width to easily make square figs, make rectangles wih multiples of this width or height

bottomregionminy = 0+marginsbottom;
bottomregionmaxy = numrowsbottom*hbotlab + bottomregionminy; %topregionminy-marginsbottom;

ybot = bottomregionminy : hbotlab : bottomregionmaxy;
ybot = ybot(1:numrowsbottom);
ybot = flip(ybot); %make y order top to bottom (first epoch is on top)


%% positions/sizes for fov plots on top (maximum size that fits in top region and maintains each top's aspect ratio)

sgtitle_height = 0.02;

marginstop = 0.002; %y space between fov plots
regionheighttop = 1 - bottomregionmaxy - sgtitle_height;   %top area height, proportion of whole fig
regionwidthtop = 1-marginstop;     %top area width, proportion of whole fig
numplotstop = size(stackmean, 3); %number of tops
aspectfov = size(stackmean, 2) / size(stackmean, 1); % top aspect ratio

numrowstop = 1;
while numrowstop>0
    numcolumnstop = ceil(numplotstop/numrowstop);
    htop = (regionheighttop - (numrowstop - 1)*marginstop)/numrowstop;
    wtop = htop*aspectfov;

    if numcolumnstop * wtop + (numcolumnstop - 1)*marginstop > regionwidthtop
        numrowstop = numrowstop + 1;
    else
        break
    end
end

numcolumnstop2 = 1;
while numcolumnstop2>0
    numrowstop2 = ceil(numplotstop/numcolumnstop2);
    widthtop2 = (regionwidthtop - (numcolumnstop2 - 1)*marginstop)/numcolumnstop2;
    heighttop2 = widthtop2/aspectfov;

    if numrowstop2 * heighttop2 + (numrowstop2 - 1)*marginstop > regionheighttop
        numcolumnstop2 = numcolumnstop2 + 1;
    else
        break
    end
end

if widthtop2*heighttop2>wtop*htop %overwrite if 2nd loop found larger tops
    wtop = widthtop2;
    htop = heighttop2;
    numrowstop = numrowstop2;
    numcolumnstop = numcolumnstop2;
end

topregionminx = 0 + marginstop;
topregionmaxx = 0 + regionwidthtop;
topregionmaxy = 1-sgtitle_height;
topregionminy = topregionmaxy-regionheighttop;

xtop = topregionminx : wtop+marginstop : topregionmaxx;
xtop = xtop(1:numcolumnstop);

ytop = topregionminy : htop+marginstop : topregionmaxy;
ytop = ytop(1:numrowstop);
ytop = flip(ytop); %make y order top to bottom (first epoch is on top)



%% create FOV image (hsv or roi view)

cmapgray = colormap(gray(num_grayscales_bg));

stackmean = rescale(stackmean, 0, num_grayscales_bg-1);
stackmean = uint16(stackmean); %this will round to nearest int, we use ints because ind2rgb will map 0 to first value in cmap (which is zero/black)

size_imgnew = [size(stackmean, 1)  size(stackmean, 2)  size(stackmean, 3) 3];  %specify size(stackmean, 3) in case it's 1, to keep ndims(size_imgnew)==4
imgtmp = zeros(size_imgnew, 'single');
for si = 1:size(stackmean, 3)
    imgtmp(:,:,si,:) = ind2rgb(stackmean(:,:,si), cmapgray); %create the background FOV intensity grayscale (may not get used though)
end
imgtmp = reshape(imgtmp, [], size(imgtmp, 4)); %collapse spatial dimensions to make pixel by time


img = cell(1, length(epochinds));
for epi = 1:length(epochinds)

    if ignorehue
        hsvmap{epi}(:,1) = 1;
    end
    if ignoresat
        hsvmap{epi}(:,2) = 1;
    end
    if ignoreval
        hsvmap{epi}(:,3) = 1;
    end

    switch hsv_background
        case 'pixels'

            imgtmptmp = imgtmp;
            imgtmptmp(cell2mat(pixinds_roi), :) = hsv2rgb( hsvmap{epi} );
            img{epi} = reshape(imgtmptmp, size_imgnew);
            imgtmptmp = [];

        case 'rois'

            "need to fix plotinds for rois"
            imgtmp = repmat(imgtmp, [ones(1, ndims(imgtmp)) length(pixinds_roi)]);
            rgbmap = cell(1, length(pixinds_roi));
            for ri = 1:length(pixinds_roi)
                rgbmap{ri} = hsv2rgb( hsvmap{epi}(ri, :));
                rgbmap{ri} = repmat(rgbmap{ri}, [numel(pixinds_roi{ri}) 1]);
                imgtmp(pixinds_roi{ri}, :, ri) = rgbmap{ri};
            end
            imbg = mean(imgtmp, 3);
            img{epi} = repmat(imbg, [1 1 length(pixinds_roi)]);
            for ri = 1:length(pixinds_roi)
                img{epi}(pixinds_roi{ri}, :, ri) = rgbmap{ri};
            end
            img{epi} = reshape(img{epi}, [size_imgnew, size(img{epi}, 3)]);

        case 'raw'

    end

end

%% prepare some plotting variables


stimsort = cell(1, length(epochinds));
predresp_sort = cell(1, length(epochinds));
tinds = cell(1, length(epochinds));
truncstr = cell(1, length(epochinds));
seglength = cell(1, length(epochinds));
for epi = 1:length(epochinds)

    [stimsort{epi}, stimsortidx] = sort(stim{epi}(:,hackstimdim));
    predresp_sort{epi} = predresp{epi}(:, stimsortidx);

    if isempty(max_tinds) || max_tinds > size(resp{epi}, 2)  %if too many samples to see, plot only the first max_tinds of them
        tinds{epi} = 1:size(resp{epi}, 2);
        truncstr{epi} = '';
    else
        if timeseries_numsegments>1
            seglength{epi} = floor(max_tinds/timeseries_numsegments);
            segspacing = floor(size(resp{epi}, 2)/timeseries_numsegments);
            tinds{epi} = [1:seglength{epi}]+segspacing*([1:timeseries_numsegments]'-1)+segspacing-seglength{epi};
            truncstr{epi} = ['TRUNC' num2str(timeseries_numsegments) 'SEG'];
        else
            tinds{epi} = 1:max_tinds;
            truncstr{epi} = ['TRUNC1SEG'];
        end
    end
end

minis =  min(cell2mat(cellfun(@(x) min(x(:)),  resp,  'UniformOutput',  false))); %min response across all epochs
maxis =  max(cell2mat(cellfun(@(x) max(x(:)),  resp,  'UniformOutput',  false))); %max response across all epochs

epochinds_str_all = strjoin(epochinds_str, ',,');



%% FOV, RESPONSES, AND MODEL PLOTS

if doplots(1)

    title_add_each = 'MODELFIT';
    figext = '.gif';

    filename_save = [pth_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = strrep(tittmp{end}, '_', ' ');


    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
    if aspect_screen>1
        hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
    else
        hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
    end
    bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( 0.02, 0.99, '', 'FontSize', fontmedium, ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;


    totalplotframes = length(plotinds)*length(epochinds);

    for plotframecount = 1:totalplotframes

        epi = ceil(plotframecount/length(plotinds)); %index into epochinds
        ri = mod(plotframecount-1, length(plotinds))+1; %index into plotinds

        if seglength{epi}
            respadj = [];
            predrespadj = [];
            for tnsi = 1:timeseries_numsegments
                seginds = [1:seglength{epi}]+seglength{epi}*(tnsi-1);
                respadj = cat(2, respadj, resp{epi}( ri, seginds), nan(1, numsampnan));
                predrespadj = cat(2, predrespadj, predresp{epi}( ri, seginds), nan(1, numsampnan));
            end
        end

        [py, px, pz] = ind2sub(size(stackmean), pixinds_roi{plotinds(ri)}); %y, x, z of selected pixel

        if strcmp(hsv_background, 'pixels')
            htx.String = [figure_title ' --- roi centroid (xyz): ' num2str(py) ' ' num2str(py) ' ' num2str(pz)];
        else
            htx.String = [figure_title];
        end

        if strcmp(responseplot_norm, 'each') %scale for each roi scanges, if responseplot_norm is 'each' rather than 'all'
            minis = min([resp{epi}( ri, :) predresp{epi}( ri, :)]);
            maxis = max([resp{epi}( ri, :) predresp{epi}( ri, :)]);
        end


        zslicecount = 0; %this variable is redundant with sit, but keeping it for clarity (and future flexibility)
        for sit = 1:numplotstop

            [cit, rit] = ind2sub([numcolumnstop, numrowstop], sit); %reverse output since subplots are column-major
            zslicecount = zslicecount+1;

            if plotframecount==1

                if zslicecount<size(img{epi}, 3)+1
                    hat{sit} = axes( 'Parent', hfg, 'Position', [xtop(cit), ytop(rit), wtop, htop] );
                    hold(hat{sit}, 'on');
                    switch hsv_background
                        case 'pixels'
                            hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:)));
                        case 'rois'
                            hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:,ri)));
                    end
                    axis image %should not have to call axis image because of how subfig width/height were calculated to maintain aspect ratio above
                    axis off
                    axis ij
                    if strcmp(hsv_background, 'pixels')
                        if zslicecount==pz
                            hp2t{sit} = xline(hat{sit}, px, 'w', 'LineStyle', '-');
                            hp3t{sit} = yline(hat{sit}, py, 'w', 'LineStyle', '-');
                        else
                            hp2t{sit} = xline(hat{sit}, px, 'w', 'LineStyle', 'none');
                            hp3t{sit} = yline(hat{sit}, py, 'w', 'LineStyle', 'none');
                        end
                    end
                end


            elseif plotframecount>1

                if zslicecount<size(img{epi}, 3)+1

                    switch hsv_background
                        case 'pixels'
                            hp1t{sit}.CData = squeeze(img{epi}(:,:,zslicecount,:));
                        case 'rois'
                            hp1t{sit}.CData = squeeze(img{epi}(:,:,zslicecount,:,ri));
                    end

                    if strcmp(hsv_background, 'pixels')
                        if zslicecount==pz
                            hp2t{sit}.Value = px;
                            hp3t{sit}.Value = py;
                            hp2t{sit}.LineStyle = '-';
                            hp3t{sit}.LineStyle = '-';
                        else
                            hp2t{sit}.LineStyle = 'none';
                            hp3t{sit}.LineStyle = 'none';
                        end
                    end
                end
            end


        end




        for sib = 1:numplotsbottom

            [cib, rib] = ind2sub([numcolumnsbottom, numrowsbottom], sib);

            if cib == 1 %occupies cib 1 and 2 (bottom column 1 and 2, ie double width column)

                if plotframecount==1

                    hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot*2, hbot] );
                    hold(hab{sib}, 'on');
                    hp1b{sib} = plot(hab{sib}, respadj, 'color', [0 0 1]);
                    hp2b{sib} = plot(hab{sib}, predrespadj, 'color', [1 0 0]);
                    yline(hab{sib}, 0)

                    xlm = hab{sib}.XLim;
                    hab{sib}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                    hab{sib}.XAxis.TickLabelFormat = '%.1f';
                    hab{sib}.XAxis.FontSize = fontsmall;

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabelFormat = '%.1f';
                    hab{sib}.YAxis.FontSize = fontsmall;

                    xlabel('time (sec)', 'fontsize', fontsmall)
                    ylabel('dff', 'fontsize', fontsmall)
                    if rib==1
                        title(hab{sib}, ['pred(r) resp (b) ' truncstr{epi}], 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    if rib~=numrowsbottom
                        hab{sib}.XAxis.Visible='off';
                    end
                    hold(hab{sib}, 'off');


                else

                    hp1b{sib}.YData = respadj;
                    hp2b{sib}.YData = predrespadj;

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabelFormat = '%.1f';
                    hab{sib}.YAxis.FontSize = fontsmall;

                end

            elseif cib == 3

                if plotframecount==1

                    hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot, hbot] );
                    hold(hab{sib}, 'on');
                    hp1b{sib} = scatter(hab{sib}, resp{epi}( ri, :), predresp{epi}( ri, :), 5, 'filled');
                    hp2b{sib} = plot(resp{epi}( ri,  :), resp{epi}( ri,  :), 'k');
                    if strcmp(hsv_background, 'rois') %0 is meaningful if passing dff, for now only data in rois method uses dff
                        xline(hab{sib}, 0)
                        yline(hab{sib}, 0)
                    end


                    hab{sib}.XLim = [minis maxis];
                    xlm = hab{sib}.XLim;
                    hab{sib}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                    hab{sib}.XAxis.TickLabelFormat = '%.1f';
                    hab{sib}.XAxis.FontSize = fontsmall;

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabel = [];


                    xlabel('resp', 'fontsize', fontsmall)
                    %ylabel('pred')
                    if rib==1
                        title(hab{sib}, 'pred vs resp', 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    if rib~=numrowsbottom
                        hab{sib}.XAxis.Visible='off';
                    end
                    hold(hab{sib}, 'off');


                else

                    hp1b{sib}.XData = resp{epi}(ri, :);
                    hp1b{sib}.YData = predresp{epi}(ri, :);
                    hp2b{sib}.XData = resp{epi}(ri, :);
                    hp2b{sib}.YData = resp{epi}(ri, :);

                    hab{sib}.XLim = [minis maxis];
                    xlm = hab{sib}.XLim;
                    hab{sib}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabel = [];



                end

            elseif cib == 4

                if plotframecount==1

                    hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot, hbot] );
                    hold(hab{sib}, 'on');
                    hp1b{sib} = scatter(hab{sib}, stim{epi}(:,end), resp{epi}(ri, :), 5, 'filled');
                    hp2b{sib} = plot(hab{sib}, stimsort{epi}, predresp_sort{epi}(ri, :), 'LineWidth', predresp_linewidth, 'Color', [1, 0, 0, predresp_transparency]);
                    yline(hab{sib}, 0)

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabel = [];

                    xlabel('stim sorted', 'fontsize', fontsmall)
                    % ylabel('dff')
                    if rib==1
                        title(hab{sib}, 'resp vs stimlag', 'fontsize', fontsmall); %raw resp tuning for raw stim raw, response vs raw stim, doesn't include any invalid first indices in resp (if model samples>1)
                    end
                    if rib~=numrowsbottom
                        hab{sib}.XAxis.Visible='off';
                    end
                    hold(hab{sib}, 'off');

                else

                    hp1b{sib}.XData = stim{epi}(:,hackstimdim);
                    hp1b{sib}.YData = resp{epi}(ri, :);
                    hp2b{sib}.XData = stimsort{epi};
                    hp2b{sib}.YData = predresp_sort{epi}(ri, :);

                    hab{sib}.YLim = [minis maxis];
                    ylm = hab{sib}.YLim;
                    hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hab{sib}.YAxis.TickLabel = [];


                end



            end

        end



        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncolgif);

        if plotframecount==1
            imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
        end


    end


end


%%  FOV PLOT ONLY


if doplots(2)

    title_add_each = 'FOV';
    figext = '.gif';
    filename_save = [pth_prefix '_' title_add_each '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};


    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;

    plotframecount = 0;
    zslicecount = 0;
    for sit = 1:numplotstop
        plotframecount = plotframecount+1;

        [cit, rit] = ind2sub([numrowstop, numcolumnstop], sit); %reverse output since subplots are column-major
        zslicecount = zslicecount+1;


        if zslicecount<size(img{epi}, 3)+1
            hat{sit} = axes( 'Parent', hfg, 'Position', [0 0 1 1] );
            hold(hat{sit}, 'on');
            switch hsv_background
                case 'pixels'
                    hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:)));
                case 'rois'
                    hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:,ri)));
            end
            axis image %should not have to call axis image because of how subfig width/height were calculated to maintain aspect ratio above
            axis off
            axis ij
        end

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncolgif);

        if plotframecount==1
            imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
        end


    end

end

%% TIMESERIES PLOTS ONLY


if doplots(3)

    title_add_each = 'TIMESERIES';
    figext = '.gif';
    filename_save = [pth_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = strrep(tittmp{end}, '_', ' ');

    numseg = 4;
    numsampresp = size(resp{epi}, 2);
    numsampseg = ceil(numsampresp / numseg);

    numrows_ts = numseg;
    numcolumns_ts = 1;
    margins_fig = 0.04;
    margins_subfig = 0.02;

    [axx, axy, axw, axh] = arrange_subplots(numrows_ts, numcolumns_ts, margins_fig, margins_subfig);

    minis =  min(cell2mat(cellfun(@(x) min(x(:)),  resp,  'UniformOutput',  false))); %min response across all epochs
    maxis =  max(cell2mat(cellfun(@(x) max(x(:)),  resp,  'UniformOutput',  false))); %max response across all epochs
    minis2 =  min(cell2mat(cellfun(@(x) min(x(:)),  predresp,  'UniformOutput',  false))); %min response across all epochs
    maxis2 =  max(cell2mat(cellfun(@(x) max(x(:)),  predresp,  'UniformOutput',  false))); %max response across all epochs
    minis = min(minis, minis2);
    maxis = max(maxis, maxis2);

    hfg = figure('Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility) ;
    hfg.Position = [0 0.2 0.8 0.6]; %make square inner size (excludes top menu bar), plot in bottom left

    bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( 0.02, 1-margins_fig/2, '', 'FontSize', fontsmall, ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
    htx.String = [figure_title];


    for ri = 1:size(resp{epi}, 1)

        for nsi = 1:numseg
            tindstmp = [1:numsampseg]+numsampseg*(nsi-1);
            tindstmp(tindstmp>numsampresp) = [];
            if ri==1

                hax{nsi} = axes( 'Parent', hfg, 'Position', [axx(nsi), axy(nsi), axw, axh] );
                hold(hax{nsi}, 'on')
                hpl{nsi} = plot(hax{nsi}, resp{epi}(ri, tindstmp));
                hpl2{nsi} = plot(hax{nsi}, predresp{epi}(ri, tindstmp));

                if nsi==numseg

                    xlm = hax{nsi}.XLim;
                    hax{nsi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 6);
                    hax{nsi}.XAxis.TickLabelFormat = '%.1f';
                    hax{nsi}.XAxis.FontSize = fontsmall;

                    hax{nsi}.YLim = [minis maxis];
                    ylm = hax{nsi}.YLim;
                    hax{nsi}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hax{nsi}.YAxis.TickLabelFormat = '%.1f';
                    hax{nsi}.YAxis.FontSize = fontsmall;

                else
                    hax{nsi}.XAxis.TickLabels = [];
                    hax{nsi}.YAxis.TickLabels = [];
                end

            else

                hpl{nsi}.YData = resp{epi}(ri, tindstmp);
                hpl2{nsi}.YData = predresp{epi}(ri, tindstmp);

            end
        end

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, ncolgif);

        if ri==1
            imwrite(imind, cm, filename_save, 'DelayTime', 0, 'Loopcount', inf);
        else
            imwrite(imind, cm, filename_save,'DelayTime', 0, 'WriteMode', 'append');
        end


    end


end

if doplots(4)


    if isequal(objfcn, @fit_svd)
        % plot_svd(ft{epi})
    else
        objfcn(ft{epi}, stim{epi}, supp, pth_prefix);
    end


end


close all



