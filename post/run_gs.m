function [ft, gof, predresp, hdata, sdata, vdata, pstim] = ...
    run_gs(slvrl, objfcn, resp, stim, x0, lbnd, ubnd, linineq_A, linineq_b, ...
    gethue, getsat, getval, supp, ri, pth_fitdata_epoch)


% patternsearch satisfies linear constraints at intermediate iterations.
% does globalsearch?

rng default %for reproducibility (do on every loop?)

%% variables for output functions

histfit.max_iter_local = 10000;
histfit.max_iter_global = 5;
histfit.max_unique_sol_global = 3; %run indefinite global search iterations until it finds histfit.max_iter_global unique local solutions . . .  make empty to not set limit
histfit.local_sol_is_unique_thresh = 1e-4; %local solution flagged as unique (recorded in histfit.unique_local_fval) if it differs from all other local solutions by at least histfit.local_sol_is_unique_thresh
histfit.save_iter_spacing = 3; %record optimization data in histfit.local fields every histfit.save_iter_spacing iteration of the local solver (continuous across global iterations)
histfit.dummyval = 61616161; %written to histfit.x_l and histfit.fval_l to help easily distinguish init rows (start of global iteration) by eye
histfit.precision = 'single';

histfit.x_l = zeros(supp.num_par_total, histfit.max_iter_local, histfit.max_iter_global, histfit.precision); %x across local iterations, continuous across global iterations
histfit.fval_l = zeros(histfit.max_iter_local, histfit.max_iter_global, histfit.precision); %fval across local iterations, continuous across global iterations
histfit.iter_l = zeros(histfit.max_iter_local, histfit.max_iter_global, histfit.precision);
histfit.x_g = zeros(supp.num_par_total, histfit.max_iter_global, histfit.precision); %x across global iterations,
histfit.fval_g = zeros(histfit.max_iter_global, 1, histfit.precision); %fval across global iterations,
histfit.iter_g = zeros(histfit.max_iter_global, 1, histfit.precision);
histfit.exitflag_g = []; %don't index into zeros for this one because it might contain zeros we don't want to remove 
histfit.bestx_g = [];
histfit.bestfval_g = [];
histfit.unique_local_fval = [];

save_iter_count_local = 1;
save_iter_count_global = 1;
save_unique_sol_count_global = 1;

%% global solver options

slvrg = GlobalSearch; %globalsearch can only use fmincon

slvrg.NumTrialPoints = 100000; %1000
slvrg.BasinRadiusFactor = 0.2000; %0.2000
slvrg.DistanceThresholdFactor = 0.7500; %0.7500
slvrg.MaxWaitCycle = 20; %20
slvrg.NumStageOnePoints = 20000; %200
slvrg.PenaltyThresholdFactor = 0.2000; %0.2000
slvrg.Display = 'final'; %'final'
slvrg.FunctionTolerance = 1.0000e-06; %1.0000e-06
slvrg.MaxTime = Inf; %Inf
slvrg.OutputFcn = @outfcn_global; %[]
slvrg.PlotFcn = [];%{@gsplotbestf, @gsplotfunccount}; %[]
slvrg.StartPointsToRun = 'bounds-ineqs'; %'all'
slvrg.XTolerance = 1.0000e-06; %1.0000e-06


%% local solver options

optopts = optimoptions(slvrl);

% optopts.Algorithm = 'interior-point'; %algorithm chosen automatically?? . . . was using 'Algorithm', 'interior-point'); % https://www.mathworks.com/help/optim/ug/choosing-the-algorithm.html
% optopts.BarrierParamUpdate = 'monotone';
% optopts.CheckGradients = false;
% optopts.ConstraintTolerance = 1.0000e-06;
optopts.Display = 'iter-detailed'; %'final'; %iter-detailed
% optopts.EnableFeasibilityMode = false;
% optopts.FiniteDifferenceStepSize = 'sqrt(eps)';
optopts.FiniteDifferenceType = 'central'; %'forward'
% optopts.HessianApproximation = 'bfgs';
% optopts.HessianFcn = [];
% optopts.HessianMultiplyFcn = [];
% optopts.HonorBounds = 1;
optopts.MaxFunctionEvaluations = Inf; %3000 for interior-point, 100*numvariables for others
optopts.MaxIterations = histfit.max_iter_local; %1000 for interior-point, 400 for others
% optopts.ObjectiveLimit = -1.0000e+20;
% optopts.OptimalityTolerance = 1.0000e-06;
optopts.OutputFcn = @outfcn_local; %[];
% optopts.PlotFcn = [];
% optopts.ScaleProblem = false; %false
% optopts.SpecifyConstraintGradient = 0;
% optopts.SpecifyObjectiveGradient = 0;
% optopts.StepTolerance = 1.0000e-10; %set to zero, along with OptimalityTolerance, to force fminncon to run specified number of iterations in MaxIterations
% optopts.SubproblemAlgorithm = 'factorization';
% optopts.TypicalX = 'ones(numberOfVariables,1)';
% optopts.UseParallel = 0;

%% optimization problem options

optprob = createOptimProblem(slvrl);

optprob.objective = @(b) sum(( resp - objfcn(b, stim, supp) ).^2); %fmincon requires objective function be sse explicitly
optprob.x0 = x0;
optprob.Aineq = linineq_A;
optprob.bineq = linineq_b;
optprob.Aeq = [];
optprob.beq = [];
optprob.lb = lbnd;
optprob.ub = ubnd;
optprob.nonlcon = [];
optprob.solver = slvrl;
optprob.options = optopts;

%% run

[ft, fval_gs, exitflag_gs, output_gs, solutions_gs] = run(slvrg, optprob); %ft are fit params

%[ftl, fvall, exfll, outl, laml, gradl, herssl] = fmincon(optprob.objective, ft, [], [], [], [], lbnd, ubnd, [], optprob.options); %single run of local solver

%% compute output variables


predresp = objfcn(ft, stim, supp); %predresp is predicted response
gof = mse(resp, predresp); %error

hdata = gethue(ft, stim, predresp);
sdata = getsat(gof);
vdata = getval(resp);

pstim = stim(find(max(predresp)==predresp,1));

save([pth_fitdata_epoch(1:end-4) num2str(ri) '_HISTFIT_.mat'], 'histfit', '-v7.3', '-mat')


%% (nested) output and plotting functions

    
    function stop = outfcn_local(x,optimValues,state)
        stop = false;
        switch state
            case 'init'
            case 'iter'
                if mod(optimValues.iteration, histfit.save_iter_spacing)==0
                    histfit.x_l(:,save_iter_count_local,save_iter_count_global) = x; %x must be a row vector.
                    histfit.fval_l(save_iter_count_local,save_iter_count_global) = optimValues.fval;
                    histfit.iter_l(save_iter_count_local,save_iter_count_global) = optimValues.iteration + 1; %local iteration starts at 0, make it 1 indexed (arbitrary)
                    save_iter_count_local = save_iter_count_local + 1;
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
                histfit.x_g(:,save_iter_count_global) = optimValues.localsolution.X; %x must be a row vector.
                histfit.fval_g(save_iter_count_global) = optimValues.localsolution.Fval;
                histfit.iter_g(save_iter_count_global) = optimValues.localrunindex; %make it 1 indexed (arbitrary)
                histfit.exitflag_g = [histfit.exitflag_g optimValues.localsolution.Exitflag];
                currfval = optimValues.localsolution.Fval;
                exitflag = optimValues.localsolution.Exitflag;
                save_iter_count_global = save_iter_count_global + 1;
                save_iter_count_local = 1; %reset here
                if exitflag > 0 && all(abs(currfval - histfit.unique_local_fval) > histfit.local_sol_is_unique_thresh)
                    histfit.unique_local_fval(save_unique_sol_count_global) = currfval;
                    save_unique_sol_count_global = save_unique_sol_count_global + 1;
                    if save_unique_sol_count_global > histfit.max_unique_sol_global %|| unique_local_fval(end) < 0.5
                        stop = true;
                    end
                end
                if save_iter_count_global > histfit.max_iter_global
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

end


