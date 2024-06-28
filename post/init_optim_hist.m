function histfit = init_optim_hist(max_iter_global, max_iter_local, optim_hist_save_iter_spacing, num_par_total)

%% variables for global optimization output function(s), to save optimization history

histfitm.max_iter_local = max_iter_local;
histfitm.max_iter_global = max_iter_global;
histfitm.max_unique_sol_global = max_iter_global; %run indefinite global search iterations until it finds histfitm.max_iter_global unique local solutions . . .  make empty to not set limit
histfitm.local_sol_is_unique_thresh = 1e-4; %local solution flagged as unique (recorded in histfitm.unique_local_fval) if it differs from all other local solutions by at least histfitm.local_sol_is_unique_thresh
histfitm.optim_hist_save_iter_spacing = optim_hist_save_iter_spacing; %record optimization data in histfitm.local fields every histfitm.optim_hist_save_iter_spacing iteration of the local solver (continuous across global iterations)
histfitm.dummyval = inf; %written to histfitm.x_l and histfitm.fval_l to help easily distinguish init rows (start of global iteration) by eye
histfitm.precision = 'single';

histfitm.x_l = zeros(num_par_total, histfitm.max_iter_local, histfitm.max_iter_global, histfitm.precision); %x across local iterations, continuous across global iterations
%histfitm.ic = zeros(num_par_total, histfitm.max_iter_local, histfitm.max_iter_global, histfitm.precision); %x across local iterations, continuous across global iterations
histfitm.fval_l = zeros(histfitm.max_iter_local, histfitm.max_iter_global, histfitm.precision); %fval across local iterations, continuous across global iterations
histfitm.iter_l = zeros(histfitm.max_iter_local, histfitm.max_iter_global, histfitm.precision);
histfitm.x_g = zeros(num_par_total, histfitm.max_iter_global, histfitm.precision); %x across global iterations,
histfitm.fval_g = zeros(histfitm.max_iter_global, 1, histfitm.precision); %fval across global iterations,
histfitm.iter_g = zeros(histfitm.max_iter_global, 1, histfitm.precision);
histfitm.exitflag_g = []; %don't index into zeros for this one because it might contain zeros we don't want to remove
histfitm.bestx_g = [];
histfitm.bestfval_g = [];
histfitm.unique_local_fval = [];

histfitm.save_iter_count_local = 1;
histfitm.save_iter_count_global = 1;
histfitm.save_unique_sol_count_global = 1;