

        % testing resample in assemble_DAQ.m in flyg

        % numt = 2000;
        % dsfac = 4;
        % m0 = idpoly(1,[ ],[1 1 1 1]);
        % e = idinput(numt,'rgs');
        % sim_opt = simOptions('AddNoise',true,'NoiseData',e);
        % y1 = sim(m0,zeros(numt,0),sim_opt);

        dsfac = 10000;
        y1 = trialData.g4panels(1:12600000);
        numt = numel(y1);

        y1 = iddata(y1,[],1);
        y2 = y1;
        y3 = y1;
        y4 = y1;

        g1 = spa(y1);

        y2.y = y2.y(1:dsfac:end);
        y2.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y2.y));
        g2 = spa(y2);

        y3.y = mean(reshape(y3.y, dsfac, []))';
        % y3.y = mean(y3.y([1:dsfac:numt ] + [0:dsfac-1]'));
        y3.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y3.y));
        g3 = spa(y3);

        % y4.y = resample(y4.y, 1, dsfac);
        y4.y = resample_with_padding(y4.y, 1, dsfac)';
        y4.y(y4.y < minVal) = minVal;
        y4.y(y4.y > maxVal) = maxVal;
        y4.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y4.y));
        g4 = spa(y4);


        freqs = linspace(0, g1.Frequency(end)/dsfac, 129);
        freqs = freqs(2:end);
        % 
        % freqs = linspace(0, g1.Frequency(end), 129);
        % freqs = freqs(2:end);

        figure; 
        % h = spectrumplot(g1,g2,g3,g4,g1.Frequency);
        % h = spectrumplot(g1,g2,freqs);
        h = spectrumplot(g1,g2,g3,g4,freqs);
        opt = getoptions(h);
        opt.FreqScale = 'linear';
        opt.FreqUnits = 'Hz';
        setoptions(h,opt);
        % subplot(1,3,2)
        % spectrumplot(g1,g3,g1.Frequency,opt)
        % subplot(1,3,3)
        % spectrumplot(g1,g4,g1.Frequency,opt)
        % 
        % y1.y = y1.y(1:numel(y4.y));
        % y1.SamplingInstants = 1:numel(y4.y);
        % g1p = spa(y1);
        % figure; 
        % h = spectrumplot(g1p,g2,g3,g4,g2.Frequency,opt);
        % opt = getoptions(h);
        % opt.FreqScale = 'linear';
        % opt.FreqUnits = 'Hz';
        % setoptions(h,opt);
