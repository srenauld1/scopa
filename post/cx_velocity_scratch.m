
                    % tmpvel = [nan; diff(unwrap((tmpsm)))]; %make first element nan
                    % tmpvel = smoothdata(tmpvel, 'gaussian', 5, 'omitnan');
                    % tmpvel = tmpvel ./ dts;
                    % tmpvel(naninds_b) = nan;
                    % 
                    % ford = 3;
                    % fflen = 201;
                    % sgf = sgolay(ford,fflen);
                    % tmpvelsm = conv(tmpvel,sgf((fflen+1)/2,:),'full');
                    % %tmpvelsm = smoothdata(tmpvel, 'gaussian', 30, 'omitnan');
                    % %tmpvelsm = filtfilt(tmpvel, sgf((fflen+1)/2));
                    % tmpvelsm = tmpvelsm(1:end-(fflen - 1)); %crop end
                    % tmpvelsm(fflen - 1) = nan; %instead of cropping beginning, make nan so you don't have to crop other variables we want to stay same at this stage 


                    