function plot_data(inp, opt, params, pthgif, inp2, inp3, running, simultaneous)

if ~exist('running', 'var')
    running = 0;
end
if ~exist('simultaneous', 'var')
    simultaneous = 0;
end


if simultaneous & iscell(inp)
    error
end

ncol = 256;
limfac = 0.1;


if strcmp(opt, 'resp')

    h3 = figure; hold on;

    if exist('inp3', 'var') & ~isempty(inp3)
        ax1 = subplot(2,1,1);
        ax2 = subplot(2,1,2);
    else
        ax1 = subplot(1,1,1);
    end

    if iscell(inp)
        alldat = vec(cell2mat(inp));
        numloops = length(inp);
        xmax = max(cellfun(@length, inp), 'all');
    else
        alldat = vec(inp);
        numloops = size(inp, 1);
        xmax = length(size(inp, 2));
    end

    if exist('inp2', 'var') & ~isempty(inp2)
        alldat = cat(1, alldat, inp2(:));
        plot(ax1, inp2, 'color', [0 0 0 0.5])
    end

    xmin = 0;
    xext = abs(xmax - xmin)*limfac;
    xlnew = [xmin - xext, xmax + xext];
    %xlnew = [xmin - abs(xmin)*limfac, xmax + abs(xmax)*limfac];
    ymin = min(alldat(:));
    ymax = max(alldat(:));
    yext = abs(ymax - ymin)*limfac;
    ylnew = [ymin - yext, ymax + yext];
    % ylnew = [ymin - abs(ymin)*limfac, ymax + abs(ymax)*limfac];

    if exist('inp3', 'var') & ~isempty(inp3)
        alldat2 = cell2mat(inp3);
        xmin2 = min(alldat2(1,:));
        xmax2 = max(alldat2(1,:));
        xext2 = abs(xmax2 - xmin2)*limfac;
        xlnew2 = [xmin2 - xext2, xmax2 + xext2];
        %xlnew2 = [xmin2 - abs(xmin2)*limfac, xmax2 + abs(xmax2)*limfac];
        ymin2 = min(alldat2(2,:));
        ymax2 = max(alldat2(2,:));
        yext2 = abs(ymax2 - ymin2)*limfac;
        ylnew2 = [ymin2 - yext2, ymax2 + yext2];
        if xlnew2(1)<ylnew2(1)
            ylnew2(1) = xlnew2(1);
        end
        if xlnew2(2)>ylnew2(2)
            ylnew2(2) = xlnew2(2);
        end
        %ylnew2 = [ymin2 - abs(ymin2)*limfac, ymax2 + abs(ymax2)*limfac];
    end

    if simultaneous
        svitmp = 1;
        svichoose{1} = [1:size(inp, 1)];
        colone = '-k';
    else
        svitmp = 1:numloops;
        for sstmp = 1:size(inp, 1)
            svichoose{sstmp} = sstmp;
        end
        colone = '-r';
    end

    for svi = svitmp

        axes(ax1)
        hold on;
        if iscell(inp)
            timb = 1:length(inp{svi});
        else
            timb = 1:size(inp, 2);
        end
        if running
            runwnd = 200;
            stridewnd = 50;
            total_time_plots = numel(timb) - runwnd;
        else
            runwnd = size(inp, 2);
            stridewnd = 1;
            total_time_plots = 1;
        end

        for k = 1:stridewnd:total_time_plots
            %pause(0.0001)
            if iscell(inp)
                %c1 = plot(ax1, inp{svi}, 'r');
                c1 = plot(ax1, timb(k:k+runwnd-1), inp{svichoose{svi}}(k:k+runwnd-1), colone);
            else
                %c1 = plot(ax1, inp(svi,:), 'r');
                c1 = plot(ax1, timb(k:k+runwnd-1), inp(svichoose{svi},k:k+runwnd-1), colone);
            end

            if running
                xlim([timb(k) timb(k+runwnd-1)])
            else
                ylim(xlnew)
            end
            ylim(ylnew)

            yline(0, 'color', [0 0 0 0.2])
            if isnumeric(params(svichoose{svi},:))
                paramtit = num2str(params(svichoose{svi},:));
            else
                paramtit = params(svichoose{svi},:);
            end
            if svichoose{svi}==44
                fuk=2
            end
            if iscell(paramtit)
                paramtit = cellfun(@(x)strrep(x, '_', ' '), paramtit, 'UniformOutput', false);
                %paramtit = cellfun(@(x)strrep(x, '*', 'STAR'), paramtit, 'UniformOutput', false);
            end
            title(paramtit)

            if exist('inp3', 'var') & ~isempty(inp3)
                axes(ax2)
                c2 = plot(ax2, inp3{svi}(1,:), inp3{svi}(2,:));
                yline([xmin2 xmax2], 'color', [1 0 1 0.2])
                if running | simultaneous
                    "NEED TO DECIDE HOW TO SET XLIM WITH RUNNING AND INP3"
                    error
                end
                xlim(xlnew2)
                ylim(ylnew2)
            end

            fig2gif(h3, min(svichoose{svi}), pthgif)

            if running
                hold(ax1, 'on')
            else
                delete(c1);
            end
            if exist('inp3', 'var') & ~isempty(inp3)
                delete(c2);
            end
        end
    end

elseif strcmp(opt, 'hist')

    pthgif = ['~/Documents/ambrose/filtergifs/' datestr(now,30) '_respsyn_.gif'];
    h = figure; hold on;
    if exist('inp2', 'var')
        h1 = histogram(vec(inp2));
        h1.FaceColor = 'k';
    end
    for svi = 1:length(inp)
        h2 = histogram(inp{svi}(:));
        h2.FaceColor = 'r';

        fig2gif(h, svi, pthgif)
        
        delete(h2);
    end



end