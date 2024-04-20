function [out, out_all, nonlinear_transformation_all, nlparams_all] = genlog(x, B,A,K,V,M,Q,C, doplots, filename_save, xlimin, ylimin)

if doplots
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
for ci = 1:length(C) %changes right asymptote value, above 1 makes it exponentially closer to lower asymptote, and below eponentially further, maybe force to be 1?
    %subplot(length(Ctmp),1,ci); hold on
    for qi = 1:length(Q) %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
        for mi = 1:length(M)%also seems like x shift, but larger effect
            for vi = 1:length(V)%inflection point, 1 is balanced in center, below half if below zero, above half if above zero; can't be negative, approaches ylim asymptotically
                for ki = 1:length(K)%right asymptote (exactly if C=1, otherwise a function of C, A, K, V)
                    for ai = 1:length(A) %left asymptote
                        for bi = 1:length(B) %slope
                            countz = countz + 1;

                            out = A(ai) + ( (K(ki) - A(ai)) ./ ( C(ci) + Q(qi) * exp( -B(bi) * (x-M(mi)) ) .^ 1/V(vi) ) );

                            out_all{countz} = out;
                            nonlinear_transformation_all{countz} = [x; out];
                            nlparams_all(countz,:) = [A(ai); K(ki); C(ci); Q(qi); B(bi); M(mi); V(vi)];

                            if doplots

                                [xs, idx] = sort(x);
                                hpl = plot(hax, xs, out(idx)); %sorting prevents an odd plotting error
                                if exist('xlimin', 'var')
                                    xlim(xlimin)
                                end
                                if exist('ylimin', 'var')
                                    ylim(ylimin)
                                end
                                axis square

                                htx.String = [...
                                    ' B: ' num2str(round(B(bi), 2)), ...
                                    ' A: ' num2str(round(A(ai), 2)), ...
                                    ' K: ' num2str(round(K(ki), 2)), ...
                                    ' V: ' num2str(round(V(vi), 2)), ...
                                    ' M: ' num2str(round(M(mi), 2)), ...
                                    ' Q: ' num2str(round(Q(qi), 2)), ...
                                    ' C: ' num2str(round(C(ci), 2)), ...
                                    ];


                                    fig2gif(hfg, countz, filename_save)


                            end
                        end
                    end
                end
            end
        end
    end
end

