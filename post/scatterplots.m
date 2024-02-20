function scatterplots(cueangtmp, cueveltmp, ballangtmp, ballveltmp, ...
    bumpmutmp, bumprhotmp, bumpveltmp, ampmeantmp, amppeaktmp, ampmutmp, ...
    respgartmp, respgaltmp, respnortmp, respnoltmp, meangtmp, meanntmp, ...
    ti, tb, stimepochinds_i, stimepochinds_b, epochindstmp, fn_prefix, gif_visibility)


allow_response_upsample = 0;

if length(respgartmp) < length(cueveltmp) & allow_response_upsample

    tsamp_ei = stimepochinds_b;
    tsamp = tb;
    respgartmp = interp1(ti,respgartmp,tb)'; %upsample resp rather than downsample stim
    respgaltmp = interp1(ti,respgaltmp,tb)'; %upsample resp rather than downsample stim
    respnortmp = interp1(ti,respnortmp,tb)'; %upsample resp rather than downsample stim
    respnoltmp = interp1(ti,respnoltmp,tb)'; %upsample resp rather than downsample stim
    meangtmp = interp1(ti,meangtmp,tb)'; %upsample resp rather than downsample stim
    meanntmp = interp1(ti,meanntmp,tb)'; %upsample resp rather than downsample stim
    ampmeantmp = interp1(ti,ampmeantmp,tb)'; %upsample resp rather than downsample stim
    amppeaktmp = interp1(ti,amppeaktmp,tb)'; %upsample resp rather than downsample stim
    ampmutmp = interp1(ti,ampmutmp,tb)'; %upsample resp rather than downsample stim
    bumpmutmp = interp1(ti,bumpmutmp,tb)'; %upsample resp rather than downsample stim
    bumprhotmp = interp1(ti,bumprhotmp,tb)'; %upsample resp rather than downsample stim
    bumpveltmp = interp1(ti,bumpveltmp,tb)'; %upsample resp rather than downsample stim

elseif length(respgartmp) == length(cueveltmp)

    tsamp_ei = stimepochinds_i;
    tsamp = ti;

else

    error

end

for rind = 1:length(epochindstmp)

    epochinds = epochindstmp{rind};
    epochstring = sprintf('%.0f,' , epochinds);
    epochstring = epochstring(1:end-1);
    indz1 = find(ismember(tsamp_ei, epochinds));
    indz1(indz1>length(cueveltmp)) = []; %there may be some beyond modeling indices since we cropped for full convolution
    tnew = tsamp(indz1);

    ampmean = ampmeantmp(indz1);
    amppeak = amppeaktmp(indz1);
    ampmu = ampmutmp(indz1);
    respgal = respgaltmp(indz1);
    respgar = respgartmp(indz1);
    respnol = respnoltmp(indz1);
    respnor = respnortmp(indz1);
    meang = meangtmp(indz1);
    meann = meanntmp(indz1);
    bumpmu = bumpmutmp(indz1);
    bumprho = bumprhotmp(indz1);
    bumpvel = bumpveltmp(indz1);
    cueang = cueangtmp(indz1);
    cuevel = cueveltmp(indz1);
    ballang = ballangtmp(indz1);
    ballvel = ballveltmp(indz1);

    %%

    % noise_scalefac = 0;
    % noiseadd = noise_scalefac*std(ballvel)*(rand(size(ballvel)));
    % noiseaddpos = noise_scalefac*std(ballvel)*(rand(size(ballvel)));
    % ballvelnoise = ballvel + noiseadd;
    % ballvelnoisepos = 6*ballvel.^3 + 2*ballvel.^2 + noiseaddpos + 0;
    % ballvelnoisepos = ballvel + noiseaddpos + 0;
    % indiest = 100:400; figure;
    % subplot(2,1,1); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoise(indiest))
    % subplot(2,1,2); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoisepos(indiest))
    % bigx = cat(2, meann, ballvel, ballvelnoise, ballvelnoisepos, bumpvel);
    % bigx = double(bigx);
    % [sValue,condIdx,VarDecomp] = collintest(bigx);

    %%

    %adftest(Y)


    %%
     
    do3d = 0;
    colorvars = {''};
    manualvars = {'respnor', 'respnol', 'ballvel'};
    threshold_data = 0;
    scatterplots_2d(cueang, cuevel, ballang, ballvel, ...
        bumpmu, bumprho, bumpvel, ampmean, amppeak, ampmu, ...
        respgar, respgal, respnor, respnol, meang, meann, ...
        do3d, colorvars, manualvars, threshold_data, ...
        epochinds, epochstring, fn_prefix, gif_visibility)

    % scatterplots_3d(cueang, cuevel, ballang, ballvel, ...
    %     bumpmu, bumprho, bumpvel, ampmean, amppeak, ampmu, ...
    %     respgar, respgal, respnor, respnol, meang, meann, ...
    %     md, epochinds, fn_prefix)

    % scatterplots_4d(cueang, cuevel, ballang, ballvel, ...
    %     bumpmu, bumprho, bumpvel, ampmean, amppeak, ampmu, ...
    %     respgar, respgal, respnor, respnol, meang, meann, ...
    %     md, epochinds, fn_prefix)

    close all

    save([fn_prefix '_' epochstring '_scatter4data_.mat'], ...
        'cueang', 'cuevel', 'ballang', 'ballvel', ...
        'bumpmu', 'bumprho', 'bumpvel', 'ampmean', 'amppeak', 'ampmu', ...
        'respgar', 'respgal', 'respnor', 'respnol', 'meang', 'meann', ...
        'ti', 'tb', 'stimepochinds_i', 'stimepochinds_b', 'epochinds', '-v7.3', '-mat')



end







