
function [fitin, plt] = setup_model_all(fitopt, plt, indvaug, num_samp_model, ...
    num_dim_indvaug, num_dim_indvin, depvin, dtmni, pth_fitdata_prefix)


modeltype = fitopt.modeltype;
slvrl = fitopt.slvrl;

spl = strsplit(modeltype, '_');
try
    chopt = fitopt.chopt.(spl{1});
catch
    chopt = [];
end


linineq_A = [];
linineq_b = [];
nlcon = [];


%% model-specific vars


if startsWith(modeltype, 'svd')

    objfcn = @fit_svd;
    lbnd = [];
    ubnd = [];
    x0 = [];

    supp.num_model_functions = 1;


elseif startsWith(modeltype, 'linear')

    objfcn = @(bv,x,supp,pthspre) bv(1) * x + bv(2);
    lbnd = [-inf,-3000]; %[0,0,0,-pi]; %a, c, k, u
    ubnd = [inf,3000]; %[inf,inf,inf,pi];
    x0 = [0,0];

    supp.NumTrialPoints = 1000;
    supp.NumStageOnePoints = 200;


elseif startsWith(modeltype, 'plane')

    objfcn = @fit_plane;
    lbnd = [ones(1, num_dim_indvaug)*3000 -inf]; %[0,0,0,-pi]; %a, c, k, u
    ubnd = [ones(1, num_dim_indvaug)*3000 inf]; %[inf,inf,inf,pi];
    x0 = [ones(1, num_dim_indvaug)*2 0];

    supp = [];


elseif startsWith(modeltype, 'genlog')

    objfcn = @(bv,x,supp,pthspre) bv(1) + ( (bv(2) - bv(1)) ./ ( bv(3) + bv(4) * exp( -bv(5) * (x-bv(6)) ) .^ 1/bv(7) ) );
    lbnd = -inf(1,7); %[0,0,0,-pi]; %a, c, k, u
    ubnd = inf(1,7); %[inf,inf,inf,pi];
    x0 = ones(1,7);

    supp = [];

elseif startsWith(modeltype, 'vonmises')

    objfcn = @objfcn_vonmises;
    lbnd = [-inf,-inf,-inf,-inf];
    ubnd = [inf,inf,inf,inf];
    x0 = [0,0,0,0];

    supp.num_total_model_functions = 1;
    supp.max_num_fun_per_neuron = 1;
    supp.NumTrialPoints = 1000;
    supp.NumStageOnePoints = 200;


elseif startsWith(modeltype, 'gaussian')

    objfcn = @(bv,x,supp,pthspre) bv(1)*exp(-(((x-bv(2)).^2)/(2*bv(3).^2)))+bv(4);
    lbnd = [0,-5,0,0];
    ubnd = [3000,5,10,3000];
    x0 = [1,1,1,0];

    supp = [];


elseif startsWith(modeltype, 'ann')

    [objfcn, x0, lbnd, ubnd, linineq_A, linineq_b, nlcon, supp] = ...
        setup_model_ann(modeltype, chopt, indvaug, depvin, num_samp_model, dtmni, num_dim_indvin);


elseif startsWith(modeltype, 'tm')

    setup_model_tm(modeltype)

end

%% synthesize depv function

supp.synpars = @synthesize_params;


%% plotting vars

plt = setup_model_plotting(modeltype, plt);

%% output structs

supp.pthspre = pth_fitdata_prefix;
supp.dt = dtmni;
supp.num_dim_indvin = num_dim_indvin;
supp.num_samp_model = num_samp_model;
if strcmp(modeltype, 'svd') || strcmp(modeltype, 'onehot') || strcmp(modeltype, 'onehot_svd')
    supp.num_par_total = num_dim_indvaug;
else
    supp.num_par_total = numel(x0);
end

fitin.slvrl = slvrl;
fitin.objfcn = objfcn;
fitin.x0 = x0;
fitin.lbnd = lbnd;
fitin.ubnd = ubnd;
fitin.linineq_A = linineq_A;
fitin.linineq_b = linineq_b;
fitin.nlcon = nlcon;
fitin.supp = supp;

[optimg, optiml, optimp] = set_optimization_options(supp);

%%


    function ftsyn = synthesize_params()
        ubndtmp = ubnd;
        lbndtmp = lbnd;
        dummybnd = 10;
        ubndtmp(isinf(ubndtmp)&ubndtmp>0) = dummybnd; %replace inf with a (relatively) big number
        ubndtmp(isinf(ubndtmp)&ubndtmp<0) = -dummybnd; %replace -inf with a (relatively) small number
        lbndtmp(isinf(lbndtmp)&lbndtmp>0) = dummybnd; %replace inf with a (relatively) big number
        lbndtmp(isinf(lbndtmp)&lbndtmp<0) = -dummybnd; %replace -inf with a (relatively) small number
        ftsyn = lbndtmp + (ubndtmp-lbndtmp).*rand(size(x0)); %synthetic params (random, within bounds), to generate synthetic depv in case testing optimization code
    end



end