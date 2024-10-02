
clear all
close all
clc

%% test various fir filters, in particular how well they express t shifts

% how do you shift an exponential filter in time (onset begins at t-t0), without interpolation??


fldr = [filesep 'Users' filesep 'wienecke' filesep];

filename_save = [fldr datestr(now, 30) '00wavelettest.gif'];
hfg = figure;
hax = axes('Parent', hfg);
dt = 0.2; %sample period
total_t_sec = 3; 
a1 = 1;
b1 = 0;
f2a = 1;
t02 = linspace(0, 1, 30);
t02 = 0;
bw_all = linspace(0.1, 0.3, 20);
bw_all = 0.2;
% cnt_all = linspace(-3, 3, 10);
cnt_all = 0;
types = {'exp', 'deriv'};
doplt = 0;

framecount = 0;
for ti2 = 1:length(t02)
    for bwi = 1:length(bw_all)
        for ci = 1:length(cnt_all)
            framecount = framecount + 1;
            
            % [rw,rwt] = ricker(bwall(bi), 11, .2, filtc(ci));
            [filtall,wt] = filter_bank(total_t_sec, dt, bw_all(bwi), cnt_all(ci), bw_all(bwi)*1.2, f2a, t02(ti2), types, doplt);
            
            fpl1 = filtall(1,:);
            norm1 = norm(fpl1(:), 1);
            sum1 = sum(fpl1(:));

            fpl2 = filtall(2,:);
            norm2 = norm(fpl2(:), 1);
            sum2 = sum(fpl2(:));

            if framecount==1
                hold(hax, 'on')
                hpl1 = plot(hax, wt, fpl1);
                hpl2 = plot(hax, wt, fpl2);
                hold(hax, 'off')
                % ylim([-0.5 3])
                xlabel('time (sec)');
                ylabel('filter amplitude');
                title({[num2str(norm1) ' :: ' num2str(sum1)]; [num2str(norm2) ' :: ' num2str(sum2)]})
            else
                hpl1.YData = fpl1;
                hpl2.YData = fpl2;
                hax.Title.String = {[num2str(norm1) ' :: ' num2str(sum1)]; [num2str(norm2) ' :: ' num2str(sum2)]};
            end
            fig2gif(hfg, framecount, filename_save)
        end
    end
end
