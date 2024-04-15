function [mdl, optimp, supp] = fitmdl_setup_fnet(modeltype, chopt, num_samp_mdl, dtmni, num_dim_indvpre, inputvar_stats)

padlen_sec = 4;

fnetspec = fitmdl_parse_modeltype_string(modeltype, chopt, num_dim_indvpre);

lbnd = [];
ubnd = [];
x0 = [];
linineq_A = [];
rwprev = 0;
clprev = 0;
linineq_b = [];

supp.num_neuron_total = 0; %initialize with 0
supp.num_total_model_functions = 0;%initialize with 0
supp.max_num_fun_per_neuron = 0;%initialize with 0
pindmax_prev = 0;

%loop over fnet positions (layers and channels), accumulating param starting point (x0) and optional constraints
fnl = fieldnames(fnetspec);
for li = 1:length(fnl)
    fnc = fieldnames(fnetspec.(fnl{li}));
    for ci = 1:length(fnc)

        [lbnd_tmp, ubnd_tmp, linineq_A_tmp, linineq_b_tmp, x0_tmp, fnettmp, freeformflag] = ...
            fitmdl_setup_fnet_oneposition(fnetspec.(fnl{li}).(fnc{ci}), num_samp_mdl, dtmni, num_dim_indvpre, padlen_sec, inputvar_stats);

        lbnd = [lbnd lbnd_tmp];
        ubnd = [ubnd ubnd_tmp];
        x0 = [x0 x0_tmp];
        rwindsnew = rwprev+1:rwprev+1+size(linineq_A_tmp, 1)-1;
        clindsnew = clprev+1:clprev+1+size(linineq_A_tmp, 2)-1;
        linineq_A(rwindsnew, clindsnew) = linineq_A_tmp;
        rwprev = size(linineq_A, 1);
        clprev = size(linineq_A, 2);
        linineq_b = [linineq_b linineq_b_tmp];

        for ni2 = 1:fnettmp.num_neuron
            fnettmp.pind(ni2) = structfun(@(x) x+pindmax_prev, fnettmp.pind(ni2), 'UniformOutput', false); %max param index for single position (layer+channel)
        end
        for ni2 = 1:fnettmp.num_neuron
            tmpcl = cellfun(@max, struct2cell(fnettmp.pind(ni2)), 'UniformOutput', false);
            tmpcl = tmpcl(~cellfun(@isempty, tmpcl));
            pindmax_prev = max(vertcat(pindmax_prev, vec(cell2mat(tmpcl)))); %max param index for single position (layer+channel)
        end

        supp.fnet.(fnl{li}).(fnc{ci}) = fnettmp;
        supp.num_neuron_total = supp.num_neuron_total + size(fnettmp.fnetspec, 1);
        supp.num_total_model_functions = supp.num_total_model_functions + fnettmp.max_num_fun_per_neuron;
        supp.max_num_fun_per_neuron = max(supp.max_num_fun_per_neuron, fnettmp.max_num_fun_per_neuron);

    end
end


if all(linineq_A(:)==0) %if all zeros, then linineq_A_tmp above remained zero because stract='none' for all LN units, so set to empty rather than zero
    linineq_A = [];
    linineq_b = [];
end

supp.modeltype = modeltype;

mdl = @mdl_fnet;

optimp.lb = double(lbnd);
optimp.ub = double(ubnd);
optimp.x0 = double(x0);
optimp.Aineq = double(linineq_A);
optimp.bineq = double(linineq_b);


if ~any(freeformflag) %set up nonlinear constraint for freeform linear function

    optimp.nonlcon = [];

else

    optimp.nonlcon = @nlcon_l1norm;

    %simplify nested function nlcon by giving it a simpler param index array (pind_Lfree, created here) than what is saved in supp.fnet.pind (but keep that for use in mdl_fnet)
    count = 0;
    fnl = fieldnames(supp.fnet);
    for li = 1:length(fnl)
        fnc = fieldnames(supp.fnet.(fnl{li}));
        for ci = 1:length(fnc)
            for ni = 1:length(supp.fnet.(fnl{li}).(fnc{ci}).pind)
                count = count+1;
                pind_Lfree{count} = supp.fnet.(fnl{li}).(fnc{ci}).pind(ni).L; %make L1 norm = 1 for linear filters with 'freeform' flag
            end
        end
    end

end


    function [c,ceq] = nlcon_l1norm(x)

        for i = 1:length(pind_Lfree)
            ceq(i) = norm(vec(x(pind_Lfree{i})),1) - 1; %make L1 norm = 1 for linear filters with 'freeform' flag
        end
        c = [];

    end


end

