
function op = mdl_optimpr(num_samp_mdl, num_dim_indv, num_dim_indvp, num_samp_indvp, opt, imrate, inputvar_stats, pthpre)


mdlname = opt.mdlname;
spl = strsplit(mdlname, '_');
mdlclass = spl{1};


%% model-specific vars


supp = [];

if strcmp(mdlclass, 'svd')

    op.mdl = @objective_svd;

    opptmp = [];
    supp.num_total_model_functions = 1;
    if isscalar(spl)
        supp.pvar = 1;
    else
        supp.pvar = str2double(spl{2}); %numeric suffix is pvar, if it exists
    end

elseif strcmp(mdlclass, 'fnet')

    [op.mdl, opptmp, supp] = mdl_optimpr_fnet(mdlname, num_samp_mdl, num_dim_indvp, num_samp_indvp, imrate, inputvar_stats);

elseif strcmp(mdlclass, 'tm')

    op = mdl_optimpr_tm(mdlname);

end


%% copy some variables from mdl (inputs above) to supp (need to fix this, it's ugly to copy)  

supp.mdlname = mdlname;
supp.mdlclass = mdlclass;
supp.pthspre = pthpre;
supp.imrate = imrate;
supp.sper = 1/imrate;
supp.num_dim_indvp = num_dim_indvp;
supp.num_samp_mdl = num_samp_mdl;
if strcmp(mdlclass, 'svd') || strcmp(mdlclass, 'ohe') || strcmp(mdlclass, 'ohe_svd')
    supp.num_par_total = num_dim_indv;
else
    supp.num_par_total = numel(opptmp.x0);
end


%% create globalsearch object and object for optimization problem

op.max_iter_global = opt.max_iter_global;

prs = struct2pairs(opt.opg);
op.opg = GlobalSearch(prs{:});

op.opp = createOptimProblem(opt.slvrl, options=opt.opl);
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