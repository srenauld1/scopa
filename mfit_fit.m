function [ft, pred, mse_train, mse_val] = mfit_fit(indv, depv, ri, optim_hist_save_iter_spacing, mdlname, ...
    validation_fold, indv_val, depv_val, sampinds_indvdepv_train, sampinds_indvdepv_val, num_samp_total, supp, op, depvmin, depvmax, pth_fitdata)


% rng default

do_nonlinear_constraint = 0;
save_progress_files = 1; %save a dummy file on every completed fit so you can monitor progress more easily on long parallel runs

if optim_hist_save_iter_spacing
    histfit = init_optim_hist(op.opp.options.MaxIterations, op.max_iter_global, optim_hist_save_iter_spacing, supp.num_par_total);
    op.opg.OutputFcn = @outfcn_global;
    op.opp.options.OutputFcn = @outfcn_local;
else
    histfit = 1; %assign dummy var in case save_progress_files is true
end

if startsWith(mdlname, 'svd')
    op.opp.objective = @objective_svd;
else
    if strcmp(op.opp.solver, 'fmincon')
        % op.opp.objective = @(pars) sum(( depv - op.mdl(pars, indv, supp) ).^2); %sum of squared error; fmincon requires objective objective to define loss explicitly
        op.opp.objective = @(pars) mse( depv, op.mdl(pars, indv, supp)); %mse; fmincon requires objective objective to define loss explicitly
    else
        op.opp.objective = op.mdl; %fmincon requires objective objective to define loss explicitly
    end
end

if do_nonlinear_constraint
    if isfield(supp, 'pind_Lfree') && ~isempty(supp.pind_Lfree) || isfield(supp, 'pind_vonmises') && ~isempty(supp.pind_vonmises)
        op.opp.nonlcon = @nlcon_fnet;
    end
end

%% fit model, predict response


if startsWith(mdlname, 'svd')
    ft = op.opp.objective( indv, depv, supp.pvar);
    %mdl_toy %synthetic data toy
else
    [ft, fval_gs, exitflag_gs, output_gs, solutions_gs] = run(op.opg, op.opp); %ft are fit params
    %[ftl, fvall, exfll, outl, laml, gradl, herssl] = fmincon(opp.objective, x0, [], [], [], [], lbnd, ubnd, [], opp.options); %example single run of local solver
end


%% predict train/val response, compute train/val gof (slot train/val pred into same timeseries, later can be separated using indices)

pred = zeros(num_samp_total, 1, 'single');

if startsWith(mdlname, 'svd')
    pred(sampinds_indvdepv_train) = indv*ft;
    mse_train = mse(depv, pred(sampinds_indvdepv_train));
else
    [pred(sampinds_indvdepv_train), mse_train] = mfit_predict(ft, indv, depv, op.mdl, supp);
end

if validation_fold %if doing validation
    [pred(sampinds_indvdepv_val), mse_val] = mfit_predict(ft, indv_val, depv_val, op.mdl, supp);
else
    mse_val = nan;
end


%% information criteria for model evaluation

% numsamp = length(depv);
% mpdiff = depv-pred;
% sigma2 = var(mpdiff);
% logLikelihood = -0.5*numsamp*log(2*pi) - 0.5*numsamp*log(sigma2) - (1/(2*sigma2))*sum((mpdiff).^2);
% AIC = -2*logLikelihood + 2*supp.num_par_total; % calculate the AIC value
% [~,~,ic] = aicbic(logLikelihood,supp.num_par_total,numsamp,'Normalize',true);

%% save optimization history

if optim_hist_save_iter_spacing
    savepath = [pth_fitdata(1:end-4) num2str(ri) '_HISTFIT_.mat'];
    parsave(savepath, histfit) %save histfit, must use separate function
end
if save_progress_files
    savepath = [pth_fitdata(1:end-4) num2str(ri) '_HISTFIT_.mat'];
    parsave(savepath, histfit) %save histfit, must use separate function
end


%% constraint function


    function [c,ceq] = nlcon_fnet(x)
        
        %the two vonmises constraints are not great because they force the curve max and min to match data max and min but data is noisy, so the curve won't fit optimally, would be better to match max and min of some filtered version of data, or just skip the constraint 

        countz = 0;
        for j = 1:length(supp.pind_Lfree)
            countz = countz+1;
            ceq(countz) = norm(vec(x(supp.pind_Lfree{j})),1) - 1; %make L1norm = 1 for linear filters with 'freeform' flag
        end
        for j = 1:length(supp.pind_vonmises)
            countz = countz+1;
            nlpars = x(supp.pind_vonmises{j});
            obfunval = nlpars(1)*exp(nlpars(2)*cos(indv-nlpars(3)))+nlpars(4);
            ceq(countz) = min(obfunval) - depvmin; %max and min match data max and min (not controllable as params of von mises)
            countz = countz+1;
            ceq(countz) = max(obfunval) - depvmax; %max and min match data max and min (not controllable as params of von mises)
        end
        c = [];

    end

%% output and plotting functions (nested to preserve info across iterations)

    function stop = outfcn_local(x,optimValues,state)
        stop = false;
        switch state
            case 'init'
            case 'iter'
                if mod(optimValues.iteration, histfit.optim_hist_save_iter_spacing)==0
                    histfit.x_l(:,histfit.save_iter_count_local,histfit.save_iter_count_global) = x; %x must be a row vector.
                    % histfit.ic(histfit.save_iter_count_local,histfit.save_iter_count_global) = ic;
                    histfit.fval_l(histfit.save_iter_count_local,histfit.save_iter_count_global) = optimValues.fval;
                    histfit.iter_l(histfit.save_iter_count_local,histfit.save_iter_count_global) = optimValues.iteration + 1; %local iteration starts at 0, make it 1 indexed (arbitrary)
                    histfit.save_iter_count_local = histfit.save_iter_count_local + 1;
                end
            case 'done'
            otherwise
        end
    end


    function stop = outfcn_global(optimValues, state)
        stop = false;
        switch state
            case 'init'
                % optimValues.localrunindex is zero at init time, and 1 after first local run finishes;
            case 'iter'
                histfit.x_g(:,histfit.save_iter_count_global) = optimValues.localsolution.X; %x must be a row vector.
                histfit.fval_g(histfit.save_iter_count_global) = optimValues.localsolution.Fval;
                histfit.iter_g(histfit.save_iter_count_global) = optimValues.localrunindex; %make it 1 indexed (arbitrary)
                histfit.exitflag_g = [histfit.exitflag_g optimValues.localsolution.Exitflag];
                currfval = optimValues.localsolution.Fval;
                exitflag = optimValues.localsolution.Exitflag;
                histfit.save_iter_count_global = histfit.save_iter_count_global + 1;
                histfit.save_iter_count_local = 1; %reset here
                if exitflag > 0 && all(abs(currfval - histfit.unique_local_fval) > histfit.local_sol_is_unique_thresh)
                    histfit.unique_local_fval(histfit.save_unique_sol_count_global) = currfval;
                    histfit.save_unique_sol_count_global = histfit.save_unique_sol_count_global + 1;
                    if histfit.save_unique_sol_count_global > histfit.max_unique_sol_global %|| unique_local_fval(end) < 0.5
                        stop = true;
                    end
                end
                if histfit.save_iter_count_global > histfit.max_iter_global
                    stop = true;
                end
            case 'done'
                histfit.bestx_g = optimValues.bestx;
                histfit.bestfval_g = optimValues.bestfval;

                fns = fieldnames(histfit);
                for fi = 1:length(fns) %remove all-zero rows/columns/slices for each field
                    if ~strcmp(fns{fi}, 'exitflag_g') %don't remove all-zero dimension for exitflag_g since they are meaningful
                        histfit.(fns{fi}) = histfit.(fns{fi})(any(histfit.(fns{fi}) ~= 0,[2 3]), any(histfit.(fns{fi}) ~= 0,[1 3]), any(histfit.(fns{fi}) ~= 0,[1 2]));
                    end
                end
        end
    end

%% save function (nesting required when run_gs called within parfor)

    function parsave(savepath, histfit)

        save(savepath, 'histfit', '-v7.3', '-mat')

    end


end


