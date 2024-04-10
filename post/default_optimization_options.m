function optout = default_optimization_options(optin)

if ~exist('optin', 'var') || ~isfield(optin, 'slvrl')
    optin.slvrl = 'fmincon';
end

%currently only uses one global optimization solver, GlobalSearch

% patternsearch satisfies linear constraints at intermediate iterations . . . does globalsearch?

%% global solver options


optimg = GlobalSearch; %globalsearch can only use fmincon

optimg.maxiterg = 100; %this is not a native globalsearch variable, but used in output function to stop optimization 

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

optiml = optimoptions(optin.slvrl);

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
optiml.MaxIterations = 1000; %1000 for interior-point, 400 for others
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

optimp = createOptimProblem(optin.slvrl);

optimp.modfun = []; %this is the model function 
optimp.objective = []; %this can be same as modfun, or may be loss given output of modfun
optimp.x0 = [];
optimp.Aineq = [];
optimp.bineq = [];
optimp.Aeq = [];
optimp.beq = [];
optimp.lb = [];
optimp.ub = [];
optimp.nonlcon = [];
optimp.solver = optin.slvrl;
optimp.options = optiml;




%% assign to struct


s = whos;
par_defaults = cell2struct({s.name}.',{s.name});
par_defaults = rmfield(par_defaults, 'optin');
eval(structvars(par_defaults,0).');
par_defaults = orderfields(par_defaults);

for ofi = 1:length(optin) %for struct index in optin
    optout(ofi) = param_struct_recurse(optin(ofi), par_defaults);
    optout(ofi) = orderfields(optout(ofi));
end


end

function optout = param_struct_recurse(optin, optout)

    fn = fieldnames(optout);
    for fi = 1:length(fn)
        if isfield(optin, fn{fi})
            if isstruct(optin.(fn{fi}))
                if ~isstruct(optout.(fn{fi})) && ~isobject(optout.(fn{fi})) %optim struct can refer to object not struct 
                    error("input struct where there is no default struct")
                else
                    optout.(fn{fi}) = param_struct_recurse(optin.(fn{fi}), optout.(fn{fi}));
                end
            else
                if ~isempty(optin.(fn{fi}))
                    optout.(fn{fi}) = optin.(fn{fi}); %overwrite default with user-defined input
                end
            end
        end
    end

end



