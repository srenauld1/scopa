function nonlinearly_transform_response(dfc)

close all
clear propor
fukos = [1 1.5 2 2.5 3 4 5 6];
fukos = [4];
for fuko = 1:length(fukos)
    nla = 1; %how steep the slope (more dramatic than nlk it seems)
    nlb = 0; %-0.3; %x position of elbow (kind of) - percentiles (at least over large scale) don't work or make biological sense
    nlc = 1; %final amplitude
    nld = 0;%-0.34; %y shift - percentiles (at least over large scale) don't work or make biological sense
    nlk = fukos(fuko); %how steep the slope (less dramatic than nla i think)
    dfcn = zeros(size(dfc));
    indiest = 1:1000;
    for rmi = 1:size(dfc, 1)
        dinn = rescale(dfc(rmi,:));
        %dfcn(rmi,:) = log( 1 + exp(dinn) );
        dfcn(rmi,:) = nonlinearity_softplus(dinn, nla, nlb, nlc, nld, nlk);
        %dfcn(rmi,:) = rescale(dfcn(rmi,:) - min(vec(dfcn(rmi,:))));
        dfcn(rmi,:) = dfcn(rmi,:) - min(vec(dfcn(rmi,:)));
        %nnz = find(dfcn(rmi,:)~=0);
        lnz = find(dfcn(rmi,:)~=0);
        propor(rmi,fuko) = numel(find(dfcn(rmi,lnz)>dinn(lnz))) / numel(dinn(lnz));
        if rmi==1
            figure;
            subplot(2,1,1);
            plot(dinn(indiest)); %yyaxis right;
            hold on
            plot(dfcn(rmi,indiest))
            subplot(2,1,2);
            plot(sort(dinn(:)), sort(dfcn(rmi,:)))
            hold off
        end
    end

end

figure; hold on
for fuko = 1:length(fukos)
    plot(propor(:, fuko))
    pause(1)
end