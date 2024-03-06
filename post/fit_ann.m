
function preddepv = fit_ann(pars, indv, supp, pthspre)

%could change how indv is organized before this function for speed (since
%it's organized for pure linear fits right now)

% artificial neural network: sums of outputs of LN units
% (1d linear filters with static nonlinearities)
% nonlinearity is generalized logistic function
% single layer
% each indv dim gets numLN LN units
% pass nonempty pthspre to plot/save model params



if exist('pthspre', 'var') && ~isempty(pthspre)

    pth_save = [pthspre '_MODELCOMPS.gif'];
    [~, fn_save, ~] = fileparts(pth_save);
    fn_save = strrep(fn_save, '_', ' ');
    
    indvmin = min(indv(:));
    indvmax = max(indv(:));
    extra_xlim_fac = 0.1;
    extrax = extra_xlim_fac*range(indv(:));

    fontsmall = 13;
    fontmedium = 20;
    ncolgif = 128;
    numrows_plot = supp.num_model_functions;
    numcolumns_plot = 1;
    margins_fig = 0.04;
    margins_subfig = 0.07;

    [axx, axy, axw, axh] = arrange_subplots(numrows_plot, numcolumns_plot, margins_fig, margins_subfig);

    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on') ;
    hfg.Position = [0 0 0.5 0.5]; %make square inner size (excludes top menu bar), plot in bottom left
    bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( 0.05, 0.99, '', 'FontSize', fontsmall, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
    hax{1} = axes( 'Parent', hfg, 'Position', [axx(1), axy(1), axw, axh] );
    hax{2} = axes( 'Parent', hfg, 'Position', [axx(2), axy(2), axw, axh] );
else
    pthspre = [];
end


C = 1; %hard coded param
Q = 1; %hard coded param
filtnorm = 1; %hard coded param
doplots_filt = 0;
preddepv = zeros(size(indv, 1), 1);
count = 0;

for jj = 1:supp.num_dim_indv %loop over indv dims

    ivinds = [1:supp.num_samp_model]*2-(2-jj); %since indv is organized this way, dims alternate in vec
    indvtmp = indv(:,ivinds);

    for ii = 1:supp.num_LN_per_indvdim %loop over LN units

        count = count +1;

        tmp = num2cell(pars(supp.pind{jj,ii}.L));
        if strcmp(supp.LN_specs_per_indv_dim{ii,'linfilt_types_per_indv_dim'}, 'freeform')
            filt = cell2mat(tmp); %optimize filter weights directly 
        else
            filt = linear_filter_1d(supp.num_samp_model, filtnorm, doplots_filt, tmp{:}); %make linear filter, tau1, tau2, shift, tc, norm, numsamp, doplots
        end
        preddepvtmp = sum(indvtmp.*filt, 2); %apply linear filter

        if pthspre
            preddepvlin = preddepvtmp; %save this for plotting after optimization, don't want to add variable if not plotting to keep optimization code light
        end

        tmp = num2cell(pars(supp.pind{jj,ii}.N));
        if ~isempty(tmp)
            preddepvtmp = static_genlog(preddepvtmp, C, Q, tmp{:}); %make linear filter, tau1, tau2, shift, tc, norm, numsamp, doplots
        end
        preddepv = preddepv + preddepvtmp; %sum outputs across loop


        if pthspre

            sfi = 1;
            plot(hax{sfi}, filt);

            xlm = hax{sfi}.XLim;
            extrax = extra_xlim_fac*range(xlm(:));
            hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 6);
            hax{sfi}.XAxis.TickLabelFormat = '%.2f';
            hax{sfi}.XAxis.FontSize = fontsmall;
            hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];
            pars_str = sprintf('%.2f,  ', pars(supp.pind{jj,ii}.L));
            pars_str = pars_str(1:end-1);% strip final comma
            hax{sfi}.Title.String = {['neuron ' num2str(jj)]; pars_str};
            hax{sfi}.Title.FontSize = fontsmall;

            sfi = 2;
            [preddepvlin, idx] = sort(preddepvlin);
            plot(hax{sfi}, preddepvlin, preddepvtmp(idx)); %sorting prevents an odd plotting error

            hax{sfi}.XAxis.Limits = [min(preddepvlin(:)) max(preddepvlin(:))];
            xlm = hax{sfi}.XLim;
            hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 6);
            hax{sfi}.XAxis.TickLabelFormat = '%.2f';
            hax{sfi}.XAxis.FontSize = fontsmall;
            extrax = extra_xlim_fac*range(xlm);
            hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];
            pars_str = sprintf('%.2f,  ', pars(supp.pind{jj,ii}.L));
            pars_str = pars_str(1:end-1);% strip final comma
            hax{sfi}.Title.String = {['neuron ' num2str(jj)]; pars_str};
            hax{sfi}.Title.FontSize = fontsmall;

            htx.String = fn_save;

            frame = getframe(hfg);
            im = frame2im(frame);
            [imind, cm] = rgb2ind(im, ncolgif);

            if count==1
                imwrite(imind, cm, pth_save, 'DelayTime', 0, 'Loopcount', inf);
            else
                imwrite(imind, cm, pth_save,'DelayTime', 0, 'WriteMode', 'append');
            end


        end
    end

end

%%
%
% B = [0.9]; %slope, 0 is horizontal line
% A = [-15000]; %left asymptote value
% K = [15000]; %right asymptote (exactly if C=1, otherwise a function of C, A, K, V)
% V = linspace(1, 1, 1 ); %[.2]; %inflection point, 1 is balanced in center; can't be negative, approaches ylim asymptotically
% M = linspace(0, 0, 1); %[1]; %x shift, larger and more direct effect than Q
% Q = [1];%linspace(1, 1, 1); %[-1.2 -0.8 -.1 0 0.1 0.8 1.2];  %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
% C = [1]; %maybe can force this to be 1, changes right asymptote value, above 1 makes it exponentially closer to lower asymptote, and below eponentially furthe
% x = linspace(-10, 10, 1000);
% genlog(x, B,A,K,V,M,Q,C, 1, pth_save)

%%
%
% tau1 = linspace(0.1, 2, 10);
% tau2 = linspace(0.1, 4, 6);
% % tau2 = [tau1+tau1*0.2 tau1+tau1*0.4 tau1+tau1*0.6 tau1+tau1*0.8];
% shift = linspace(0, 0, 1);
% tc = linspace(0, 1, 3 );
% filtnorm = linspace(1, 1, 1);
% numsamp = linspace(10, 10, 1);
% linear_filter_1d_test(tau1, tau2, shift, tc, filtnorm, numsamp, ['~/Documents/' datestr(now,30) '_.gif'])

%%


end
