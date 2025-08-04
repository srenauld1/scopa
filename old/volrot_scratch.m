
%apply rotation, center new image, recover original point; this is how you
%find new point with forward or original point with inverse

rot = 10;
pt1i = [10,25,30];

tform = rigidtform3d([rot,0,0], [0,0,0]);
[tmp, ov2] = imwarp(stackup, imref3d(size(stackup)), tform); %default output view is centeroutput

[pt2w(1),pt2w(2),pt2w(3)] = transformPointsForward(tform, pt1i(1), pt1i(2), pt1i(3));
pt2i = pt2w - fix([ov2.XWorldLimits(1), ov2.YWorldLimits(1), ov2.ZWorldLimits(1)]);
pt3w = pt2i + fix([ov2.XWorldLimits(1), ov2.YWorldLimits(1), ov2.ZWorldLimits(1)]);
[pt4i(1),pt4i(2),pt4i(3)] = transformPointsInverse(tform, pt3w(1), pt3w(2), pt3w(3));

[pt1i; pt4i]


if ndims(stackmnt)<3
                error("stackseg 'torus' requires nonsingleton yxz dimensions (can't be planar right now)")
            end


            sznew = 40; %max(size(stackmnt));
            stackup = imresize3(stackmnt, [sznew, sznew, sznew], 'linear');
            rots = linspace(0, 180, 19);
            rots = rots(1:end-1);
            stackmnzrot = zeros(size(stackup,1), size(stackup,1), numel(rots));
            hfg = figure;
            for k = 1:numel(rots)
                tmp = imrotate3(stackup, rots(k), [1 0 0], 'linear', 'crop');
                tmp = mean(tmp, 3);
                if k==1
                    hpl = imagesc(tmp);
                else
                    hpl.CData = tmp;
                end
                hfg.Children.Title.String = mean(tmp(:));
                fig2gif(hfg, k)
                stackmnzrot(:,:,k) = tmp;
            end
            stackplt(stackmnzrot, title_prefix=['rotations: ' num2str(rots)]);

            prompt = sprintf("ENTER DEGREES TO ROTATE STACK FORWARD (ALONG X AXIS), OR EMPTY TO NOT ROTATE: ");
            commandwindow();
            drawrot = input(prompt);
            if drawrot
                szpad = sznew;
                stackrot = imrotate3(stackup, drawrot, [1 0 0], 'linear', 'crop');
            else
                szpad = 0;
                stackrot = stackup;
            end

            stackplt(stackrot)
            prompt = sprintf("ENTER Z-INDICES YOU WANT TO SUM TO CREATE BACKGROUND FOR MANUALLY POSITIONING ROI CENTROIDS (MEAN OF CHOSEN Z INDICES WILL BE Z COORDINATE FOR ROI CENTROIDS), OR ENTER NOTHING TO POSITION CENTROIDS ON ALL Z SLICES SEPARATELY: ");
            commandwindow();
            drawslice = input(prompt);

            [cenperm, midx, midy] = drawcent(stackrot, drawslice, numroi_init);

            cenperm = cenperm + szpad;
            upfac = size(stackmnt) / sznew;
            cenperm = cenperm .* upfac;
            midy = midy * upfac(1);
            midx = midx * upfac(2);


            hfg = figure;
            imagesc(stackrot) 
            colormap(bone)
            hold on
            plot(midx, midy, 'w')
            cmap = distinguishable_colors(numroi_init);
            scatter(cenperm(:,2), cenperm(:,1), [], cmap, 'filled')
            axis equal tight
            fig2gif(hfg, 1, pathauto(suffix='.gif', usetime=1))
            close(hfg);

            %%

            stackuppad = padarray(stackup, [szpad szpad szpad], nan, 'both');
            stackuppad = stackup;

            rots = linspace(0, 90, 19);
            rots = rots(1:end-1);
            % rots = -60;
            hfg = figure;
            for k = 1:numel(rots)
                
                ov = imref3d(size(stackuppad));
                tX = mean(ov.XWorldLimits);
                tY = mean(ov.YWorldLimits)*const;
                tZ = mean(ov.ZWorldLimits)*const;
                tlc2o = [1 0 0 -tX; 0 1 0 -tY; 0 0 1 -tZ; 0 0 0 1];
                rt = [1 0 0 0; 0 cosd(rots(k)) -sind(rots(k)) 0; 0 sind(rots(k)) cosd(rots(k)) 0; 0 0 0 1];
                tlo2c = [1 0 0 tX; 0 1 0 tY; 0 0 1 tZ; 0 0 0 1];
                rtcnt = tlc2o*rt*tlo2c;
                tform = rigidtform3d(rtcnt);

                tform = rigidtform3d([rots(k),0,0], [0,0,0]);

                % theta = [rots(k) 0 0];
                % transl = size(stackuppad)/2*1;
                % tform = rigidtform3d(theta, transl); %rigidtform3d angle is negative of imrotate3

                % ov = affineOutputView(size(stackuppad),tform,"BoundsStyle","SameAsInput");
                [tmp,ov2] = imwarp(stackuppad,ov,tform);
                tmp = mean(tmp, 3, 'omitmissing');

                if k==1
                    hpl = imagesc(tmp);
                else
                    hpl.CData = tmp;
                end
                hfg.Children.Title.String = mean(tmp(:));
                fig2gif(hfg, k)
            end
            %% 

            tform = rigidtform3d(theta, transl); %rigidtform3d angle is negative of imrotate3
            ov = affineOutputView(size(stackuppad),tform,"BoundsStyle","SameAsInput");
            volrotf = imwarp(stackuppad,tform,"OutputView",ov);
            stackplt(mean(volrotf,3, 'omitmissing'))

            %% 



            ov = imref3d(size(stackup)); 
            tX = mean(ov.XWorldLimits);
            tY = mean(ov.YWorldLimits);
            tZ = mean(ov.ZWorldLimits);
            tlc2o = [1 0 0 -tX; 0 1 0 -tY; 0 0 1 -tZ; 0 0 0 1];
            rt = [1 0 0 0; 0 cosd(drawrot) -sind(drawrot) 0; 0 sind(drawrot) cosd(drawrot) 0; 0 0 0 1];
            tlo2c = [1 0 0 tX; 0 1 0 tY; 0 0 1 tZ; 0 0 0 1];
            rtcnt = tlc2o*rt*tlo2c;
            tform = rigidtform3d(rtcnt);
            ov = affineOutputView(size(stackup),tform,"BoundsStyle","SameAsInput");
            volrotf = imwarp(stackup,tform,"OutputView",ov);
            stackplt(mean(volrotf,3, 'omitmissing'))
%% 

            cenperm_xyz = [cenperm(:,2), cenperm(:,1), cenperm(:,3)];
            U = transformPointsInverse(tform, cenperm_xyz);
            cenperm3 = [U(:,2), U(:,1), U(:,3)];

            %%

            if drawrot
                % R = [cosd(dorot) -sind(dorot); sind(dorot) cosd(dorot)];
                R = [1 0 0; 0 cosd(-drawrot) -sind(-drawrot) ; 0 sind(-drawrot) cosd(-drawrot)] ; %negative rotation applied above
                for k = 1:size(cenperm,1)
                    [cenperm2(k,:), RR, TT] = AxelRot(cenperm(k,:)', -drawrot, [0 1 0], [1 1 0]);
                    % cenperm2(k,:) = (R*(cenperm(k,:)-size(stackmnt)/2)')'+(size(stackmnt)/2); %pnew=R*(pold-c1)+c2
                    cenperm3(k,:) = (R*cenperm(k,:)')';
                    % pold = inv(R)*pnew; %from  pnew = R*(pold-c1)+c2;
                end
                % roicentmp = cenperm(:,[3 2 1]); %flip z and y because permuted above to create posterior sections
            else
                roicentmp = cenperm; %flip z and y because permuted above to create posterior sections
            end

            roicentmp(:,widyxz>roirad) = round(roicentmp(:,widyxz>roirad)); %round dimension with resolution lower than roi radius to prevent empty rois
