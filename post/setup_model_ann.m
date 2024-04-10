function [opop, supp] = setup_model_ann(modeltype, chopt, num_samp_model, dt, num_dim_indv_pre)

supp.modeltype = modeltype;
supp.NumTrialPoints = 1000;
supp.NumStageOnePoints = 200;

padlen_sec = 4;

annspec = parse_model_string(modeltype, chopt, num_dim_indv_pre);

lbnd = [];
ubnd = [];
x0 = [];
linineq_A = [];
rwprev = 0;
clprev = 0;
linineq_b = [];

supp.num_neuron_total = 0;
supp.num_total_model_functions = 0;
supp.max_num_fun_per_neuron = 0;
pindmax_prev = 0;

%loop over ann positions (layers and channels), accumulating param starting point (x0) and optional constraints
fnl = fieldnames(annspec);
for li = 1:length(fnl)
    fnc = fieldnames(annspec.(fnl{li}));
    for ci = 1:length(fnc)

        [lbnd_tmp, ubnd_tmp, linineq_A_tmp, linineq_b_tmp, x0_tmp, anntmp, freeformflag] = ...
            setup_model_ann_oneposition(annspec.(fnl{li}).(fnc{ci}), num_samp_model, dt, num_dim_indv_pre, padlen_sec);

        lbnd = [lbnd lbnd_tmp];
        ubnd = [ubnd ubnd_tmp];
        x0 = [x0 x0_tmp];
        rwindsnew = rwprev+1:rwprev+1+size(linineq_A_tmp, 1)-1;
        clindsnew = clprev+1:clprev+1+size(linineq_A_tmp, 2)-1;
        linineq_A(rwindsnew, clindsnew) = linineq_A_tmp;
        rwprev = size(linineq_A, 1);
        clprev = size(linineq_A, 2);
        linineq_b = [linineq_b linineq_b_tmp];

        for ni2 = 1:anntmp.num_neuron
            anntmp.pind(ni2) = structfun(@(x) x+pindmax_prev, anntmp.pind(ni2), 'UniformOutput', false); %max param index for single position (layer+channel)
        end
        for ni2 = 1:anntmp.num_neuron
            tmpcl = cellfun(@max, struct2cell(anntmp.pind(ni2)), 'UniformOutput', false);
            tmpcl = tmpcl(~cellfun(@isempty, tmpcl));
            pindmax_prev = max(vertcat(pindmax_prev, vec(cell2mat(tmpcl)))); %max param index for single position (layer+channel)
        end

        supp.ann.(fnl{li}).(fnc{ci}) = anntmp;
        supp.num_neuron_total = supp.num_neuron_total + size(anntmp.annspec, 1);
        supp.num_total_model_functions = supp.num_total_model_functions + anntmp.max_num_fun_per_neuron;
        supp.max_num_fun_per_neuron = max(supp.max_num_fun_per_neuron, anntmp.max_num_fun_per_neuron);

    end
end


if all(linineq_A(:)==0) %if all zeros, then linineq_A_tmp above remained zero because stract='none' for all LN units, so set to empty rather than zero
    linineq_A = [];
    linineq_b = [];
end

opop.objective = @fit_ann;
opop.lb = double(lbnd);
opop.ub = double(ubnd);
opop.x0 = double(x0);
opop.Aineq = double(linineq_A);
opop.bineq = double(linineq_b);


if any(freeformflag) %set up nonlinear constraint for freeform linear function

    opop.nonlcon = @nlcon_l1norm;

    %simplify nested function nlcon by giving it a simpler param index array (pind_Lfree, created here) than what is saved in supp.ann.pind (but keep that for use in fit_ann)
    count = 0;
    fnl = fieldnames(supp.ann);
    for li = 1:length(fnl)
        fnc = fieldnames(supp.ann.(fnl{li}));
        for ci = 1:length(fnc)
            for ni = 1:length(supp.ann.(fnl{li}).(fnc{ci}).pind)
                count = count+1;
                pind_Lfree{count} = supp.ann.(fnl{li}).(fnc{ci}).pind(ni).L; %make L1 norm = 1 for linear filters with 'freeform' flag
            end
        end
    end


else
    opop.nonlcon = [];
end



    function [c,ceq] = nlcon_l1norm(x)

        for i = 1:length(pind_Lfree)
            ceq(i) = norm(vec(x(pind_Lfree{i})),1) - 1; %make L1 norm = 1 for linear filters with 'freeform' flag
        end
        c = [];

    end


end

