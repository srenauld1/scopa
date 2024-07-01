function [ftD] = readFictracCSV_scopa(file)
        
%copied verbatim from flyg, renamed to avoid conflict 

        %% Default settings
        arguments
            file char
        end
    
        %read .csv or .dat file
        rawFtData = csvread(file);
        
        % Deal with FicTrac resets
        for iFrame = 2:(size(rawFtData, 1) - 1)
            if rawFtData(iFrame, 23) < rawFtData(iFrame - 1, 23)

                % Integrated XY position
                rawFtData(iFrame:end, 15:16) = rawFtData(iFrame:end, 15:16) + rawFtData(iFrame - 1, 15:16);

                % Heading direction
                rawFtData(iFrame:end, 17) = mod(rawFtData(iFrame:end, 17) + rawFtData(iFrame - 1, 17), 2 * pi);

                % Movement speed
                rawFtData(iFrame, 19) = rawFtData(iFrame + 1, 19);
            end
        end
        
        % Convert to table
        ftD = array2table(rawFtData);
        ftD.Properties.VariableNames = {'frameCounter'...
            'deltaRotationVectorCamX' 'deltaRotationVectorCamY' 'deltaRotationVectorCamZ' ...
            'deltaRotationErrorScore' 'deltaRotationVectorLabX' 'deltaRotationVectorLabY' 'changeHeading'... %deltaRotationVectorLabZ=changeHeading
            'absoluteRotationVectorCamX' 'absoluteRotationVectorCamY' 'absoluteRotationVectorCamZ' ...
            'absoluterotationVectorLabX' 'absoluterotationVectorLabY' 'absoluterotationVectorLabZ',...
            'posX' 'posY' ...
            'heading' ...
            'direction' 'speed'...
            'intX' 'intY' ...
            'timeStamp' 'sequenceCounter' 'deltaTimestamp' 'altTimestamp'};
end