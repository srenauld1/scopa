
function plots_scratch(filename_sd_full)

num_panel_frames = 192;

smoothfac_i = 5; %define how many frames to smooth 2p data. both for bump parameters, and for fluorescence. gaussian filter.
smooth_iter = 5; %set how many times to perform gaussian smoothing on fictrac

max_lag = 1e3; %max lag to search for optimal cross correlation between dF/F and kinematics, in seconds
vel_thresh = 10; %exclude points in bump to fly vel correlation that are faster than 10rad/s
vel_min = 1e-1; %exclude points in bump to fly vel correlation where fly is slower than .01rad/s (effectively just fictrac noise)
rho_thresh = 5e-3;
c1 = [1, 0.5, 0]; %define the colors for the left and right bump
c2 = [0, 0.5, 1];
c3 = [0, 1, 0.5];

alp = [0.7 0.7 0.7];
splits = 140:20:440;
splits2 = [splits(1:2:end); splits(1:2:end)+20]';

openinds = [];
for si = 1:size(splits2,1)
    openinds = [openinds splits2(si,1):splits2(si,2)];
end
closedinds = openinds+20;

%% load imaging data

load(filename_sd_full)

intHD = ball.intHD;
cue = ball.cue;
f_vel = ball.f_vel;
r_vel = ball.r_vel;
f_speed = ball.f_speed;
r_speed = ball.r_speed;

for pii = 1:length(region)
    switch region{pii}{1}
        case 'PB'
            dff_pb = resp{pii}.zscore;
            mu = bump{pii}.mu;
            rho = bump{pii}.rho;
            amp_pb = bump{pii}.amp_pb;
            amp_mu = bump{pii}.amp_mu;
            amp_peak = bump{pii}.amp_peak;
            domain = bump{pii}.domain;
        case 'GA'
            dff_gall = resp{pii}.zscore(1,:);
        case 'NO'
            dff_no = resp{pii}.zscore(1,:);
    end
end
dff_pb = dff_pb(~isnan(mean(dff_pb,2)),:); %make sure none of the PB ROIs have nans introduced by extraction

xf = mean(diff(ball.trialtime)) * [1:length(ball.f_speed)]; %create a time vector for the fictrac data. have to remake because of the error frames %create vectors with timestamps for each trace
xf = seconds(xf);
total_t = max(xf);
xb = linspace(0,total_t,metadata.numframes)';
fr_i = mean(diff(xb)); %imaging sampling rate
fr_b = mean(diff(xf)); %behavior sampling rate

smoothfac_b = round(smoothfac_i / (fr_b/fr_i)); %set how many frames to smooth for fictrac. gaussian, and repeated n times because very noisy

%% smooth imaging and fictrac data, and interp imaging onto fictrac

mu = unwrap(mu); %unwrap to perform circular smoothing. keeps radians continuous, so that smoothing 0 and 2pi doesnt go to 1pi
%mu2d = unwrap(mu2d); %unwrap to perform circular smoothing. keeps radians continuous, so that smoothing 0 and 2pi doesnt go to 1pi
intHD = unwrap(intHD);
cue = unwrap(cue / num_panel_frames * 2*pi - pi);

for i = 1:smooth_iter %smooth fictrac data n times, since fictrac is super noisy.
    if i<2000
        mu = smoothdata(mu,'gaussian',smoothfac_i); %smooth all bump parameters.
        rho = smoothdata(rho,'gaussian',smoothfac_i);
        %         mu2d = smoothdata(mu2d,'gaussian',smoothfac_i); %smooth all bump parameters.
        %         rho2d = smoothdata(rho2d,'gaussian',smoothfac_i);
        dff_no = smoothdata(dff_no,'gaussian',smoothfac_i);
        dff_gall = smoothdata(dff_gall,'gaussian',smoothfac_i);
        amp_pb = smoothdata(amp_pb,'gaussian',smoothfac_i);
        amp_mu = smoothdata(amp_mu,'gaussian',smoothfac_i);
        amp_peak = smoothdata(amp_peak,'gaussian',smoothfac_i);
    end
    f_vel = smoothdata(f_vel,'gaussian',smoothfac_b);
    f_speed = smoothdata(f_speed,'gaussian',smoothfac_b);
    r_vel = smoothdata(r_vel,'gaussian',smoothfac_b);
    r_speed = smoothdata(r_speed,'gaussian',smoothfac_b);
    intHD = smoothdata(intHD,'gaussian',smoothfac_b);
    cue = smoothdata(cue,'gaussian',smoothfac_b);
end

mu = interp1(xb,mu,xf)';
rho = interp1(xb,rho,xf)';
% mu2d = interp1(xb,mu2d,xf)';
% rho2d = interp1(xb,rho2d,xf)';
amp_mu_hf = interp1(xb,amp_mu,xf)';
amp_pb = interp1(xb,amp_pb,xf)';
dff_pb_hf = amp_pb;
dff_no_hf = interp1(xb,dff_no,xf)';
dff_ga_hf = interp1(xb,dff_gall,xf)';
amp_peak = interp1(xb,amp_peak,xf)';


mu = mod(mu,2*pi); %rewrap heading data, and put between -pi and pi.
mu(mu > pi) = mu(mu > pi) - 2*pi;
% mu2d = mod(mu2d,2*pi); %rewrap heading data, and put between -pi and pi.
% mu2d(mu2d > pi) = mu2d(mu2d > pi) - 2*pi;
intHD = mod(intHD,2*pi);
intHD(intHD > pi) = intHD(intHD > pi) - 2*pi;
cue = mod(cue,2*pi);
cue(cue > pi) = cue(cue > pi) - 2*pi;


%% fit lags

f_vel_lag_pb = find_behavior_lag(xf, fr_i, max_lag, amp_pb, f_vel);
f_speed_lag_pb = find_behavior_lag(xf, fr_i, max_lag, amp_pb, f_speed);
r_vel_lag_pb = find_behavior_lag(xf, fr_i, max_lag, amp_pb, r_vel);
r_speed_lag_pb = find_behavior_lag(xf, fr_i, max_lag, amp_pb, r_speed);
r_vel_lag_no = find_behavior_lag(xf, fr_i, max_lag, dff_no_hf, r_vel);
r_speed_lag_no = find_behavior_lag(xf, fr_i, max_lag, dff_no_hf, r_speed);

amp_pb(isnan(amp_pb)) = 0;

[rv_pb_fit,rv_pb_gof] = fit(r_vel_lag_pb,amp_pb,'poly1');
[rs_pb_fit,rs_pb_gof] = fit(r_speed_lag_pb,amp_pb,'poly1');
[mv_pb_fit,mv_pb_gof] = fit([r_vel_lag_pb,f_vel_lag_pb],amp_pb,'poly11');
[ms_pb_fit,ms_pb_gof] = fit([r_speed_lag_pb,f_speed_lag_pb],amp_pb,'poly11');

%%

if 0
    
    %lag = ceil(fmincon(@(x)(circ_corrcc(cue(1:end-ceil(x)),-mu((ceil(x)+1):end))),20,[],[],[],[],0));
    
    lag = 20;
    rho_idx = rho>rho_thresh;
    [pva_corr,pva_pval] = circ_corrcc(cue(1:end-ceil(lag)),-mu((ceil(lag)+1):end));

    figure(7); clf
    subplot(3,1,1)
    a = plot(xf,cue,'k','linewidth',2);
    a.YData(abs(diff(a.YData))>pi) = nan;
    yticks([-pi,0,pi]); yticklabels({'-\pi','0','\pi'}); ylim([-pi,pi])
    ylabel('visual cue')

    subplot(3,1,2)
    scatter(xf(rho_idx),-mu(rho_idx),[],rho(rho_idx),'.')
    colormap('bone')
    yticks([-pi,0,pi]); yticklabels({'-\pi','0','\pi'}); ylim([-pi,pi])
    pos = get(gca,'Position');
    colorbar
    set(gca,'Position',pos)
    ylabel('Bump PVA')

    subplot(3,1,3)
    tmp = circ_dist(cue,-mu);
    a = plot(xf(rho_idx),tmp(rho_idx),'k','linewidth',2);
    a.YData(abs(diff(a.YData))>pi) = nan;
    ylabel('Offset')
    yticks([-pi,0,pi]); yticklabels({'-\pi','0','\pi'})

    linkaxes(get(gcf,'Children'),'x')
    axis tight; ylim([-pi,pi])
    xlabel('time (s)')


    %% plot velocities

    figure
    plot(xf,r_vel_lag_pb,'k'); ylabel('Rotational velocity (rad/s) lag PB')
    yyaxis right; plot(xf, amp_pb,'Color',c1); ylabel('Average \DeltaF/F');
    ax = gca;
    ax.YAxis(2).Color = c1;
    xlabel('time (s)')
    axis tight
    % y = ylim; text(xb(end),y(2),sprintf('r^2: %.2f\n2p lag: %.1fs\njoint r^2:%.2f',...
    %                                 r_gof.adjrsquare,r_lag*fr,m_gof.adjrsquare),...
    %                 'HorizontalAlignment','right','VerticalAlignment','top')
    y = ylim; text(xf(end),y(2),sprintf('r^2: %.2f\njoint r^2: %.2f',...
        rv_pb_gof.adjrsquare,mv_pb_gof.adjrsquare),...
        'HorizontalAlignment','right','VerticalAlignment','top')


    figure
    plot(xf,r_speed_lag_pb,'k'); ylabel('Rotational Speed (rad/s) lag PB')
    yyaxis right; plot(xf, amp_pb,'Color',c1); ylabel('Average \DeltaF/F');
    ax = gca;
    ax.YAxis(2).Color = c1;
    xlabel('time (s)')
    axis tight
    % y = ylim; text(xb(end),y(2),sprintf('r^2: %.2f\n2p lag: %.1fs\njoint r^2:%.2f',...
    %                                 r_gof.adjrsquare,r_lag*fr,m_gof.adjrsquare),...
    %                 'HorizontalAlignment','right','VerticalAlignment','top')
    y = ylim; text(xf(end),y(2),sprintf('r^2: %.2f\njoint r^2: %.2f',...
        rs_pb_gof.adjrsquare,ms_pb_gof.adjrsquare),...
        'HorizontalAlignment','right','VerticalAlignment','top')

end
%%

%
%
% figure
% plot(xf,r_vel_lag_no,'k');
% ax = gca;
% leftlim = ax.YAxis(1).Limits;
% hold on
% plot(xf, dff_no_hf,'Color',c1);
% ylim(leftlim);
% xlabel('time (s)')
% title('ball rot speed and GLNO dff (nodulus)')
% axis tight
%
% figure
% plot(xf,r_speed_lag_no,'k');
% ax = gca;
% leftlim = ax.YAxis(1).Limits;
% hold on
% plot(xf, dff_no_hf,'Color',c1);
% ylim(leftlim);
% xlabel('time (s)')
% title('ball rot speed and GLNO dff (nodulus)')
% axis tight
%
%
%
% figure
% plot(xf,r_speed_lag_pb,'k');
% ax = gca;
% leftlim = ax.YAxis(1).Limits;
% hold on
% plot(xf, dff_ga_hf,'Color',c1);
% ylim(leftlim);
% xlabel('time (s)')
% title('ball rot speed and EPG dff (Gall)')
% axis tight



%%

%
% figure
% plot(xf,dff_pb_hf,'k'); ylabel('Rotational Speed (rad/s) lag Ga')
% ax = gca;
% leftlim = ax.YAxis(1).Limits;
% hold on
% plot(xf, dff_ga_hf,'Color',c1); ylabel('Average \DeltaF/F');
% ylim(leftlim);
% xlabel('time (s)')
% title('dff in pb and gall')
% axis tight

%%


% figure;
% scatter(dff_pb_hf, dff_ga_hf, '.')
% title('dff in pb and gall')


figure;
subplot(2,1,1)
scatter(dff_pb_hf(openinds), dff_ga_hf(openinds), '.')
title('dff in pb and gall (open loop)')

subplot(2,1,2)
scatter(dff_pb_hf(closedinds), dff_ga_hf(closedinds), '.')
title('dff in pb and gall (closed loop)')

%
% timez = 10000:11000;
% figure;
% scatter(dff_pb_hf(timez), dff_ga_hf(timez), '.')
%
%
% figure
% plot(xf(timez),dff_pb_hf(timez),'k'); ylabel('Rotational Speed (rad/s) lag Ga')
% ax = gca;
% leftlim = ax.YAxis(1).Limits;
% hold on
% plot(xf(timez), dff_ga_hf(timez),'Color',c1); ylabel('Average \DeltaF/F');
% ylim(leftlim);
% xlabel('time (s)')
% axis tight



%%

%
% tmp = unwrap(mu) - median(circ_dist(mu,-cue)); %- mu(1);
% tmp = mod(tmp,2*pi); %rewrap heading data, and put between -pi and pi.
% tmp(tmp > pi) = tmp(tmp > pi) - 2*pi;
% figure(12); clf
% a = plot(xf, tmp,'k','LineWidth',2);
% a.YData(abs(diff(a.YData)) > pi) = nan;
% hold on
% tmp = unwrap(cue); % - cue(1);
% tmp = mod(tmp,2*pi); %rewrap heading data, and put between -pi and pi.
% tmp(tmp > pi) = tmp(tmp > pi) - 2*pi;
% a = plot(xf, -tmp,'b','LineWidth',2);
% a.YData(abs(diff(a.YData)) > pi) = nan;
% axis tight
% ylabel('Azimuth (radians)')
% yticks([-pi,0,pi])
% ylim([-pi,pi])
% yticklabels({'-\pi','0','\pi'})
% a = gca;
% a.FontSize= 20;
% hold on
% for si = 1:size(splits2,1)
%     xbars = [splits2(si,1) splits2(si,2)];
%     patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
% end
% hold off
% % xticks([])
% % xticklabels([])
% legend('PVA','Cue')




%%


figure;
hold on
plot(xf,unwrap(cue),'k','linewidth',2)
plot(xf, -unwrap(mu),'b','linewidth',2)
plot(xf, -unwrap(intHD),'r','linewidth',2)
ylabel('accumulated rotation', 'FontSize',20)
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])
ylim([-220 150])
line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');


yyaxis right

plot(xf, amp_mu_hf,'magenta','linewidth',0.05, 'LineStyle','-');
plot(xf, dff_ga_hf,'color',[0.4660 0.6740 0.1880],'linewidth',0.05, 'LineStyle','-');
%plot(xf, dff_no_hf,'color',[1 0.5 0], 'linewidth',0.05, 'LineStyle','-');
ylim([-0.1 0.5])
ylim([-5 15])
ylabel('df/F                                     ', 'FontSize',20, 'Color','k')
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])
xlabel('seconds', 'FontSize',20, 'Color','k')
line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');
title({'bar in open loop (shading) or closed loop (no shading)'; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL';'\color{magenta}PB, \color[rgb]{0.4660 0.6740 0.1880}GA, \color[rgb]{1 0.5 0}NO' }, 'FontSize',20)


hold on
for si = 1:size(splits2,1)
    xbars = [splits2(si,1) splits2(si,2)];
    patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
end
xline(closedinds(end))
hold off



%%


figure
hold on
plot(xf,unwrap(cue),'k','linewidth',2)
plot(xf, -unwrap(mu),'b','linewidth',2)
plot(xf, -unwrap(intHD),'r','linewidth',2)
ylabel('accumulated rotation', 'FontSize',20)
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])
ylim([-220 150])
line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');

yyaxis right

plot(xf, dff_ga_hf,'color',[0.4660 0.6740 0.1880],'linewidth',0.05, 'LineStyle','-');
plot(xf, dff_no_hf,'color',[1 0.5 0], 'linewidth',0.05, 'LineStyle','-');
ylim([-0.1 0.5])
ylabel('df/F                                     ', 'FontSize',20, 'Color','k')
%set(gca,'ytick',[])
%set(gca,'yticklabel',[])
xlabel('seconds', 'FontSize',20, 'Color','k')
line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');
title({'bar in open loop (shading) or closed loop (no shading)'; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL'; '\color[rgb]{0.4660 0.6740 0.1880}GA,  \color[rgb]{1 0.5 0}NO' }, 'FontSize',20)


hold on
for si = 1:size(splits2,1)
    xbars = [splits2(si,1) splits2(si,2)];
    patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
end
xline(closedinds(end))
hold off




%%

%
% figure
% hold on
% plot(xf,unwrap(cue),'k','linewidth',2)
% plot(xf, -unwrap(mu2d),'b','linewidth',1, 'LineStyle','--')
% plot(xf, -unwrap(mu),'b','linewidth',2)
% plot(xf, -unwrap(intHD),'r','linewidth',2)
% ylabel('accumulated rotation', 'FontSize',20)
% %set(gca,'ytick',[])
% %set(gca,'yticklabel',[])
%
%
% title({'bar in open loop (shading) or closed loop (no shading)'; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL'; '\color[rgb]{0.4660 0.6740 0.1880}GA,  \color[rgb]{1 0.5 0}NO' }, 'FontSize',20)
%
%
% hold on
% for si = 1:size(splits2,1)
%     xbars = [splits2(si,1) splits2(si,2)];
%     patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
% end
% hold off


%%
%
% close all
%
% halfcent = size(dff_pb,1)/2;
% % [~, md1a]=sort(dff_pb(1:halfcent,:));
% % [~, md2a]=sort(dff_pb(halfcent+1:end,:));
% cmap = make_colors(halfcent); %set a colormap to plot each centroid in a different color, and which repeats per hemisphere (note that if a hemisphere has more clusters than colorbrewer can generate, it will repeat colors within each hemisphere).
%
% murs = round(interp1(linspace(-pi, pi, 1000), linspace(1, halfcent+1, 1000), mu));
% murs(murs==halfcent+1) = halfcent;
% cmurs = cmap(murs, :);
%
% %ydm = -unwrap(mu2d);
% ydm = -unwrap(mu);
%
% figure
% hold on
% plot(xf,unwrap(cue),'k','linewidth',2)
% for i = 1 : length(xf) - 1
%   line('XData', xf(i:i+1), 'YData', ydm(i:i+1), 'Color', cmurs(i, :), 'linewidth',2);
% end
% %plot(xf, -unwrap(mu),'b','linewidth',2)
% plot(xf, -unwrap(intHD),'r','linewidth',2)
% ylabel('accumulated rotation', 'FontSize',20)
% %set(gca,'ytick',[])
% %set(gca,'yticklabel',[])
% % ylim([-220 150])
% % line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');
%
%
% % yyaxis right
% %
% % plot(xf, dff_ga_hf,'color',[0.4660 0.6740 0.1880],'linewidth',0.05, 'LineStyle','-');
% % plot(xf, dff_no_hf,'color',[1 0.5 0], 'linewidth',0.05, 'LineStyle','-');
% % ylim([-0.1 0.5])
% % ylabel('df/F                                     ', 'FontSize',20, 'Color','k')
% % %set(gca,'ytick',[])
% % %set(gca,'yticklabel',[])
% % xlabel('seconds', 'FontSize',20, 'Color','k')
% % line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');
% % title({'bar in open loop (shading) or closed loop (no shading)'; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL'; '\color[rgb]{0.4660 0.6740 0.1880}GA,  \color[rgb]{1 0.5 0}NO' }, 'FontSize',20)
%
% title({'bar in open loop (shading) or closed loop (no shading)'; '\color{black}CUE, \color{blue}BUMP, \color{red}BALL' }, 'FontSize',20)
%
% hold on
% for si = 1:size(splits2,1)
%     xbars = [splits2(si,1) splits2(si,2)];
%     patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
% end
% hold off
%
%
% %%
%
% %
% % figure
% % hold on
% % %plot(xf,unwrap(cue),'k','linewidth',2)
% % plot(xf, mu2d,'b','linewidth',1)
% % plot(xf, mu,'b','linewidth',2)
% % %plot(xf, -unwrap(intHD),'r','linewidth',2)
% % ylabel('accumulated rotation', 'FontSize',20)
% % %set(gca,'ytick',[])
% % %set(gca,'yticklabel',[])
% % ylim([-12 12])
% % line(xlim(), [0,0], 'LineWidth', 1, 'Color', 'k');
% %
% % hold on
% % for si = 1:size(splits2,1)
% %     xbars = [splits2(si,1) splits2(si,2)];
% %     patch([xbars(1) xbars(1), xbars(2) xbars(2)], [min(ylim) max(ylim) max(ylim) min(ylim)], alp, 'FaceAlpha', 0.2)
% % end
% % hold off
%
%


SaveOpenFigures([filename_sd_full(1:end-4) 'figz'])
stopit = 1;
