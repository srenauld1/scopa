
function scatterplots_4d(cueang, cuevel, ballang, ballvel, ...
    bumpang, bumprho, bumpvel, ampmean, amppeak, ampmu, ...
    respgar, respgal, respnor, respnol, meang, meann, ...
    md, epochinds, fn_prefix)


% [outputArray, cmap, colorScaled] = dogmodel_colormap(inputArray, minwghts, nColors);

if any(ismember([1 4], epochinds)) %2 and 3 are constant cuevel, and 5 is no cue (dark)
    skip_cuevel = 0;
else
    skip_cuevel = 1;
end

for dti4 = 1:3

    if dti4==1
        dattmp4 = cueang;
        labtmp4 = 'cueang';
    elseif dti4==2
        dattmp4 = cuevel;
        labtmp4 = 'cuevel';
    elseif dti4==3
        dattmp4 = bumpang;
        labtmp4 = 'bumpang';
    end

    for dti3 = 1:3

        if dti3==1
            dattmp3 = amppeak;
            labtmp3 = 'pbpeak';

        elseif dti3==2
            dattmp3 = ballvel;
            labtmp3 = 'ballvel';

        elseif dti3==3
            dattmp3 = cuevel;
            labtmp3 = 'cuevel';

            % elseif dti3==4
            %     dattmp3 = ampmu;
            %     labtmp3 = 'pbmu';
            %
            % elseif dti3==5
            %     dattmp3 = ampmean;
            %     labtmp3 = 'pbmean';

        end


        for dti2 = 1:4

            if dti2==1
                dattmp2 = bumpvel;
                labtmp2 = 'bumpvel';
            elseif dti2==2
                dattmp2 = respgar;
                labtmp2 = 'gar';
            elseif dti2==3
                dattmp2 = respgal;
                labtmp2 = 'gal';
            elseif dti2==4
                dattmp2 = respgal;
                labtmp2 = 'gamean';
            end

            for dti1 = 1:6

                if dti1==1
                    dattmp1 = respnor;
                    labtmp1 = 'nor';
                elseif dti1==2
                    dattmp1 = respnol;
                    labtmp1 = 'nol';
                elseif dti1==3
                    dattmp1 = meann;
                    labtmp1 = 'nomean';
                elseif dti1==4
                    dattmp1 = respgar;
                    labtmp1 = 'gar';
                elseif dti1==5
                    dattmp1 = respgal;
                    labtmp1 = 'gal';
                elseif dti1==6
                    dattmp1 = meang;
                    labtmp1 = 'gamean';
                end

                dattmp1new = dattmp1;
                labtmp1new = labtmp1;
                dattmp2new = dattmp2;
                labtmp2new = labtmp2;
                dattmp3new = dattmp3;
                labtmp3new = labtmp3;
                dattmp4new = dattmp4;
                labtmp4new = labtmp4;
                if endsWith(labtmp2, 'vel') & endsWith(labtmp1, 'mean') %convert vel to speed if it's against a 'mean' var
                    dattmp2new = abs(dattmp2);
                    labtmp2new = [labtmp2(1:end-3) 'speed'];
                end
                if endsWith(labtmp3, 'vel') & endsWith(labtmp1, 'mean')%convert vel to speed if it's against a 'mean' var
                    dattmp3new = abs(dattmp3);
                    labtmp3new = [labtmp3(1:end-3) 'speed'];
                end
                if endsWith(labtmp4, 'vel') & endsWith(labtmp1, 'mean')%convert vel to speed if it's against a 'mean' var
                    dattmp4new = abs(dattmp4);
                    labtmp4new = [labtmp4(1:end-3) 'speed'];
                end



                skipplot = 0;
                allvars = who; %all workspace vars
                labvars = allvars(startsWith(allvars, 'labtmp') & ~endsWith(allvars, 'new'));
                for lnvi = 1:length(labvars)
                    labvarsvals{lnvi} = eval(labvars{lnvi}); %get their values
                end
                if numel(unique(labvarsvals(:)))~=numel(labvarsvals(:)) %must not have duplicate vars
                    skipplot = 1;
                end
                if any(strcmp(labvarsvals, 'cuevel')) & skip_cuevel %must not have cuevel if skip_cuevel
                    skipplot = 1;
                end
                if numel(find(~cellfun(@isempty, regexp(labvarsvals, 'ga'))))>1 || ... %must not have more than 1 ga
                        numel(find(~cellfun(@isempty, regexp(labvarsvals, 'no'))))>1 % or more than 1 no
                    skipplot = 1;
                end
                if numel(find( ~cellfun(@isempty, regexp(labvarsvals, 'ga')) | ~cellfun(@isempty, regexp(labvarsvals, 'no')) ))<2 %must have one ga and one no
                    skipplot = 1;
                end
                if any(endsWith(labvarsvals, 'mean')) & numel(find(endsWith(labvarsvals, 'mean')))~=2 %must be 0 or 2 'mean' vars
                    skipplot = 1;
                end
                if (any(endsWith(labvarsvals, 'gar')) & any(endsWith(labvarsvals, 'nor'))) | ... %must not have no and ga from "same side" (not connected)
                        (any(endsWith(labvarsvals, 'gal')) & any(endsWith(labvarsvals, 'nol')))
                    skipplot = 1;
                end
                if any(endsWith(labvarsvals, 'ang')) %must not be an angle (for now)
                    skipplot = 1;
                end



                if ~skipplot


                    for li = 1:length(laginds)


                    end

                    [~, idx4] = sort(dattmp4new);
                    dattmp1new = dattmp1new(idx4);
                    dattmp2new = dattmp2new(idx4);
                    dattmp3new = dattmp3new(idx4);
                    cmp = jet(length(idx4));

                    figure;
                    scatter3(dattmp1new, dattmp2new, dattmp3new, 4, cmp, 'filled');
                    fnscat = [fn_prefix '_' labtmp1new '_' labtmp2new '_' labtmp3new '_' labtmp4new '_epoch' num2str(epochinds) '_4dcol_' ];
                    xlabel(labtmp1new)
                    ylabel(labtmp2new)
                    zlabel(labtmp3new)
                    title({['_epoch' num2str(epochinds)]; ['color is ' labtmp4new ]})
                    %saveas( gcf, [fnscat '_.png'])
                    saveas( gcf, [fnscat '_.fig'])

                end
            end
        end
    end
end