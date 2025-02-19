function [mdl, opp, supp] = mdl_optimpr_fnet(mdlname, num_samp_mdl, imrate, num_dim_indvp, inputvar_stats)

padlen_sec = 4;

multi_time_in_layer_one_only = 1;

fnetspec = mdl_parse_mdlname_string(mdlname, num_dim_indvp, num_samp_mdl, multi_time_in_layer_one_only);
all_layers_ordered = char(('A':'Z').').'; %alphabet, capitals, to ensure layerindex order is corect

lbnd = [];
ubnd = [];
x0 = [];
linineq_A = [];
rwprev = 0;
clprev = 0;
linineq_b = [];

supp.num_unit_total = size(fnetspec, 1);

supp.num_total_model_functions = 0; %initialize with 0
supp.max_num_fun_per_unit = 0; %initialize with 0
pindmax_prev = 0;
freeformflag = 0;

for k = 1:size(fnetspec, 1) %loop over all fnet units, accumulating param starting points (x0) and optional constraints

    [lbnd_tmp, ubnd_tmp, linineq_A_tmp, linineq_b_tmp, x0_tmp, fnettmp, freeformflagtmp] = ...
        mdl_optimpr_fnet_oneunit(fnetspec(k,:), num_samp_mdl, imrate, num_dim_indvp, padlen_sec, inputvar_stats, multi_time_in_layer_one_only);

    lbnd = [lbnd lbnd_tmp];
    ubnd = [ubnd ubnd_tmp];
    x0 = [x0 x0_tmp];
    rwindsnew = rwprev+1:rwprev+1+size(linineq_A_tmp, 1)-1;
    clindsnew = clprev+1:clprev+1+size(linineq_A_tmp, 2)-1;
    linineq_A(rwindsnew, clindsnew) = linineq_A_tmp;
    rwprev = size(linineq_A, 1);
    clprev = size(linineq_A, 2);
    linineq_b = [linineq_b linineq_b_tmp];

    fnettmp.pind = cellfun(@(x) x+pindmax_prev, fnettmp.pind, 'UniformOutput', false); %max param index for single position (layer+channel)
    tmpcl = cellfun(@max, fnettmp.pind, 'UniformOutput', false);
    tmpcl = tmpcl(~cellfun(@isempty, tmpcl));
    pindmax_prev = max(vertcat(pindmax_prev, vec(cell2mat(tmpcl)))); %max param index for single position (layer+channel)

    fnettmp.layer_in = cell2mat(fnetspec(k,:).layer_in);
    [~, layer_in_index] = regexp(all_layers_ordered, fnetspec(k,:).layer_in, 'match');
    fnettmp.layer_in_index = cell2mat(layer_in_index);
    fnettmp.channel_in = cell2mat(fnetspec(k,:).channel_in);
    [~, layer_out_index] = regexp(all_layers_ordered, fnetspec(k,:).layer_out, 'match');
    fnettmp.layer_out = cell2mat(fnetspec(k,:).layer_out);
    fnettmp.layer_out_index = cell2mat(layer_out_index);
    fnettmp.channel_out = cell2mat(fnetspec(k,:).channel_out);
    supp.fnet(k,:) = fnettmp; %make it first dim, even though only dim
    supp.num_total_model_functions = supp.num_total_model_functions + fnettmp.max_num_fun_per_unit;
    supp.max_num_fun_per_unit = max(supp.max_num_fun_per_unit, fnettmp.max_num_fun_per_unit);

    if freeformflagtmp && ~freeformflag
        freeformflag = 1;
    end

end


if all(linineq_A(:)==0) %if all zeros, then linineq_A_tmp above remained zero because stract='none' for all LN units, so set to empty rather than zero
    linineq_A = [];
    linineq_b = [];
end

supp.mdlname = mdlname;

mdl = @mdl_fnet;

opp.lb = double(lbnd);
opp.ub = double(ubnd);
opp.x0 = double(x0);
opp.Aineq = double(linineq_A);
opp.bineq = double(linineq_b);


opp.nonlcon = [];

allpind = [supp.fnet.pind];
supp.pind_Lfree = allpind(strcmp([supp.fnet.funstr], 'f'));

allpind = [supp.fnet.pind];
supp.pind_vonmises = allpind(strcmp([supp.fnet.funstr], 'v'));

%
% if ~freeformflag %set up nonlinear constraint for freeform linear function
% 
%     opp.nonlcon = [];
% 
% else
% 
%     allpind = [supp.fnet.pind];
%     supp.pind_Lfree = allpind(strcmp([supp.fnet.funstr], 'f'));
% 
% this von mises constraint would only be called for freeformflag and that's wrong
%     allpind = [supp.fnet.pind];
%     supp.pind_vonmises = allpind(strcmp([supp.fnet.funstr], 'v'));
% 
%     % opp.nonlcon = @nlcon_fnet;
% 
% end

    % 
    % function [c,ceq] = nlcon_fnet(x)
    %     %the two vonmises constraint are not great because they forces the curve max and min to match data max and min but data is noisy, so the curve won't fit optimally, would be better to match max and min of some filtered version of data, or just skip the constraint 
    % 
    %     countz = 0;
    %     for j = 1:length(pind_Lfree)
    %         countz = countz+1;
    %         ceq(countz) = norm(vec(x(pind_Lfree{j})),1) - 1; %make L1norm = 1 for linear filters with 'freeform' flag
    %     end
    %     for j = 1:length(pind_vonmises) %this constraint is not great because it forces the curve max and min to match data max and min but data is noisy, would be better to match max and min of some filtered version of data, or just skip the constraint 
    %         countz = countz+1;
    %         ceq(countz) = min(vec(x(pind_vonmises{j})),1) - inputvar_stats.depvp_min_alldim; %max and min match data max and min (not controllable as params of von mises)
    %     end
    %     for j = 1:length(pind_vonmises)
    %         countz = countz+1;
    %         ceq(countz) = max(vec(x(pind_vonmises{j})),1) - inputvar_stats.depvp_max_alldim; %max and min match data max and min (not controllable as params of von mises)
    %     end
    %     c = [];
    % 
    % end


end

