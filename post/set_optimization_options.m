function [optimg, optiml, optimp] = set_optimization_options(supp)

%currently only uses one global optimization solver, GlobalSearch


%% global solver options

optimg = GlobalSearch; %globalsearch can only use fmincon

optimg.NumTrialPoints = supp.NumTrialPoints; %1000
optimg.BasinRadiusFactor = supp.BasinRadiusFactor; %0.2000
optimg.DistanceThresholdFactor = supp.DistanceThresholdFactor; %0.7500
optimg.MaxWaitCycle = supp.MaxWaitCycle; %20
optimg.NumStageOnePoints = supp.NumStageOnePoints; %200
optimg.PenaltyThresholdFactor = supp.PenaltyThresholdFactor; %0.2000
optimg.Display = 'final'; %'final'
optimg.FunctionTolerance = supp.FunctionTolerance; %1.0000e-06
optimg.MaxTime = Inf; %Inf
optimg.OutputFcn = @outfcn_global; %[]
optimg.PlotFcn = []; %{@gsplotbestf, @gsplotfunccount}; %[]
optimg.StartPointsToRun = 'bounds-ineqs'; %'all'
optimg.XTolerance = supp.XTolerance; %1.0000e-06



%% local solver options

optiml = optimoptions(slvrl);

% optiml.Algorithm = 'interior-point'; %algorithm chosen automatically?? . . . was using 'Algorithm', 'interior-point'); % https://www.mathworks.com/help/optim/ug/choosing-the-algorithm.html
% optiml.BarrierParamUpdate = 'monotone';
% optiml.CheckGradients = false;
% optiml.ConstraintTolerance = 1.0000e-06;
optiml.Display = 'iter-detailed'; %'final'; %iter-detailed
% optiml.EnableFeasibilityMode = false;
% optiml.FiniteDifferenceStepSize = 'sqrt(eps)';
optiml.FiniteDifferenceType = 'central'; %'forward'
% optiml.HessianApproximation = 'bfgs';
% optiml.HessianFcn = [];
% optiml.HessianMultiplyFcn = [];
% optiml.HonorBounds = 1;
optiml.MaxFunctionEvaluations = Inf; %3000 for interior-point, 100*numvariables for others
optiml.MaxIterations = histfit.max_iter_local; %1000 for interior-point, 400 for others
% optiml.ObjectiveLimit = -1.0000e+20;
% optiml.OptimalityTolerance = 1.0000e-06;
optiml.OutputFcn = @outfcn_local; %[];
% optiml.PlotFcn = [];
% optiml.ScaleProblem = false; %false
% optiml.SpecifyConstraintGradient = 0;
% optiml.SpecifyObjectiveGradient = 0;
% optiml.StepTolerance = 1.0000e-10; %set to zero, along with OptimalityTolerance, to force fminncon to run specified number of iterations in MaxIterations
% optiml.SubproblemAlgorithm = 'factorization';
% optiml.TypicalX = 'ones(numberOfVariables,1)';
% optiml.UseParallel = 0;



%% optimization problem

optimp = createOptimProblem(slvrl);

optimp.objective = @(b) sum(( depv - objfcn(b, indv, supp) ).^2); %fmincon requires objective objective to define loss explicitly
optimp.x0 = x0;
optimp.Aineq = linineq_A;
optimp.bineq = linineq_b;
optimp.Aeq = [];
optimp.beq = [];
optimp.lb = lbnd;
optimp.ub = ubnd;
optimp.nonlcon = nlcon;
optimp.solver = slvrl;
optimp.options = optiml;

