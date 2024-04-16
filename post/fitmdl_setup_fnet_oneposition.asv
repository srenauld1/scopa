
function [lbnd, ubnd, linineq_A, linineq_b, x0, fnet, freeformflag] = ...
    fitmdl_setup_fnet_oneposition(fnetspec, num_samp_mdl, dtmni, num_dim_indvpre, padlen_sec, inputvar_stats)

% in fnetspec, strlin for linear functions, stract for activation (nonlinear) functions
% strlin 's' and 'd' and 'f' make linear filters (s is monophasic; d is biphasic, formed from derivative of s; f is freeform, can take any shape)
% strlin 'l' skips linear filter stage
% stract 'e' and 'i' make generalized logistic functions (includes sigmoids), with constraints on params controlling slope and horizontal asymptotes
% forcing 'e' to be positive true slope (left horiz asymptote<right horiz asymptote with positive slope param)
% and 'i' to be negative true slope  (left horiz asymptote>right horiz asymptote with positive slope param)
% stract that starts with 'h' makes hot encoded nonlinear function (can take any shape)
% stract 'a' skips activation function stage


%% some useful stats on input variables 

depvpre_extreme_alldim = inputvar_stats.depvpre_extreme_alldim;
depvpre_mean_alldim = inputvar_stats.depvpre_mean_alldim;
depvpre_min_alldim = inputvar_stats.depvpre_min_alldim;
depvpre_max_alldim = inputvar_stats.depvpre_max_alldim;
indvpre_extreme_alldim = inputvar_stats.indvpre_extreme_alldim;
indvpre_mean_alldim = inputvar_stats.indvpre_mean_alldim;
indvpre_min_alldim = inputvar_stats.indvpre_min_alldim;
indvpre_max_alldim = inputvar_stats.indvpre_max_alldim;

%% define time domain for linear filters

tmax = dtmni*(num_samp_mdl-1);
t = 0:dtmni:tmax; %zero-indexed time for final/used filter

tlongfac = 2;
tlongmax = tmax*tlongfac;
tlong = 0:dtmni:tlongmax; %zero-indexed time for long-time domain filter (initial instantiation)

filt_padlen = round(padlen_sec/dtmni);
filt_padded = zeros(1, numel(tlong)+filt_padlen*2);
t_shifted_max = dtmni*(numel(filt_padded)-1);
t_shifted = 0:dtmni:t_shifted_max; %zero-indexed time for padded and shifted filter

con_filtnorm = 1;


%% activation function constants

C = 1; %hard coded param
Q = 1; %hard coded param

%% some useful variables for this function

max_num_fun_per_neuron = max(sum(cellfun(@any, regexp([fnetspec.strlin(:) fnetspec.stract(:)], '[^l|a]')), 2));
num_unit = size(fnetspec, 1);

%% define constraints for all possible params for each function unit (some will not be used, depending on unit type)

% prefix con_* denotes 'constraint', 3-element vectors below are [lowerbound, upperbound, startpoint]

con_filt_tau1 = [dtmni/2, 0.3, dtmni]; %filter tau, in units of seconds, don't tranform into units of samples since filter is implemented in time not samples
con_filt_tshift = [0, 0.75, 0.01];   %filter shift (ie lag, delay, rightward shift of filter) in seconds, implemented with spline interp
con_filt_bias = [-depvpre_extreme_alldim, depvpre_extreme_alldim, 0.01]; %"y intercept", "bias", added to linear filter output

% constraints for old 'd' filter function, 'linear_filter_1d_deprecated', now trying derivative of monophasic instead 
% con_tau2 = [0.1, 2, 0.5]; %fraction by which con_tau2 is larger than con_filt_tau1 (better behaved)
% con_tc = [0, 1, 0.1]; %L1 norm of con_tau2 filter, redundant with con_filtnorm somewhat, so make con_filtnorm constant
% con_filtnorm = [-inf, inf, 1]; %L1 norm of whole filter (con_filt_tau1 filter minus con_tau2 filter, assuming latter is not norm zero )

con_genlog_slope = [0.1, depvpre_extreme_alldim, 1]; %previously [0.1, inf, 1]  %force positive, letting left/right asymptotes determine sign without redundancy from slope (no constraint that left must be greater than right)
con_genlog_asympleft = [-depvpre_extreme_alldim*2, depvpre_extreme_alldim*2, depvpre_min_alldim];
con_genlog_asympright = [-depvpre_extreme_alldim*2, depvpre_extreme_alldim*2, depvpre_max_alldim];
con_genlog_inflection = [0, depvpre_extreme_alldim*2, 1]; %must be positive, previous was [0, inf, 1]
con_genlog_xshift = [-indvpre_extreme_alldim*2, indvpre_extreme_alldim*2, mean([indvpre_min_alldim indvpre_max_alldim])];  %since con_filtnorm is forced to be 1, filter output will be on order of indv

hotnonlin_weights = [-depvpre_extreme_alldim*2, depvpre_extreme_alldim*2, depvpre_mean_alldim];

%%


lbnd = [];
ubnd = [];
x0 = [];
linineq_min_difference = 0; %zero allows equality, could try -2*options.ConstraintTolerance instead of zero (why -2, why not just -options.ConstraintTolerance?)
neuron_ind_total = 0;
num_par_running_total = 0;

for ni = 1:num_unit

    neuron_ind_total = neuron_ind_total + 1;

    if strcmp(fnetspec.strlin{ni}, 'l') %skips linear filter
        lbnd_lin = [];
        ubnd_lin = [];
        x0_lin = [];
    elseif strcmp(fnetspec.strlin{ni}, 's') %makes monophasic filter, 2 params
        lbnd_lin = [con_filt_tau1(1), con_filt_tshift(1), con_filt_bias(1)];
        ubnd_lin = [con_filt_tau1(2), con_filt_tshift(2), con_filt_bias(2)];
        x0_lin = [con_filt_tau1(3), con_filt_tshift(3), con_filt_bias(3)];
    elseif strcmp(fnetspec.strlin{ni}, 'd') %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
        lbnd_lin = [con_filt_tau1(1), con_filt_tshift(1), con_filt_bias(1)];
        ubnd_lin = [con_filt_tau1(2), con_filt_tshift(2), con_filt_bias(2)];
        x0_lin = [con_filt_tau1(3), con_filt_tshift(3), con_filt_bias(3)];
    elseif strcmp(fnetspec.strlin{ni}, 'd2') %old approach for d filter, 'd2' specifier currently not supported %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
        lbnd_lin = [con_filt_tau1(1), con_filt_tshift(1), con_tau2(1), con_tc(1)];
        ubnd_lin = [con_filt_tau1(2), con_filt_tshift(2), con_tau2(2), con_tc(2)];
        x0_lin = [con_filt_tau1(3), con_filt_tshift(3), con_tau2(3), con_tc(3)];
    elseif strcmp(fnetspec.strlin{ni}, 'f') %freeform filter, can take any shape
        lbnd_lin = -inf(1, num_samp_mdl);
        ubnd_lin = inf(1, num_samp_mdl);
        x0_lin = rand(1, num_samp_mdl);
        x0_lin = x0_lin / norm(vec(x0_lin(:)),1); %L1 norm=1
    end

    fnet.actfun{ni} = [];
    if strcmp(fnetspec.stract{ni}, 'a') || strcmp(fnetspec.stract{ni}, 'y') %skip activation function
        lbnd_nonlin = [];
        ubnd_nonlin = [];
        x0_nonlin = [];
    elseif any(strcmp(fnetspec.stract{ni}, {'e', 'i'}))
        fnet.actfun{ni} = @static_genlog;
        lbnd_nonlin = [con_genlog_slope(1), con_genlog_asympleft(1), con_genlog_asympright(1), con_genlog_inflection(1), con_genlog_xshift(1)];
        ubnd_nonlin = [con_genlog_slope(2), con_genlog_asympleft(2), con_genlog_asympright(2), con_genlog_inflection(2), con_genlog_xshift(2)];
        x0_nonlin = [con_genlog_slope(3), con_genlog_asympleft(3), con_genlog_asympright(3), con_genlog_inflection(3), con_genlog_xshift(3)];
    elseif startsWith(fnetspec.stract{ni}, 'h')
        fnet = fitmdl_setup_ohe(fnet, fnetspec, ni, num_dim_indvpre, num_samp_mdl, num_unit);
        lbnd_nonlin = ones(1, fnetspec.numbinhot{ni})*hotnonlin_weights(1);
        ubnd_nonlin = ones(1, fnetspec.numbinhot{ni})*hotnonlin_weights(2);
        x0_nonlin = ones(1, fnetspec.numbinhot{ni})*hotnonlin_weights(3);
    end

    num_par_this_neuron = length(x0_lin)+length(x0_nonlin);
    parind_this_neuron = [1:num_par_this_neuron] + num_par_running_total;
    num_par_running_total = num_par_running_total + num_par_this_neuron;
    pind(ni).L = parind_this_neuron(1:length(x0_lin));
    pind(ni).N = parind_this_neuron(length(x0_lin)+1:end);
    if strcmp(fnetspec.strlin{ni}, 'f')
        pind(ni).Lfree = parind_this_neuron(1:length(x0_lin));
    end

    linineq_A_tmp = zeros(1, num_par_this_neuron);
    if strcmp(fnetspec.stract{ni}, 'e')  %left asymptote <= right asymptote will make positive slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
        linineq_A_tmp(length(x0_lin)+2) = 1;
        linineq_A_tmp(length(x0_lin)+3) = -1;
    elseif strcmp(fnetspec.stract{ni}, 'i')  %right asymptote <= left asymptote will make negative slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
        linineq_A_tmp(length(x0_lin)+2) = -1;
        linineq_A_tmp(length(x0_lin)+3) = 1;
    end

    lbnd = [lbnd lbnd_lin lbnd_nonlin];
    ubnd = [ubnd ubnd_lin ubnd_nonlin];
    x0 = [x0 x0_lin x0_nonlin];
    linineq_A(neuron_ind_total, parind_this_neuron) = linineq_A_tmp;
    linineq_b(neuron_ind_total) = 0 + linineq_min_difference;

end


if any(strcmp(fnetspec.strlin, 'f'))
    freeformflag = 1;
else
    freeformflag = 0;
end

fnet.num_unit = num_unit;
fnet.fnetspec = fnetspec;
fnet.pind = pind;
fnet.max_num_fun_per_neuron = max_num_fun_per_neuron;
fnet.linfun = @linear_filter_1d;


%% nested model functions


    function [out, filt] = linear_filter_1d(in, filttype, doplots, varargin)


        %make linear filter
        if strcmp(filttype, 'f') %freeform, ie non-parametric, linear filter, directly optimize weights
           
            filt = cell2mat(varargin);
        
        elseif any(strcmp(filttype, {'s', 'd'})) % otherwise, it's a parametric filter
            
            filt_tau1 = varargin{1};
            filt_tshift = varargin{2};
            if nargin==6
                filt_bias = varargin{3};
            else
                filt_bias = 0;
            end

            filt_tlong = tlong./filt_tau1^2.*exp(-tlong./filt_tau1); %t = t minus filt_tshift does not work for this, so using interp below for filt_tshift
            if strcmp(filttype, 'd')
                filt_tlong = [0 diff(filt_tlong)];
            end

            if doplots
                tmpplot = filt_tlong(1:numel(t));
                tmpplot = tmpplot / norm(tmpplot(:),1) * con_filtnorm; %normalize by L1
                hfg = figure; hax = axes('Parent', hfg); plot(hax, t, tmpplot); hold on;
            end

            filt_padded(:) = 0; %initialized earlier, re-zeroed here each time through this function
            filt_padded(filt_padlen+1:end-filt_padlen) = filt_tlong;
            filt_padded = spline(t_shifted+filt_tshift,filt_padded,t_shifted);
            if strcmp(filttype, 's')
                filt_padded(filt_padded<0) = 0; %hack to remove interp artifacts when filter should be nonnegative
            end
            filt = filt_padded(filt_padlen+1:end-filt_padlen); %shorten to numel(tlong)
            filt = filt / norm(filt(:),1) * con_filtnorm; %normalize by L1
            filt = filt(1:numel(t)); %shorten to final length, numel(t)
            filt = filt / norm(filt(:),1) * con_filtnorm; %normalize by L1

            if doplots
                plot(hax, t, filt);
                close(hfg)
            end
        end
        
        %apply linear filter
        out = sum(in.*filt, 2); 
        out = out + filt_bias;

    end



    function out = static_genlog(in, varargin)

        if nargin==6
            B = varargin{1};
            A = varargin{2};
            K = varargin{3};
            V = varargin{4};
            M = varargin{5};
        else
            error("currently (temporarily) written to accept 6 inputs")
        end

        out = A + ( (K - A) ./ ( C + Q * exp( -B * (in-M) ) .^ 1/V ) );

    end



end
