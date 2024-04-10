
function [fitin, opts] = setup_model(fitin, opts, dtmni, pth_fitdata_prefix)


num_samp_model = fitin.num_samp_model;
num_dim_indvaug = fitin.num_dim_indvaug;
num_dim_indv_pre = fitin.num_dim_indv_pre;

modeltype = opts.modeltype;

spl = strsplit(modeltype, '_');
try
    chopt = opts.chopt.(spl{1});
catch
    chopt = [];
end


%% model-specific vars


if startsWith(modeltype, 'svd')

    optimp.modfun = @fit_svd;

    supp.num_model_functions = 1;


elseif startsWith(modeltype, 'linear')

    optimp.modfun = @(bv,x,supp,pthspre) bv(1) * x + bv(2);
    optimp.lb = [-inf,-3000]; %[0,0,0,-pi]; %a, c, k, u
    optimp.ub = [inf,3000]; %[inf,inf,inf,pi];
    optimp.x0 = [0,0];

    supp.NumTrialPoints = 1000;
    supp.NumStageOnePoints = 200;


elseif startsWith(modeltype, 'plane')

    optimp.modfun = @fit_plane;
    optimp.lb = [ones(1, num_dim_indvaug)*3000 -inf]; %[0,0,0,-pi]; %a, c, k, u
    optimp.ub = [ones(1, num_dim_indvaug)*3000 inf]; %[inf,inf,inf,pi];
    optimp.x0 = [ones(1, num_dim_indvaug)*2 0];

    supp = [];


elseif startsWith(modeltype, 'genlog')

    optimp.modfun = @(bv,x,supp,pthspre) bv(1) + ( (bv(2) - bv(1)) ./ ( bv(3) + bv(4) * exp( -bv(5) * (x-bv(6)) ) .^ 1/bv(7) ) );
    optimp.lb = -inf(1,7); %[0,0,0,-pi]; %a, c, k, u
    optimp.ub = inf(1,7); %[inf,inf,inf,pi];
    optimp.x0 = ones(1,7);

    supp = [];

elseif startsWith(modeltype, 'vonmises')

    optimp.modfun = @objfcn_vonmises;
    optimp.lb = [-inf,-inf,-inf,-inf];
    optimp.ub = [inf,inf,inf,inf];
    optimp.x0 = [0,0,0,0];

    supp.num_total_model_functions = 1;
    supp.max_num_fun_per_neuron = 1;
    supp.NumTrialPoints = 1000;
    supp.NumStageOnePoints = 200;


elseif startsWith(modeltype, 'gaussian')

    optimp.modfun = @(bv,x,supp,pthspre) bv(1)*exp(-(((x-bv(2)).^2)/(2*bv(3).^2)))+bv(4);
    optimp.lb = [0,-5,0,0];
    optimp.ub = [3000,5,10,3000];
    optimp.x0 = [1,1,1,0];

    supp = [];


elseif startsWith(modeltype, 'ann')

    supp = setup_model_ann(modeltype, chopt, num_samp_model, dtmni, num_dim_indv_pre);


elseif startsWith(modeltype, 'tm')

    supp = setup_model_tm(modeltype);

end


%% plotting vars

fitin.plt = setup_model_plotting(modeltype, opts.plt);

%% optimization options 

fitin.opop.optimp = optimp;
fitin.opop.max_iter_local = 1001;  %will be assigned to fitin.opop.optiml.MaxIterations
fitin.opop.max_iter_global = 4; %this will not be assigned to globalsearch object; instead is used in output function for optimization problem, to stop optimization 
fitin.opop.optimg.NumTrialPoints = 2000;
fitin.opop.optimg.NumStageOnePoints = 1000; 

fitin.opop = default_optimization_options(fitin.opop);

%% copy some variables from fitin to supp (need to fix this, it's ugly)  

supp.pthspre = pth_fitdata_prefix;
supp.dt = dtmni;
supp.num_dim_indv_pre = num_dim_indv_pre;
supp.num_samp_model = num_samp_model;
if strcmp(modeltype, 'svd') || strcmp(modeltype, 'onehot') || strcmp(modeltype, 'onehot_svd')
    supp.num_par_total = num_dim_indvaug;
else
    supp.num_par_total = numel(optimp.x0);
end

fitin.supp = supp;

fitin = orderfields(fitin);

end