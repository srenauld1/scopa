

        %stim = discretize(cueang, 12);

        roifitinds = 1;

        vv = [50 0.5 1 -50];

        switch modeltype
            case 'gaussian'
                objfcn =  @(vv,xx) vv(1)*exp(-(((xx-vv(2)).^2)/(2*vv(3).^2)))+vv(4);

            case 'vonmises'
                objfcn = @(vv,xx) vv(1)*exp(vv(2)*cos(xx-vv(3)))+vv(4);
        
            case 'sigmoid'
                out = @(vv,xx) vv(1) + ( (vv(2) - vv(1)) ./ ( vv(3) + vv(4) * exp( -vv(5) * (x-vv(6)) ) .^ 1/vv(7) ) ); %genlog
                out = c * (1 ./ ( 1 + exp( -a * (inp-cntr) )) - 0.5); %sigmoid
                out = c * log( 1 + exp(a*x + b) ).^k + d; %softplus
                Y = d+(a-d)/(1+(x/c)^b)
                Y = a/(1+exp(-b*(x-c)))
            case 'sine'
                objfcn = @(vv,xx) vv(1)*sin(vv(2)*x+vv(3))+vv(4);

        
        end

        wid1 = 2 * abs( acos( 1/vv(2) * log( 1/2 *( exp(vv(2)) + exp(-vv(2)) ))));
        respfit  = objfcn (vv, stim);
        noisefac = 0.5;
        % [~, idx] = sort(stim);
        % noisedata = 2*(rand(size(stim)) - 0.5) .* (movstd(respfit(idx), 30) * noisefac);
        noisedata = 2*(rand(size(stim)) - 0.5) .* (max(respfit(:)) * noisefac);
        respfit = respfit + noisedata;
        %respfit = awgn(respfit, 0.000000000001);
        respfit = respfit(:)';

        figure;
        scatter(stim, respfit, 'filled');
        yline(0)
        % psc = polarscatter(stim, respfit, 'filled');
        % psc.Parent.RLim = [min(respfit(:)) max(respfit(:))];
        title([num2str(wid1) ' ---  ' num2str(wid1)])
        %figure; plot(sort(stim), movstd(respfit(idx), 10)); yyaxis right; scatter(stim, respfit, 5, 'filled')