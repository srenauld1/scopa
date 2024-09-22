

function [xPos, yPos] = plot2DTrajectory(rootDir, toPlot, nTrial)
    folders = get_folders(rootDir, 1, 0);
    
    if isempty(folders)
        folders(1).folder = rootDir; 
    end
   
    %% Process each folder
    folderNum = length(folders);
    fprintf(1, '##### Found %d potential experiment folders to process...#####\n', folderNum);
for ff = 1:folderNum
      try
      %% Get folder information
          folder = folders(ff).folder;


        %% Load in fictrac & ROI data
            if strcmp(folder(end),'.')
                folder = folder(1:end-2); 
            end

            % Get data files
            expID = get_expID(folder);
            expList = {expID};

            % Load metadata 
            [~, trialMd] = load_metadata(expList, folder);

            % Load imaging data
            roiData = load_roi_data(expList, folder);

            % Load FicTrac data
            [~,ftData_DAQ,~] = load_ft_data(expList, folder, 1, 0);


            if all(nTrial == 'all')
                nTrials = max(size(unique(roiData.trialNum),1),length(trialMd.trialNum)); 
                numTrials = 1:nTrials;
            else 
                numTrials = nTrial; 
            end
            %%

            %% Helen's path code

            for nTrial = numTrials
                yawAngPos = ftData_DAQ.cueAngle{nTrial};
                fwdAngVel = ftData_DAQ.velFor{nTrial};
                slideAngVel = ftData_DAQ.velSide{nTrial};
                [~, goal] = CalculateAverageHeading_wholeSegment(ftData_DAQ,60,1.5,'all',60);
                goal = rad2deg(goal)';

                sampRate = 30; 
                % conversion factor between degrees and mm
                circum = 9 * pi; % circumference of ball, in mm
                mmPerDeg = circum / 360; % mm per degree of ball

                % position incorporating heading - as if fly were walking on x-y plane,
                %  x-y coordinates at each time point
                % start with fly at (0,0) and facing 0 deg
                zeroedYawAngPos = yawAngPos - yawAngPos(1); 

                % movement in x (in degrees) at each time point
                xChangePos = (fwdAngVel ./ sampRate) .* sind(zeroedYawAngPos) + ...
                    (slideAngVel ./ sampRate) .* sind(zeroedYawAngPos + 90);  

                % x position in mm (i.e. x-coordinate of fly's position at each time 
                %  point), starts at 0
                xPos = (cumsum(xChangePos) - xChangePos(1)) .* mmPerDeg;
                minX = min(xPos);
                maxX = max(xPos);

                % movement in y (in degrees) at each time point
                yChangePos = (fwdAngVel ./ sampRate) .* cosd(zeroedYawAngPos) + ...
                    (slideAngVel ./ sampRate) .* cosd(zeroedYawAngPos + 90);

                % y position in mm (i.e. y-coordinate of fly's position at each time 
                %  point), starts at 0
                yPos = (cumsum(yChangePos) - yChangePos(1)) .* mmPerDeg;
                minY = min(yPos);
                maxY = max(yPos);

                [~, ~, transition] = detect_jumps(ftData_DAQ, 2, 2,[],0);
                time = seconds(ftData_DAQ.trialTime{1});
                jumpTimes = time(transition == 1); 
                
                if toPlot
                    figure();patch(xPos,yPos,goal,'EdgeColor','interp','FaceColor','none','LineStyle','none','Marker','.', 'MarkerSize',3);
                    %figure();patch('xData',xPos,'yData',yPos,'EdgeColor','k','FaceColor','none','LineStyle','none','Marker','.', 'MarkerSize',3);
                    hold on
                    if showJumps
                        %patch(xPos(transition == 1),yPos(transition == 1),time(transition == 1),'EdgeColor','k','FaceColor','none','LineStyle','none','Marker','.', 'MarkerSize',7);
                        %patch('xData',xPos(transition == 1),'yData',yPos(transition == 1),'EdgeColor','k','FaceColor','none','LineStyle','none','Marker','.', 'MarkerSize',7);
                    end
                    colormap(rainbow)
                    a=colorbar; a.Label.String = 'Goal (deg)';
                    set(gcf,'Renderer','painters')
                    set(gcf,'color','w');
                    xlabel('mm')
                    xlim([min(minX,minY),max(maxX, maxY)])
                    ylim([min(minX,minY),max(maxX, maxY)])

                    idxes = regexp(folder,'\');
                    title(folder(idxes(end) + 1:end), 'Interpreter', 'none')
                
                    speed = sqrt(fwdAngVel.^2 + slideAngVel.^2);
                    trial_angle = ftData_DAQ.cueAngle{1};
                    trial_angle = trial_angle(speed > 1.5);
                    xTrial = cosd(trial_angle);
                    yTrial = sind(trial_angle); 
                    trialHeadingVector(1) = sum(xTrial)/length(xTrial);
                    trialHeadingVector(2) = sum(yTrial)/length(yTrial);
                    rho = sqrt(trialHeadingVector(1).^2 + trialHeadingVector(2).^2); 
                    theta = atan2(trialHeadingVector(2),trialHeadingVector(1));

                    [x,y] = pol2cart([theta,0],[rho,0.8]);
                    figure();
                    set(gcf,'Renderer','painters')
                    set(gcf,'color','w')
                    hC = compass(x,y,'k');
                    for i=1:numel(hC)
                        hC(i).XData(end-2:end)=nan;       % HG won't display NaN points (arrows)
                    end
                end

%                 figure();patch(ftData_dat.intX{1},ftData_dat.intY{1},ftData_dat.trialTime{1},'EdgeColor','interp','FaceColor','none','LineStyle','none','Marker','.', 'MarkerSize',3);
%                 a=colorbar; a.Label.String = 'Time (sec)';
%                 set(gcf,'color','w');
%                 axis off

%                 saveas(gcf, fullfile(folder,'images',[expID,'_',num2str(nTrial),'_pathTrajectory.fig']));
%                 saveas(gcf, fullfile(folder,'images',[expID,'_',num2str(nTrial),'_pathTrajectory.png']));
%                 saveas(gcf, fullfile(folder,'images',[expID,'_',num2str(nTrial),'_pathTrajectory.svg']));
            end
      catch
          disp(['Folder: ',folder,' failed'])
      end
end
end


function make_fictive_path(heading_in, posx_in, posy_in, intx, inty, heading_raw_in, intx_raw_in, inty_raw_in, transGain, yawGain, ballRadius)

% extra_variable = [heading, posx, posy, intx, inty, heading_raw, intx_raw, inty_raw]
%   x as sideway or EW axis, y as forward or NS axis

% Determine yaw speed with gain and update heading
heading_raw = unwrap([heading_raw_in, ft.heading]);
heading_raw = heading_raw(2);
heading = heading_in + (heading_raw - heading_raw_in) * yawGain;
heading = wrapTo2Pi(heading);
% get the change in translation (compare current vs saved raw fictrac translation),
%   apply gain and conversion to mm
delta_intx = (ft.intx - intx_raw_in) * transGain * ballRadius; % side motion
delta_inty = (ft.inty - inty_raw_in) * transGain * ballRadius; % forward motion
% get x and y allocentric position of the animal from egocentric integrated coordinates
%   and heading
% Forward/backward or y > 0 animal moves forwards
posy = posy_in + (delta_inty.*cos(heading) - delta_intx.*sin(heading));
% Sideway movement or x > 0 animal moves rightwards
posx = posx_in + (delta_inty.*sin(heading) + delta_intx.*cos(heading));


end


function [xPos_padded, yPos_padded] = reconstruct_path(fwV, sideV, heading, time, ball_d)
circum = ball_d * pi; %circumference of ball, in mm
mmPerDeg = circum / 360; % mm per degree of ball
fwdAngVel = fwV/mmPerDeg;
zeroedH = heading - heading(1); % zero heading
time_bin = diff(time);
% movement in x (in degrees) at each time point
xChangePos = (fwdAngVel(1:end-1)*time_bin)*sin(zeroedH(1:end-1)) + (sideV(1:end-1)*time_bin)*sin(zeroedH(1:end-1)+pi/4);
xPos = (cumsum(xChangePos) - xChangePos(1))*mmPerDeg;
yChangePos = (fwdAngVel(1:end-1)*time_bin)*cos(zeroedH(1:end-1)) + (sideV(1:end-1)*time_bin)*cos(zeroedH(1:end-1)+pi/4);
yPos = (cumsum(yChangePos) - yChangePos(1))*mmPerDeg;
xPos_padded = cat(1, xPos, xPos(end));
yPos_padded = cat(1, yPos, yPos(end));
end