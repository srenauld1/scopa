
function opop = fitmdl_setup(num_samp_mdl, num_dim_indv, num_dim_indvpre, mdlname, chopt, dtmni, inputvar_stats, pth_fitdata_prefix)


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

    supp.num_model_functions = 1;
    supp.pvar = sscanf(mdlname, 'svd_%d'); %numeric suffix is pvar

elseif strcmp(mdlclass, 'l')

    opop.mdl = @(bv,x,supp,pthspre) bv(1) + ( (bv(2) - bv(1)) ./ ( bv(3) + bv(4) * exp( -bv(5) * (x-bv(6)) ) .^ 1/bv(7) ) );
    opop.optimp.lb = -inf(1,7); %[0,0,0,-pi]; %a, c, k, u
    opop.optimp.ub = inf(1,7); %[inf,inf,inf,pi];
    opop.optimp.x0 = ones(1,7);

elseif strcmp(mdlclass, 'v')

    opop.mdl = @mdl_vonmises;
    opop.optimp.lb = [-inf,-inf,-inf,-inf];
    opop.optimp.ub = [inf,inf,inf,inf];
    opop.optimp.x0 = [0,0,0,0];

    supp.num_total_model_functions = 1;
    supp.max_num_fun_per_unit = 1;

elseif strcmp(mdlclass, 'g')

    opop.mdl = @(bv,x,supp,pthspre) bv(1)*exp(-(((x-bv(2)).^2)/(2*bv(3).^2)))+bv(4);
    opop.optimp.lb = [0,-5,0,0];
    opop.optimp.ub = [3000,5,10,3000];
    opop.optimp.x0 = [1,1,1,0];

elseif strcmp(mdlclass, 'fnet')

    [opop.mdl, opop.optimp, supp] = fitmdl_setup_fnet(mdlname, chopt, num_samp_mdl, dtmni, num_dim_indvpre, inputvar_stats);

elseif strcmp(mdlclass, 'tm')

    opop = fitmdl_setup_tm(mdlname);

end


%% copy some variables from fitin (inputs above) to supp (need to fix this, it's ugly to copy)  

supp.mdlname = mdlname;
supp.mdlclass = mdlclass;
supp.pthspre = pth_fitdata_prefix;
supp.dtmni = dtmni;
supp.num_dim_indvpre = num_dim_indvpre;
supp.num_samp_mdl = num_samp_mdl;
if strcmp(mdlclass, 'svd') || strcmp(mdlclass, 'ohe') || strcmp(mdlclass, 'ohe_svd')
    supp.num_par_total = num_dim_indv;
else
    supp.num_par_total = numel(opop.optimp.x0);
end


%% specify some nondefault optimization options (eventually, this will be moved above to be sometimes modetype dependent) 

opop.max_iter_local = 1001;  %will be assigned to opop.optiml.MaxIterations
opop.max_iter_global = 4; %this will not be assigned to globalsearch object optimg; instead is used in output function for optimization problem, to stop optimization 
opop.optimg.NumTrialPoints = 2000;
opop.optimg.NumStageOnePoints = 1000; 

opop = default_optimization_params(opop);

opop.supp = supp; %assign this after default_optimization_params, since supp is for supplemental options that can vary (exist or not) 


opop = orderfields_recursive(opop);


end