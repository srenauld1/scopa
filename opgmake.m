function opt = opgmake(slvr, opt, opt2)

%{

this function just exists for symmetry with other a2p modules
it just shows/outputs default options for a2p module 'opl', which are default local solver options output by optimoptions('fmincon')
opt2.och is unecessary, but just included for symmetry with other a2p modules

%}

arguments

    slvr {mustBeTextScalar} = '' %global solver; gs for GlobalSearch, or ms for MultiStart

    opt.NumTrialPoints = 1000; %1000
    opt.BasinRadiusFactor = 0.2; %0.2000
    opt.DistanceThresholdFactor = 0.75; %0.7500
    opt.MaxWaitCycle = 20; %20
    opt.NumStageOnePoints = 200; %200
    opt.PenaltyThresholdFactor = 0.2; %0.2000
    opt.Display = 'final'; %'final'
    opt.FunctionTolerance = 1e-6; %1.0000e-06
    opt.MaxTime = Inf; %Inf
    opt.OutputFcn = []; %[]
    opt.PlotFcn = []; %{@gsplotbestf, @gsplotfunccount}; %[]
    opt.StartPointsToRun = 'all'; %'all', can try 'bounds-ineqs' to only start with points that obey user-defined constraints
    opt.XTolerance = 1e-6; %1.0000e-06

    opt2.och {mustBeMember(opt2.och,[0,1]), mustBeNonempty} = 0 %och means "options check"; 1 to exit function and return nothing but arguments block struct opt (not opt2 or any other name-value arguments struct); 0 to skip och (run function normally), which is default

end

switch slvr
    case {'', 'gs'} %empty or gs
        objecttmp = GlobalSearch;
    case 'ms'
        error("global solver 'ms' (MultiStart) is not supported right now")
        objecttmp = MultiStart;
    otherwise
        error("'gs' (and empty char '' or string "", which are equivalent to 'gs') is only valid slvr input for opgmake")
end
fntmp = fieldnames(objecttmp); %do it this way because GlobalSearch a outputs an object, not struct (and needs to be struct for oset/ofill/etc to work), and there are superfluous options that get converted if we just run struct(GlobalSearch)
for m = 1:numel(fntmp)
    opttmp.(fntmp{m}) = objecttmp.(fntmp{m});
end

if ~isequal(opt, opttmp)
    error("defaults in arguments block do not match defaults output by global solver")
end

if opt2.och
    if isfield(opt, 'optid')
        opt = rmfield(opt, 'optid');
    end
    opt = opt;
    return
end
