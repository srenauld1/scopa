function [objfcn, lbnd, ubnd, linineq_A, linineq_b, nlcon, x0, supp, gethue, gethr_native] = ...
    fit_glno(modeltype, indv, depv, num_samp_model, dt, num_dim_indvin, huestr)

supp.NumTrialPoints = 1000;
supp.NumStageOnePoints = 200;
supp.lf2 = @linear_filter_1d_2;

T = dt*(num_samp_model-1);
t = 0:dt:T; %zero-indexed time for filter

padlen_sec = 4;
padlen = round(padlen_sec/dt);
tmppad = zeros(1, length(t)+padlen*2);
tnew = 0:length(tmppad)-1;
filtnorm = 1;

objfcn = @fit_ann;

% LNs with constraints on horizontal asymptotes of sigmoid (while constraining slope to be positive always)

%excitatory (positive slope sigmoid) as opposed to inhibitory (negative slope sigmoid), or none
%integrating (monophasic linear filter) as opposed to differentiating (biphasic linear filter), freeform optimizes weights directly rather than parametric linear filter
if strcmp(modeltype, 'glno3')
    linfilt_types_per_indv_dim = {'integrating'};
    nonlinearity_types_per_indv_dim = {'none'};
elseif strcmp(modeltype, 'glno4')
    linfilt_types_per_indv_dim = {'integrating', 'differentiating'};
    nonlinearity_types_per_indv_dim = {'none'};
elseif strcmp(modeltype, 'glno5')
    linfilt_types_per_indv_dim = {'integrating', 'differentiating'};
    nonlinearity_types_per_indv_dim = {'excitatory'};
elseif strcmp(modeltype, 'glno6')
    linfilt_types_per_indv_dim = {'integrating'};
    nonlinearity_types_per_indv_dim = {'excitatory', 'inhibitory'};
elseif strcmp(modeltype, 'glno7')
    linfilt_types_per_indv_dim = {'integrating', 'differentiating'};
    nonlinearity_types_per_indv_dim = {'excitatory', 'inhibitory'};
end


%%

if strcmp(nonlinearity_types_per_indv_dim, 'none')
    num_model_functions_per_indvdim = 1;
else
    num_model_functions_per_indvdim = 2;
end

LN_specs_per_indv_dim = combinations(nonlinearity_types_per_indv_dim, linfilt_types_per_indv_dim);

num_LN_per_indvdim = size(LN_specs_per_indv_dim, 1);
num_LN_total = num_LN_per_indvdim*num_dim_indvin;
minindv = min(indv(:));
maxindv = max(indv(:));


%% define all possible params for single LN (some will not be used, depending on LN type)

% 3-element vectors below are [lowerbound, upperbound, startpoint]

tau1 = [dt/2, 0.3, dt]; %this is in domain of time, don't tranform into samples since filter is implemented in time not samples
filtshift_sec = [0, 1, 0.01];   %linear interpolation time shift
filtshift = filtshift_sec/dt;   %but do transform this variable into samples, that's how the interp shift is implemented
filtbias = [0, max(depv(:)), 0.01]; %"y intercept", "bias", added to linear filter output 
% differentiating_old filter params, now trying derivative of monophasic
% tau2 = [0.1, 2, 0.5]; %fraction by which tau2 is larger than tau1 (better behaved)
% tc = [0, 1, 0.1]; %L1 norm of tau2 filter, redundant with filtnorm somewhat, so make filtnorm constant
% filtnorm = [-inf, inf, 1]; %L1 norm of whole filter (tau1 filter minus tau2 filter, assuming latter is not norm zero )

sigmoid_slope = [0.1, inf, 1];  %force positive, letting left/right asymptotes determine sign without redundancy from slope (no constraint that left must be greater than right)
sigmoid_asympleft = [-max(depv(:))*2, max(depv(:))*2, min(depv(:))];
sigmoid_asympright = [-max(depv(:))*2, max(depv(:))*2, max(depv(:))];
sigmoid_inflection = [0, inf, 1]; %must be positive
sigmoid_xshift = [minindv, maxindv, mean([minindv maxindv])];  %since filtnorm is forced to be 1, filter output will be on order of indv

%%


lbnd = [];
ubnd = [];
x0 = [];
linineq_min_difference = 0; %zero allows equality, could try -2*options.ConstraintTolerance instead of zero (why -2, why not just -options.ConstraintTolerance?)
LN_ind_total = 0;
num_par_running_total = 0;
for jj = 1:num_dim_indvin
    for ii = 1:num_LN_per_indvdim

        LN_ind_total = LN_ind_total + 1;

        if strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'integrating') %makes monophasic filter, 2 params
            lbnd_lin = [tau1(1), filtshift(1), filtbias(1)];
            ubnd_lin = [tau1(2), filtshift(2), filtbias(2)];
            x0_lin = [tau1(3), filtshift(3), filtbias(3)];
        elseif strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'differentiating') %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
            lbnd_lin = [tau1(1), filtshift(1), filtbias(1)];
            ubnd_lin = [tau1(2), filtshift(2), filtbias(2)];
            x0_lin = [tau1(3), filtshift(3), filtbias(3)];
        elseif strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'differentiating_old') %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
            lbnd_lin = [tau1(1), filtshift(1), tau2(1), tc(1)];
            ubnd_lin = [tau1(2), filtshift(2), tau2(2), tc(2)];
            x0_lin = [tau1(3), filtshift(3), tau2(3), tc(3)];
        elseif strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'freeform') %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
            lbnd_lin = -inf(1, num_samp_model);
            ubnd_lin = inf(1, num_samp_model);
            x0_lin = rand(1, num_samp_model);
            x0_lin = x0_lin / norm(vec(x0_lin(:)),1); %L1 norm=1
        end

        if strcmp(LN_specs_per_indv_dim.nonlinearity_types_per_indv_dim{ii}, 'none')
            lbnd_nonlin = [];
            ubnd_nonlin = [];
            x0_nonlin = [];
        else
            lbnd_nonlin = [sigmoid_slope(1), sigmoid_asympleft(1), sigmoid_asympright(1), sigmoid_inflection(1), sigmoid_xshift(1)];
            ubnd_nonlin = [sigmoid_slope(2), sigmoid_asympleft(2), sigmoid_asympright(2), sigmoid_inflection(2), sigmoid_xshift(2)];
            x0_nonlin = [sigmoid_slope(3), sigmoid_asympleft(3), sigmoid_asympright(3), sigmoid_inflection(3), sigmoid_xshift(3)];
        end

        num_par_this_LN = length(lbnd_lin)+length(lbnd_nonlin);
        parind_this_LN = [1:num_par_this_LN] + num_par_running_total;
        num_par_running_total = num_par_running_total + num_par_this_LN;
        pind{jj,ii}.L = parind_this_LN(1:length(lbnd_lin));
        pind{jj,ii}.N = parind_this_LN(length(lbnd_lin)+1:end);
        if strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'freeform')
            pind{jj,ii}.Lfree = parind_this_LN(1:length(lbnd_lin));
        end

        linineq_A_tmp = zeros(1, num_par_this_LN);
        if  strcmp(LN_specs_per_indv_dim.nonlinearity_types_per_indv_dim{ii}, 'excitatory')  %left asymptote <= right asymptote will make positive slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
            linineq_A_tmp(length(lbnd_lin)+2) = 1;
            linineq_A_tmp(length(lbnd_lin)+3) = -1;
        elseif strcmp(LN_specs_per_indv_dim.nonlinearity_types_per_indv_dim{ii}, 'inhibitory')  %right asymptote <= left asymptote will make negative slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
            linineq_A_tmp(length(lbnd_lin)+2) = -1;
            linineq_A_tmp(length(lbnd_lin)+3) = 1;
        end

        lbnd = [lbnd lbnd_lin lbnd_nonlin];
        ubnd = [ubnd ubnd_lin ubnd_nonlin];
        x0 = [x0 x0_lin x0_nonlin];
        linineq_A(LN_ind_total, parind_this_LN) = linineq_A_tmp;
        linineq_b(LN_ind_total) = 0 + linineq_min_difference;

    end
end

if all(linineq_A(:)==0) %if all zeros, then linineq_A_tmp above remained zero because nonlinearity_types_per_indv_dim='none' for all LN units, so set to empty rather than zero
    linineq_A = [];
    linineq_b = [];
end

if strcmp(LN_specs_per_indv_dim.linfilt_types_per_indv_dim{ii}, 'freeform')
    nlcon = @nlcon_l1norm;
else
    nlcon = [];
end

    function [c,ceq] = nlcon_l1norm(x)

        for i = 1:numel(pind)
            ceq(i) = norm(vec(x(pind{i}.Lfree)),1) - 1; %make L1 norm = 1
        end
        c = [];

    end

supp.num_LN_per_indvdim = num_LN_per_indvdim;
supp.num_LN_total = num_LN_total;
supp.LN_specs_per_indv_dim = LN_specs_per_indv_dim;
supp.pind = pind;
supp.num_model_functions_per_indvdim = num_model_functions_per_indvdim;
supp.num_total_model_functions = num_LN_total*supp.num_model_functions_per_indvdim;


%% make sure doubles

lbnd = double(lbnd);
ubnd = double(ubnd);
x0 = double(x0);
linineq_A = double(linineq_A);
linineq_b = double(linineq_b);

%% params for plots

switch huestr
    case 'loc'
        gethue = @(ft, st, pr) st(find(max(pr) == pr, 1)); %value of indv at max predicted depv; doing this instead of just ft(3) because ft(3) is preferred head direction when ft(1)*ft(2) is positive, but null head direction when negative, and mse is worse with bounds that force nonnegative
        gethr_native = @(ft,st,rs) [0 2*pi];
    case 'wid'
        gethue = @(ft, st, pr) 2 * abs( acos( 1/ft(2) * log( 1/2 *( exp(ft(2)) + exp(-ft(2)) ))));
        gethr_native = @(ft,st,rs) [0 2*pi];
    case 'amp'
        gethue = @(ft, st, pr) ft(1) * ( exp(ft(2)) - exp(-ft(2)) );
        gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
end



    function filt = linear_filter_1d_2(flagdiff, doplots, tau1, shift)


        tmp = t./tau1^2.*exp(-t./tau1); %t = t-shift does not work for this, so using interp below for shift
        if flagdiff
            tmp = [0 diff(tmp)];
        end

        if doplots
            tmpplot = tmp / norm(tmp(:),1) * filtnorm; %normalize by L1
            hfg = figure; hax = axes('Parent', hfg); plot(hax, t, tmpplot); hold on;
        end

        tmppad(:) = 0;
        tmppad(padlen+1:end-padlen) = tmp;
        tmppad = spline(tnew+shift,tmppad,tnew);
        filt = tmppad(padlen+1:end-padlen);
        filt = filt / norm(filt(:),1) * filtnorm; %normalize by L1

        if doplots
            plot(hax, t, filt);
            close(hfg)
        end

    end
end
