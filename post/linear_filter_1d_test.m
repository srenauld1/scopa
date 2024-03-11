function linear_filter_1d_test(tau1, tau2, shift, tc, filtnorm, numsamp, filename_save)

if exist('filename_save', 'var') && ~isempty(filename_save)
    fontmedium = 12;
    figsidelength = 0.5; %proportion of your screen occupied by fig
    hfg = figure; %hold on;
    aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
    close(hfg)
    hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on') ;
    if aspect_screen>1
        hfg.Position = [0.4 0.2 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
    else
        hfg.Position = [0.4 0.2 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
    end
    bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
    htx = text( 0.2, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
    hax = axes( 'Parent', hfg, 'Position', [0.1, 0.1, 0.8, 0.8] );
end

countz = 0;

for qi = 1:length(numsamp) %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
    for mi = 1:length(filtnorm)%also seems like x shift, but larger effect
        for vi = 1:length(tc)%inflection point, 1 is balanced in center, below half if below zero, above half if above zero; can't be negative, approaches ylim asymptotically
            for ki = 1:length(shift)%right asymptote (exactly if C=1, otherwise a function of C, tau2, shift, tc)
                for ai = 1:length(tau2) %left asymptote
                    for bi = 1:length(tau1) %slope
                        countz = countz + 1;


                        x = 0:numsamp-1;
                        b1 = x./tau1(bi)^2.*exp(-x./tau1(bi));
                        b1 = b1 / norm(vec(b1(:)),1);
                        tau2new = tau1(bi)+tau1(bi)*tau2(ai);
                        b2 = x./tau2new^2.*exp(-x./tau2new);
                        b2 = b2 / norm(vec(b2(:)),1) * tc(vi);
                        filt = b1-1*b2;
                        filtplot = filt / norm(vec(filt(:)),1) * filtnorm(mi); %normalize by L1
                        filt = fraccircshift(filt,shift(ki));
                        filt = filt / norm(vec(filt(:)),1) * filtnorm(mi); %normalize by L1


                        if exist('filename_save', 'var') && ~isempty(filename_save)

                            hpl = plot(hax, x, filt); 
                            % hold(hax, 'on')
                            % hpl2 = plot(hax, x, filtplot); %shifted
                            ylim([-1 1])
                            xlim([0 numsamp])
                            htx.String = [...
                                ' tau1: ' num2str(round(tau1(bi), 2)), ...
                                ' tau2: ' num2str(round(tau2(ai), 2)), ...
                                ' shift: ' num2str(round(shift(ki), 2)), ...
                                ' tc: ' num2str(round(tc(vi), 2)), ...
                                ' filtnorm: ' num2str(round(filtnorm(mi), 2)), ...
                                ' numsamp: ' num2str(round(numsamp(qi), 2)), ...
                                ];

                            fig2gif(hfg, countz, filename_save)



                        end
                    end
                end
            end
        end
    end
end

