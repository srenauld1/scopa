

        fvd = ts.ball.forvel;
        fvd = smoothdata(fvd, 'gaussian', 12, 'omitnan');
        fvd = abs(fvd);
        stimthresh = 0.05;
        % tsplt(fvd, xseg=1); yline(stimthresh, 'm')
        kpstim = fvd<stimthresh;
        kpstim2 = smoothdata(kpstim, 'gaussian', 20, 'omitnan');
        kpstim2 = logical(kpstim2);
        save('~/stacks/muk.mat', 'kpstim2', '-v7.3', '-mat')
        % tsplt(kpstim, y2=kpstim2/2, xseg=30, ymatch=1);

        rsp2 = reshape(stackcrop(:,:,:,:,1), [], size(stackcrop, 4));
        [~, pwr] = wavflt(rsp2, t=ts.t, wavp=[0 5]);

        respstd = std(reshape(stackcrop(:,:,:,:,1), [], size(stackcrop, 4)), 1, 2); %making 2nd argument 1 normalizes by n, making it 0 normalizes by n-1

        imhsv = [];
        imhsv.fg = 'pixels';
        imhsv = default_hsv_opts(imhsv);
        imhsv = plots_setup_hsv(imhsv);

        stackmnt = mean(stackcrop(:,:,:,:,1), 4);
        roipxall = num2cell(1:numel(stackmnt));

        pwrind = 1;
        imhsvall = zeros([size(stackmnt) 3 size(pwr,2)], 'uint8');
        for kk = 1:size(pwr,2)
            hsvmap = hsvcmp(imhsv, hueft=[], satft=pwr(:,kk,pwrind), valft=respstd);
            imhsvall(:,:,:,:,kk) = hsvplt(imhsv, stackmnt, hsvmap, roipxall);
        end

        stackplt(squeeze(imhsvall(:,:,:,2,:)), fdimnum=3)