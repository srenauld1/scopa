function [ft, depvp, gof_train, gof_val] = fitmdl_fit(indv, depv, ri, optim_hist_save_iter_spacing, modeltype, ...
    validation_fold, indv_val, depv_val, sampinds_indvdepv_train, sampinds_indvdepv_val, num_samp_total, supp, opop, pth_fitdata)


% rng default

if optim_hist_save_iter_spacing
    histfit = init_optim_hist(opop.optiml.MaxIterations, opop.max_iter_global, optim_hist_save_iter_spacing, supp.num_par_total);
    opop.optimg.OutputFcn = @outfcn_global;
    opop.optiml.OutputFcn = @outfcn_local;
end

if startsWith(modeltype, 'svd')
    opop.optimp.objective = @objective_svd;
else
    if strcmp(opop.optimp.solver, 'fmincon')
        opop.optimp.objective = @(b) sum(( depv - opop.mdl(b, indv, supp) ).^2); %fmincon requires objective objective to define loss explicitly
    else
        opop.optimp.objective = opop.mdl; %fmincon requires objective objective to define loss explicitly
    end
end

%% fit model, predict response

if startsWith(modeltype, 'svd')
    ft = opop.optimp.objective( indv, depv, supp.pvar);
    %mdl_toy %synthetic data toy
else
    [ft, fval_gs, exitflag_gs, output_gs, solutions_gs] = run(opop.optimg, opop.optimp); %ft are fit params
    %[ftl, fvall, exfll, outl, laml, gradl, herssl] = fmincon(optimp.objective, x0, [], [], [], [], lbnd, ubnd, [], optimp.options); %example single run of local solver
end


%% predict train/val response, compute train/val gof (slot train/val depvp into same timeseries, later can be separated using indices)

depvp = zeros(num_samp_total, 1, 'single');

[depvp(sampinds_indvdepv_train), gof_train] = fitmdl_predict(ft, indv, depv, opop.mdl, supp);

if validation_fold %if doing validation
    [depvp(sampinds_indvdepv_val), gof_val] = fitmdl_predict(ft, indv_val, depv_val, opop.mdl, supp);
end


%% information criteria for model evaluation

% numsamp = length(depv);
% mpdiff = depv-depvp;
% sigma2 = var(mpdiff);
% logLikelihood = -0.5*numsamp*log(2*pi) - 0.5*numsamp*log(sigma2) - (1/(2*sigma2))*sum((mpdiff).^2);
% AIC = -2*logLikelihood + 2*supp.num_par_total; % calculate the AIC value
% [~,~,ic] = aicbic(logLikelihood,supp.num_par_total,numsamp,'Normalize',true);

%% save optimization history

savepath = [pth_fitdata(1:end-4) num2str(ri) '_HISTFIT_.mat'];
parsave(savepath, histfit) %save histfit, must use separate function


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


