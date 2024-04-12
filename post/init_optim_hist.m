function histfit = init_optim_hist(max_iter_global, max_iter_local, optim_hist_save_iter_spacing, num_par_total)

%% variables for global optimization output function(s), to save optimization history

histfit.max_iter_local = max_iter_local;
histfit.max_iter_global = max_iter_global;
histfit.max_unique_sol_global = max_iter_global; %run indefinite global search iterations until it finds histfit.max_iter_global unique local solutions . . .  make empty to not set limit
histfit.local_sol_is_unique_thresh = 1e-4; %local solution flagged as unique (recorded in histfit.unique_local_fval) if it differs from all other local solutions by at least histfit.local_sol_is_unique_thresh
histfit.optim_hist_save_iter_spacing = optim_hist_save_iter_spacing; %record optimization data in histfit.local fields every histfit.optim_hist_save_iter_spacing iteration of the local solver (continuous across global iterations)
histfit.dummyval = inf; %written to histfit.x_l and histfit.fval_l to help easily distinguish init rows (start of global iteration) by eye
histfit.precision = 'single';

histfit.x_l = zeros(num_par_total, histfit.max_iter_local, histfit.max_iter_global, histfit.precision); %x across local iterations, continuous across global iterations
%histfit.ic = zeros(num_par_total, histfit.max_iter_local, histfit.max_iter_global, histfit.precision); %x across local iterations, continuous across global iterations
histfit.fval_l = zeros(histfit.max_iter_local, histfit.max_iter_global, histfit.precision); %fval across local iterations, continuous across global iterations
histfit.iter_l = zeros(histfit.max_iter_local, histfit.max_iter_global, histfit.precision);
histfit.x_g = zeros(num_par_total, histfit.max_iter_global, histfit.precision); %x across global iterations,
histfit.fval_g = zeros(histfit.max_iter_global, 1, histfit.precision); %fval across global iterations,
histfit.iter_g = zeros(histfit.max_iter_global, 1, histfit.precision);
histfit.exitflag_g = []; %don't index into zeros for this one because it might contain zeros we don't want to remove
histfit.bestx_g = [];
histfit.bestfval_g = [];
histfit.unique_local_fval = [];

histfit.save_iter_count_local = 1;
histfit.save_iter_count_global = 1;
histfit.save_unique_sol_count_global = 1;