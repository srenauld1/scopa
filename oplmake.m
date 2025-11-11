function [slvr, opt] = oplmake(slvr, opt, opt2)

%{

this function just exists for symmetry with other a2p modules
it just shows/outputs default options for a2p module 'opl', which are default local solver options output by optimoptions('fmincon')
opt2.runtype is unecessary, but just included for symmetry with other a2p modules
for symmetry with other modules, opt must be second output, so first is arbitrarily slvr

%}

arguments

    slvr {mustBeTextScalar} = '' %local solver; default 'fmincon' is set below if empty

    opt.Algorithm = 'interior-point'; %algorithm chosen automatically?? . . . was using 'Algorithm', 'interior-point'); % https://www.mathworks.com/help/optim/ug/choosing-the-algorithm.html
    opt.BarrierParamUpdate = 'monotone';
    opt.ConstraintTolerance = 1.0000e-06;
    opt.Display = 'final'; %'final'; %try iter-detailed
    opt.EnableFeasibilityMode = false;
    opt.FiniteDifferenceStepSize = 'sqrt(eps)';
    opt.FiniteDifferenceType = 'forward'; %try 'central' for precision
    opt.FunctionTolerance = 1.0000e-06; %Termination tolerance on the function value; for some reason this does not appear in options output by optimoptions('fmincon') but does appear in fieldnames(optimoptions('fmincon')), and is listed as fmincon option in docs, so keeping it here
    opt.HessianApproximation = 'bfgs';
    opt.HessianFcn = [];
    opt.HessianMultiplyFcn = [];
    opt.HonorBounds = 1;
    opt.MaxFunctionEvaluations = 3000; %3000 for interior-point, 100*numvariables for others, can be inf
    opt.MaxIterations = 1000; %1000 for interior-point, 400 for others; can try 10000
    opt.ObjectiveLimit = -1.0000e+20;
    opt.OptimalityTolerance = 1.0000e-06;
    opt.OutputFcn = [];
    opt.PlotFcn = [];
    opt.ScaleProblem = false; %false
    opt.SpecifyConstraintGradient = 0;
    opt.SpecifyObjectiveGradient = 0;
    opt.StepTolerance = 1.0000e-10; %set to zero, along with OptimalityTolerance, to force fminncon to run specified number of iterations in MaxIterations
    opt.SubproblemAlgorithm = 'factorization';
    opt.TypicalX = 'ones(numberOfVariables,1)';
    opt.UseParallel = 0;

    opt2.runtype (1,1) {mustBeBinary} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments and return arguments block struct opt (not any other input arguments, since only opt is under id-control) 

end

if isempty(slvr)
    slvr = 'fmincon';
end
objecttmp = optimoptions(slvr);
fntmp = fieldnames(objecttmp); %do it this way because optimoptions a outputs an object, not struct (and needs to be struct for oset/ofill/etc to work), and there are superfluous options that get converted if we just run struct(optimoptions(slvr))
for m = 1:numel(fntmp)
    opttmp.(fntmp{m}) = objecttmp.(fntmp{m});
end

if ~isequal(opt, opttmp)
    error("defaults in arguments block do not match defaults output by optimoptions")
end

if opt2.runtype %for oplmake, runtype is pointless, since oplmake is just for validating/returning options
    return
end
