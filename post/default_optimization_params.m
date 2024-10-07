function pout = default_optimization_params(pin)

%currently only uses one global optimization solver, GlobalSearch

% patternsearch satisfies linear constraints at intermediate iterations, does globalsearch?

if ~exist('pin', 'var') || ~isfield(pin, 'slvrl')
    slvrl = 'fmincon';
else
    slvrl = pin.slvrl;
end
if ~exist('pin', 'var') || ~isfield(pin, 'max_iter_local')
    max_iter_local = 1000;
else
    max_iter_local = pin.max_iter_local;
end
if ~exist('pin', 'var') || ~isfield(pin, 'max_iter_global')
    max_iter_global = 3;
else
    max_iter_global = pin.max_iter_global;
end

mdl = []; %this is the model function


%% global solver options


optimg = GlobalSearch; %globalsearch can only use fmincon

optimg.NumTrialPoints = 1000; %1000
optimg.BasinRadiusFactor = 0.2; %0.2000
optimg.DistanceThresholdFactor = 0.75; %0.7500
optimg.MaxWaitCycle = 20; %20
optimg.NumStageOnePoints = 200; %200
optimg.PenaltyThresholdFactor = 0.2; %0.2000
optimg.Display = 'final'; %'final'
optimg.FunctionTolerance = 1e-6; %1.0000e-06
optimg.MaxTime = Inf; %Inf
optimg.OutputFcn = []; %[]
optimg.PlotFcn = []; %{@gsplotbestf, @gsplotfunccount}; %[]
optimg.StartPointsToRun = 'bounds-ineqs'; %'all'
optimg.XTolerance = 1e-6; %1.0000e-06



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
optiml.MaxIterations = max_iter_local; %1000 for interior-point, 400 for others
% optiml.ObjectiveLimit = -1.0000e+20;
% optiml.OptimalityTolerance = 1.0000e-06;
optiml.OutputFcn = []; %[];
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

optimp.objective = []; %this can be same as mdl, or may be loss given output of mdl
optimp.x0 = [];
optimp.Aineq = [];
optimp.bineq = [];
optimp.Aeq = [];
optimp.beq = [];
optimp.lb = [];
optimp.ub = [];
optimp.nonlcon = [];
optimp.solver = slvrl;
optimp.options = optiml;

%% assign to struct

update_param_struct; %call this script to overwrite any default params above with fields in pin, and organize into pout

end
