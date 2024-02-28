                    % sorting_targets = {'none'}; %{'none', 'mu'}
                    % for mji = 1:length(sorting_targets)
                    %
                    %     sorting_target = sorting_targets{mji};
                    %
                    %     if strcmp(sorting_target, 'none') %if not sorting
                    %         numfram = 1e10;
                    %         for epi = 1:length(epochinds_plot) %find min epoch length, and plot that many frames (so they can be contiguous)
                    %             numfram = min([numfram numel(find(trialepochinds_i==epochinds_plot(epi)))]);
                    %         end
                    %     else
                    %         numfram = 150; %if sorting, plot less (not strictly necessary, could plot all)
                    %     end
                    %
                    %
                    %     mask_with_3d_mask = 0;
                    %     plot_only_outliers = 0; %in the raw fluorescence 3d movie
                    %     bump_method_index_save = 1; %keep at 1 right now, not written yet to vary
                    %     bump_method_index_plot = 1; %keep at 1 right now, not written yet to vary
                    %     pltindz = [1];%[1 2]; %keep at 1 right now, not written yet to vary %indices of fi below
                    %     ncol = 128; %num colors in gifs
                    %     makeroomfac_mu = 0.1;
                    %     makeroomfac_rho = 0.1;
                    %     epochinds_plot = [2 3 4];
                    %     percentile_to_plot = 99.5;
                    %     plotcolz = {[1 0 0], [0.4660 0.6740 0.1880], [0 1 0]};
                    %     startsec = 1; %only relevant if dosort=0
                    %     stopsec = 20; %only relevant if dosort=0
                    %     xlim_makeroomfac = 0.1;
                    %     nanpadlen_min_input = 20;
                    %     gif_visibility = 'on';
                    %     separate_vis_and_bump = 0;
                    %
                    %     % "DONT FORGET ROTATE THE MASK PLOT POSTERIOR TO SHOW ALL CLUST_"
                    %     % plot_bump(alpha_plot, resp_plot, mu_plot, rho_plot, visang, ballang, ...
                    %     %     ampmu_plot, amppeak_plot, ampmean_plot, resp_gar, resp_gal, resp_nor, resp_nol, ...
                    %     %     epochinds_plot, md, centinds, halfcent, pltindz, numfram, startsec, stopsec,  ...
                    %     %     imdata, percentile_to_plot, mask_mroi, mask_with_3d_mask, inds_roi, plot_only_outliers, ...
                    %     %     plotcolz, xlim_makeroomfac, makeroomfac_rho, makeroomfac_mu, ncol, ...
                    %     %     gif_visibility, separate_vis_and_bump, sorting_target, ...
                    %     %     bump_method_index_plot, fn_prefix, nanpadlen_min_input)
                    %
                    % end