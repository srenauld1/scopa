    %%

    % noise_scalefac = 0;
    % noiseadd = noise_scalefac*std(ballvel,1)*(rand(size(ballvel)));
    % noiseaddpos = noise_scalefac*std(ballvel,1)*(rand(size(ballvel)));
    % ballvelnoise = ballvel + noiseadd;
    % ballvelnoisepos = 6*ballvel.^3 + 2*ballvel.^2 + noiseaddpos + 0;
    % ballvelnoisepos = ballvel + noiseaddpos + 0;
    % indiest = 100:400; figure;
    % subplot(2,1,1); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoise(indiest))
    % subplot(2,1,2); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoisepos(indiest))
    % bigx = cat(2, meann, ballvel, ballvelnoise, ballvelnoisepos, bumpvel);
    % bigx = double(bigx);
    % [sValue,condIdx,VarDecomp] = collintest(bigx);

        %adftest(Y)
