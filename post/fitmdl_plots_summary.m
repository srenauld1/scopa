function fitmdl_plots_summary(fitin, opts, roiinfo, stackmean)

plt = fitin.plt;
supp = fitin.supp;

mdl = fitin.opop.mdl;
num_dim_depvpre = fitin.num_dim_depvpre;

standardize_depv = opts.standardize_depv;
epochinds = opts.epochinds;

pixinds_roi = roiinfo.pixinds_roi;
mapind2ind = roiinfo.mapind2ind;

gif_visibility = plt.gif_visibility;
doplots = plt.doplots;
hsv_background = plt.hsv_background;
max_tinds = plt.max_tinds;
timeseries_numsegments = plt.timeseries_numsegments;
ignorehue = plt.ignorehue;
ignoresat = plt.ignoresat;
ignoreval = plt.ignoreval;
depvplot_norm = plt.depvplot_norm;
plot_class = plt.plot_class;

%% params

hackindvdim = 1; %haven't yet expanded this plotting function for multidimensional indvuli, for now just choosing one dim

depvp_linewidth = 0.5;
depvp_transparency = 1;
numsampnan = 10;
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
% axroomindv = range(indv(:))*0.1;
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

% [xbot2, ybot2, wbot2, hbot2] = arrange_subplots(numrowsbottom, numcolumnsbottom, margins_fig, marginsbottom);

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

            "need to fix roiinds_plot for rois"
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


%% FOV, DEPVS, AND MODEL PLOTS


title_add_each = 'MODELFIT';
figext = '.gif';

filename_save = [pth_fitdata_prefix '_' title_add_each '_e_' epochinds_str_all '_' figext];
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


totalplotframes = length(roiinds_plot)*length(epochinds);

for framecount = 1:totalplotframes

    epi = ceil(framecount/length(roiinds_plot)); %index into epochinds
    ri = mod(framecount-1, length(roiinds_plot))+1; %index into roiinds_plot

    [py, px, pz] = ind2sub(size(stackmean), pixinds_roi{roiinds_plot(ri)}); %y, x, z of selected pixel

    if strcmp(hsv_background, 'pixels')
        htx.String = [figure_title ' --- roi centroid (xyz): ' num2str(py) ' ' num2str(py) ' ' num2str(pz)];
    else
        htx.String = [figure_title];
    end

    if strcmp(depvplot_norm, 'each') %scale for each roi scanges, if depvplot_norm is 'each' rather than 'all'
        minis = min([depv{epi}( ri, :) depvp{epi}( ri, :)]);
        maxis = max([depv{epi}( ri, :) depvp{epi}( ri, :)]);
    end


    zslicecount = 0; %this variable is redundant with sit, but keeping it for clarity (and future flexibility)
    for sit = 1:numplotstop

        [cit, rit] = ind2sub([numcolumnstop, numrowstop], sit); %reverse output since subplots are column-major
        zslicecount = zslicecount+1;

        if framecount==1

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


        elseif framecount>1

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

            if framecount==1

                hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot*2, hbot] );
                hold(hab{sib}, 'on');
                hp1b{sib} = plot(hab{sib}, depvnan_seg{epi}( ri, :), 'color', [0 0 1]);
                hp2b{sib} = plot(hab{sib}, depvpnan_seg{epi}( ri, :), 'color', [1 0 0]);
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
                    title(hab{sib}, ['pred(r) depv (b) ' truncstr{epi}], 'fontsize', fontsmall); %model-extracted feature (depvp) tuning for raw indv
                end
                if rib~=numrowsbottom
                    hab{sib}.XAxis.Visible='off';
                end
                hold(hab{sib}, 'off');


            else

                hp1b{sib}.YData = depvnan_seg{epi}( ri, :);
                hp2b{sib}.YData = depvpnan_seg{epi}( ri, :);

                hab{sib}.YLim = [minis maxis];
                ylm = hab{sib}.YLim;
                hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                hab{sib}.YAxis.TickLabelFormat = '%.1f';
                hab{sib}.YAxis.FontSize = fontsmall;

            end

        elseif cib == 3

            if framecount==1

                hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot, hbot] );
                hold(hab{sib}, 'on');
                hp1b{sib} = scatter(hab{sib}, depv{epi}( ri, :), depvp{epi}( ri, :), 5, 'filled');
                hp2b{sib} = plot(depv{epi}( ri,  :), depv{epi}( ri,  :), 'k');
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


                xlabel('depv', 'fontsize', fontsmall)
                %ylabel('pred')
                if rib==1
                    title(hab{sib}, 'pred vs depv', 'fontsize', fontsmall); %model-extracted feature (depvp) tuning for raw indv
                end
                if rib~=numrowsbottom
                    hab{sib}.XAxis.Visible='off';
                end
                hold(hab{sib}, 'off');


            else

                hp1b{sib}.XData = depv{epi}(ri, :);
                hp1b{sib}.YData = depvp{epi}(ri, :);
                hp2b{sib}.XData = depv{epi}(ri, :);
                hp2b{sib}.YData = depv{epi}(ri, :);

                hab{sib}.XLim = [minis maxis];
                xlm = hab{sib}.XLim;
                hab{sib}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);

                hab{sib}.YLim = [minis maxis];
                ylm = hab{sib}.YLim;
                hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                hab{sib}.YAxis.TickLabel = [];



            end

        elseif cib == 4

            if framecount==1

                hab{sib} = axes( 'Parent', hfg, 'Position', [xbot(cib), ybot(rib), wbot, hbot] );
                hold(hab{sib}, 'on');
                hp1b{sib} = scatter(hab{sib}, indv{epi}(:, hackindvdim), depv{epi}(ri, :), 5, 'filled');
                hp2b{sib} = plot(hab{sib}, indvsort{epi}, depvp_sort{epi}(ri, :), 'LineWidth', depvp_linewidth, 'Color', [1, 0, 0, depvp_transparency]);
                yline(hab{sib}, 0)

                hab{sib}.YLim = [minis maxis];
                ylm = hab{sib}.YLim;
                hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                hab{sib}.YAxis.TickLabel = [];

                xlabel('indv sorted', 'fontsize', fontsmall)
                % ylabel('dff')
                if rib==1
                    title(hab{sib}, 'depv vs indvlag', 'fontsize', fontsmall); %raw depv tuning for raw indv raw, depv vs raw indv, doesn't include any invalid first indices in depv (if model samples>1)
                end
                if rib~=numrowsbottom
                    hab{sib}.XAxis.Visible='off';
                end
                hold(hab{sib}, 'off');

            else

                hp1b{sib}.XData = indv{epi}(:,hackindvdim);
                hp1b{sib}.YData = depv{epi}(ri, :);
                hp2b{sib}.XData = indvsort{epi};
                hp2b{sib}.YData = depvp_sort{epi}(ri, :);

                hab{sib}.YLim = [minis maxis];
                ylm = hab{sib}.YLim;
                hab{sib}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                hab{sib}.YAxis.TickLabel = [];


            end



        end

    end


    fig2gif(hfg, framecount, filename_save)



end


