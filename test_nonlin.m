
numsamp = 1000;

if isempty(glb('pthstackdir'))
    glb(pthstackdir = '/Users/wienecke/stacks/');
else
    glb(1, pthstackdir = '/Users/wienecke/stacks/');
end
pthsv = pthauto(suffix='.gif', usetime=1);

fun = 'vonmises';

V = linspace(0, 1, 1 ); % am
M = linspace(0, 2, 20); % width
Q = linspace(0, 0, 1); %xshift (center)
C = linspace(-5, -3, 1); %yshift (baseline)

x = linspace(-pi,pi,numsamp); %indv;

inmin = min(x);
inmax = max(x);

outmin = -5;
outmax = 5;
outmin = [];
outmax = [];


[y, h] = testfun(fun, x, [],[],[],V,M,Q,C, 1, pthsv, [inmin inmax], [outmin outmax]);


function [out, h, out_all, nonlinear_transformation_all, nlparams_all] = testfun(func, x, B,A,K,V,M,Q,C, doplt, filename_save, xlimin, ylimin)

if doplt
    h = fg(szf=1);
    h.ax = axes(parent=h.fg);
end

switch func

    case 'test_nonlin'

        cnt = 0;
        for ci = 1:length(C) %changes right asymptote value, above 1 makes it exponentially closer to lower asymptote, and below eponentially further, maybe force to be 1?
            %subplot(length(Ctmp),1,ci); hold on
            for qi = 1:length(Q) %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
                for mi = 1:length(M)%also seems like x shift, but larger effect
                    for vi = 1:length(V)%inflection point, 1 is balanced in center, below half if below zero, above half if above zero; can't be negative, approaches ylim asymptotically
                        for ki = 1:length(K)%right asymptote (exactly if C=1, otherwise a function of C, A, K, V)
                            for ai = 1:length(A) %left asymptote
                                for bi = 1:length(B) %slope
                                    cnt = cnt + 1;

                                    out = A(ai) + ( (K(ki) - A(ai)) ./ ( C(ci) + Q(qi) * exp( -B(bi) * (x-M(mi)) ) .^ 1/V(vi) ) );

                                    out_all{cnt} = out;
                                    nonlinear_transformation_all{cnt} = [x; out];
                                    nlparams_all(cnt,:) = [A(ai); K(ki); C(ci); Q(qi); B(bi); M(mi); V(vi)];

                                    if doplt

                                        [xs, idx] = sort(x);
                                        hpl = plot(h.ax, xs, out(idx)); %sorting prevents an odd plotting error
                                        if exist('xlimin', 'var') && ~isempty(xlimin)
                                            xlim(xlimin)
                                        end
                                        if exist('ylimin', 'var') && ~isempty(ylimin)
                                            ylim(ylimin)
                                        end
                                        axis square

                                        h.tx.String = [...
                                            ' B: ' num2str(round(B(bi), 2)), ...
                                            ' A: ' num2str(round(A(ai), 2)), ...
                                            ' K: ' num2str(round(K(ki), 2)), ...
                                            ' V: ' num2str(round(V(vi), 2)), ...
                                            ' M: ' num2str(round(M(mi), 2)), ...
                                            ' Q: ' num2str(round(Q(qi), 2)), ...
                                            ' C: ' num2str(round(C(ci), 2)), ...
                                            ];


                                        fig2gif(h.fg, cnt, filename_save)


                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

    case 'vonmises'

        limy = [];
        cnt = 0;
        for ci = 1:length(C) %changes right asymptote value, above 1 makes it exponentially closer to lower asymptote, and below eponentially further, maybe force to be 1?
            %subplot(length(Ctmp),1,ci); hold on
            for qi = 1:length(Q) %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
                for mi = 1:length(M)%also seems like x shift, but larger effect
                    for vi = 1:length(V)%inflection point, 1 is balanced in center, below half if below zero, above half if above zero; can't be negative, approaches ylim asymptotically

                        cnt = cnt + 1;

                        % original von mises
                        out = V(vi)*exp(M(mi)*cos(x-Q(qi)))+C(ci);

                        % % version that allows amp control (expresses first param as amp and k) - attempt to make amp better behaved? is it equal to original??
                        % newamp = V(vi) / ( exp(M(mi)) - exp(-M(mi)) );
                        % out = newamp * exp(M(mi)*cos(x-Q(qi)))+C(ci);

                        % out_all{cnt} = out;
                        % nonlinear_transformation_all{cnt} = [x; out];
                        % nlparams_all(cnt,:) = [A(ai); K(ki); C(ci); Q(qi); B(bi); M(mi); V(vi)];

                        limy = [min([limy out(:)']) max([limy out(:)'])];
                    end
                end
            end
        end

        if doplt

            cnt = 0;
            for ci = 1:length(C) %changes right asymptote value, above 1 makes it exponentially closer to lower asymptote, and below eponentially further, maybe force to be 1?
                %subplot(length(Ctmp),1,ci); hold on
                for qi = 1:length(Q) %kind of like x shift / when curve starts to rise  (i think this needs to be positive??)
                    for mi = 1:length(M)%also seems like x shift, but larger effect
                        for vi = 1:length(V)%inflection point, 1 is balanced in center, below half if below zero, above half if above zero; can't be negative, approaches ylim asymptotically

                            cnt = cnt + 1;

                            % original von mises
                            out = V(vi)*exp(M(mi)*cos(x-Q(qi)))+C(ci);


                            [xs, idx] = sort(x);
                            hpl = plot(h.ax, xs, out(idx)); %sorting prevents an odd plotting error
                            yline(0, 'k')
                            if exist('xlimin', 'var') && ~isempty(xlimin)
                                xlim(xlimin)
                            end
                            if exist('ylimin', 'var') && ~isempty(ylimin)
                                ylim(ylimin)
                            else
                                ylim(limy)
                            end
                            axis square

                            h.tx.String = [...

                            ' V: ' num2str(round(V(vi), 2)), ...
                            ' M: ' num2str(round(M(mi), 2)), ...
                            ' Q: ' num2str(round(Q(qi), 2)), ...
                            ' C: ' num2str(round(C(ci), 2)), ...
                            ' min: ' num2str(min(out(:))), ...
                            ' max: ' num2str(max(out(:))), ...
                            ];


                            mu = circ_mean(x, out, 2);
                            [rho, selpre, sel] = circ_var(x, out, [], 2);
                            [mu2, rho2, var2] = circmnvar(x, out', 0);
                            mu3 = deg2rad(weighted_circular_mean(rad2deg(x), out')); % "true circular mean"??
                            rho3 = deg2rad(weighted_circular_std(rad2deg(x), out)); % "true circular std"??
                            hold(h.ax, 'on')

                            rhox = [mu-rho2/2, mu+rho2/2];
                            rho2x = [mu2-rho2/2, mu2+rho2/2];
                            rho3x = [mu3-rho3/2, mu3+rho3/2];
                            midy = min(out) + range(out)/2;
                            marksep = 0.05;
                            frac = range(out)*marksep;
                            midytmp = repelem(midy, numel(rhox));

                            plot(h.ax, rhox, midytmp, 'b');
                            plot(h.ax, rho2x, midytmp+frac, 'r');
                            % try
                            %     plot(h.ax, rho3x, midytmp+frac*2, 'g');
                            % catch
                            %     plot(h.ax, nan, nan, 'g');
                            % end

                            scatter(h.ax, mu, midytmp, 'b', 'filled');
                            scatter(h.ax, mu2, midytmp+frac, 'r', 'filled');
                            % scatter(h.ax, mu3, midytmp+frac*2, 'g', 'filled');

                            title({mat2str([mu, mu2, mu3]); mat2str([rho, rho2, rho3]); mat2str([sel, var2])})
                            hold(h.ax, 'off')

                            fig2gif(h.fg, cnt, filename_save)


                        end
                    end
                end
            end
        
        end


end


end