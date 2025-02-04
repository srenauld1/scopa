
function op = mfit_setup(num_samp_mdl, num_dim_indv, num_dim_indvp, opts, imrate, inputvar_stats, pth_fitdata_prefix)


mdlname = opts.mdlname;
spl = strsplit(mdlname, '_');
mdlclass = spl{1};


%% model-specific vars


supp = [];

if strcmp(mdlclass, 'svd')

    op.mdl = @objective_svd;

    opptmp = [];
    supp.num_total_model_functions = 1;
    supp.pvar = sscanf(mdlname, 'svd_%d'); %numeric suffix is pvar

elseif strcmp(mdlclass, 'fnet')

    [op.mdl, opptmp, supp] = mfit_setup_fnet(mdlname, num_samp_mdl, imrate, num_dim_indvp, inputvar_stats);

elseif strcmp(mdlclass, 'tm')

    op = mfit_setup_tm(mdlname);

end


%% copy some variables from fitin (inputs above) to supp (need to fix this, it's ugly to copy)  

supp.mdlname = mdlname;
supp.mdlclass = mdlclass;
supp.pthspre = pth_fitdata_prefix;
supp.imrate = imrate;
supp.sampper = 1/imrate;
supp.num_dim_indvp = num_dim_indvp;
supp.num_samp_mdl = num_samp_mdl;
if strcmp(mdlclass, 'svd') || strcmp(mdlclass, 'ohe') || strcmp(mdlclass, 'ohe_svd')
    supp.num_par_total = num_dim_indv;
else
    supp.num_par_total = numel(opptmp.x0);
end


%% create globalsearch object and object for optimization problem

op.max_iter_global = opts.max_iter_global;


fng = fieldnames(opts.opg);
tmpopts = cell(numel(fng),1);
for k = 1:numel(fng)
    tmpopts{2*k-1} = fng{k};
    tmpopts{2*k} = opts.opg.(fng{k});
end
op.opg = GlobalSearch(tmpopts{:});


op.opp = createOptimProblem(opts.slvrl, options=opts.opl);
fn = fieldnames(op.opp);
for k = 1:numel(fn)
    if isfield(opptmp, fn{k})
        op.opp.(fn{k}) = opptmp.(fn{k});
    end
end

% op.opp.options = optimoptions(op.opp.options, ...
%     "EnableFeasibilityMode",true,...
%     "SubproblemAlgorithm","cg" ...
%     );


% op.opp.objective = []; %this can be same as mdl, or may be loss given output of mdl
% op.opp.x0 = [];
% op.opp.Aineq = [];
% op.opp.bineq = [];
% op.opp.Aeq = [];
% op.opp.beq = [];
% op.opp.lb = [];
% op.opp.ub = [];
% op.opp.nonlcon = [];
% op.opp.solver = d.mdl.slvrl;
% op.opp.options = opl;


op.supp = supp; %assign this after default_optimization_params, since supp is for supplemental options that can vary (exist or not) 

op = structsort(op, vectype='row'); %recursively order alphabetically



end