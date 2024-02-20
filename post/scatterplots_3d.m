
function scatterplots_3d(cueang, cuevel, ballang, ballvel, ...
    bumpmu, bumprho, bumpvel, ampmean, amppeak, ampmu, ...
    respgar, respgal, respnor, respnol, meang, meann, ...
    md, epochinds, fn_prefix)


% [outputArray, cmap, colorScaled] = dogmodel_colormap(inputArray, minwghts, nColors);

if any(ismember([1 4 5], epochinds))
    maxsecond = 5;
else
    maxsecond = 4;
end

for sllli3 = 1

    if sllli3==1
        tmpdat3 = bumpvel;
        tmplab3 = 'bumpvel';
    elseif sllli3==2
        tmpdat3 = respgar;
        tmplab3 = 'gar';
    elseif sllli3==3
        tmpdat3 = respgal;
        tmplab3 = 'gal';
    end


    for sllli2 = 3:maxsecond %1:5

        if sllli2==1
            tmpdat2 = ampmean;
            tmplab2 = 'ampmean';

        elseif sllli2==2
            tmpdat2 = ampmu;
            tmplab2 = 'ampmu';

        elseif sllli2==3
            tmpdat2 = amppeak;
            tmplab2 = 'amppeak';

        elseif sllli2==4
            tmpdat2 = ballvel;
            tmplab2 = 'ballvel';

        elseif sllli2==5
            tmpdat2 = cuevel;
            tmplab2 = 'cuevel';

        end

        for sllli = 1:2

            tmpdat2new = tmpdat2;
            tmplab2new = tmplab2;
            tmpdat3new = tmpdat3;
            tmplab3new = tmplab3;

            if sllli==1
                tmpdat1 = meann;
                tmplab1 = 'nomean';
                if sllli2==4 | sllli2==5
                    tmpdat2new = abs(tmpdat2);
                    tmplab2new = [tmplab2(1:end-3) 'speed'];
                end
                if sllli3==1
                    tmpdat3new = abs(tmpdat3);
                    tmplab3new = [tmplab3(1:end-3) 'speed'];
                end
            elseif sllli==2
                tmpdat1 = meang;
                tmplab1 = 'gamean';
                if sllli2==4 | sllli2==5
                    tmpdat2new = abs(tmpdat2);
                    tmplab2new = [tmplab2(1:end-3) 'speed'];
                end
                if sllli3==1
                    tmpdat3new = abs(tmpdat3);
                    tmplab3new = [tmplab3(1:end-3) 'speed'];
                end
            elseif sllli==3
                tmpdat1 = respgar;
                tmplab1 = 'gar';
            elseif sllli==4
                tmpdat1 = respgal;
                tmplab1 = 'gal';
            elseif sllli==5
                tmpdat1 = respnor;
                tmplab1 = 'nor';
            elseif sllli==6
                tmpdat1 = respnol;
                tmplab1 = 'nol';
            end


            figure; scatter3(tmpdat1, tmpdat2new, tmpdat3new, 2.5, 'filled')
            xlabel(tmplab1)
            ylabel(tmplab2new)
            zlabel(tmplab3new)
            title(['_epoch' num2str(epochinds)])
            fnscat = [fn_prefix '_' tmplab1 '_' tmplab2new '_' tmplab3new '_epoch' num2str(epochinds) '_3d_' ];
            savefig([fnscat '_.fig'])
            % saveas( gcf, [fnscat '_.png'])


            % [tmpdat3sort, idx3] = sort(tmpdat3new);
            % tmpdat1 = tmpdat1(idx3);
            % tmpdat2new = tmpdat2new(idx3);
            % cmp = jet(length(idx3));
            %
            % figure;
            % scatter(tmpdat1, tmpdat2new, 4, cmp, 'filled');
            % fnscat = [fn_prefix '_' tmplab1 '_' tmplab2new '_' tmplab3new '_epoch' num2str(epochinds) '_3dcol_' ];
            % xlabel(tmplab1)
            % ylabel(tmplab2new)
            % title({['_epoch' num2str(epochinds)]; ['color is ' tmplab3new ]})
            % saveas( gcf, [fnscat '_.png'])


        end
    end
end