
function opop = mfit_setup(num_samp_mdl, num_dim_indv, num_dim_indvpre, mdlname, chopt, imper, inputvar_stats, pth_fitdata_prefix)


spl = strsplit(mdlname, '_');
mdlclass = spl{1};
try
    chopt = chopt.(mdlclass);
catch
    chopt = [];
end


%% model-specific vars


supp = [];

if strcmp(mdlclass, 'svd')

    opop.mdl = @objective_svd;

    supp.num_total_model_functions = 1;
    supp.pvar = sscanf(mdlname, 'svd_%d'); %numeric suffix is pvar

elseif strcmp(mdlclass, 'fnet')

    [opop.mdl, opop.optimp, supp] = mfit_setup_fnet(mdlname, chopt, num_samp_mdl, imper, num_dim_indvpre, inputvar_stats);

elseif strcmp(mdlclass, 'tm')

    opop = mfit_setup_tm(mdlname);

end


%% copy some variables from fitin (inputs above) to supp (need to fix this, it's ugly to copy)  

supp.mdlname = mdlname;
supp.mdlclass = mdlclass;
supp.pthspre = pth_fitdata_prefix;
supp.imper = imper;
supp.num_dim_indvpre = num_dim_indvpre;
supp.num_samp_mdl = num_samp_mdl;
if strcmp(mdlclass, 'svd') || strcmp(mdlclass, 'ohe') || strcmp(mdlclass, 'ohe_svd')
    supp.num_par_total = num_dim_indv;
else
    supp.num_par_total = numel(opop.optimp.x0);
end


%% specify some nondefault optimization options (eventually, this will be moved above to be sometimes modetype dependent) 

if 1%strcmp(mdlname, 'fnet_v') || strcmp(mdlname, 'fnet_s')
    opop.max_iter_local = 999;  %will be assigned to opop.optiml.MaxIterations
    opop.max_iter_global = 3; %this will not be assigned to globalsearch object optimg; instead is used in output function for optimization problem, to stop optimization
    opop.optimg.NumTrialPoints = 1000;
    opop.optimg.NumStageOnePoints = 200;
else
    opop.max_iter_local = 5;  %will be assigned to opop.optiml.MaxIterations
    opop.max_iter_global = 10; %this will not be assigned to globalsearch object optimg; instead is used in output function for optimization problem, to stop optimization
    opop.optimg.NumTrialPoints = 2000;
    opop.optimg.NumStageOnePoints = 1000;
end

opop = default_optimization_params(opop);

opop.supp = supp; %assign this after default_optimization_params, since supp is for supplemental options that can vary (exist or not) 


% orderfields currently erroring when called here, not super important though opop = orderfields_recursive(opop);


end