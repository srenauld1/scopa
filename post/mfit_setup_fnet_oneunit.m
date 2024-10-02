
function [lbnd, ubnd, linineq_A, linineq_b, x0, fnet, freeformflag] = ...
    mfit_setup_fnet_oneunit(fnetspec, num_samp_mdl, imper, num_dim_indvp, padlen_sec, inputvar_stats, multi_time_in_layer_one_only)



%% some useful stats on input variables

depvp_extreme_alldim = inputvar_stats.depvp_extreme_alldim;
depvp_mean_alldim = inputvar_stats.depvp_mean_alldim;
depvp_min_alldim = inputvar_stats.depvp_min_alldim;
depvp_max_alldim = inputvar_stats.depvp_max_alldim;
indvp_extreme_alldim = inputvar_stats.indvp_extreme_alldim;
indvp_mean_alldim = inputvar_stats.indvp_mean_alldim;
indvp_min_alldim = inputvar_stats.indvp_min_alldim;
indvp_max_alldim = inputvar_stats.indvp_max_alldim;

%% define time domain for linear filters (constants in the nested functions)

tmax = imper*(num_samp_mdl-1);
t = 0:imper:tmax; %zero-indexed time for final/used filter

tlongfac = 2;
tlongmax = tmax*tlongfac;
tlong = 0:imper:tlongmax; %zero-indexed time for long-time domain filter (initial instantiation)

filt_padlen = round(padlen_sec/imper);
filt_padded = zeros(1, numel(tlong)+filt_padlen*2);
t_shifted_max = imper*(numel(filt_padded)-1);
t_shifted = 0:imper:t_shifted_max; %zero-indexed time for padded and shifted filter


%% nonlinear function constants

C = 1; %hard coded param
Q = 1; %hard coded param

%% some useful variables for this function

% max_num_fun_per_unit = max(sum(cellfun(@any, regexp([fnetspec.strlin(:) fnetspec.stract(:)], '[^l|a]')), 2));
fnet_funlist = fnetspec(:,startsWith(fnetspec.Properties.VariableNames, 'fun'));
% notemptyfunstring = ~cellfun(@isempty, regexp(table2cell(funcolumns), '[^l|n]'));
notemptycolumn = ~cellfun(@isempty, table2cell(fnet_funlist));
% max_num_fun_per_unit = sum(notemptyfunstring .* notemptycolumn);
fnet_funlist = fnet_funlist(:,notemptycolumn);
max_num_fun_per_unit = size(fnet_funlist, 2); %sum(notemptycolumn);

num_fun = max_num_fun_per_unit; %size(fnet_fun, 2);
freeformflag = any(strcmp(table2cell(fnet_funlist), 'f'));

%% define constraints for all possible params for each function unit (some will not be used, depending on unit type)

% prefix con_* denotes 'constraint', 3-element vectors below are [lowerbound, upperbound, startpoint]

con_filt_tau1 = [imper/2, 0.3, imper]; %filter tau, in units of seconds, don't tranform into units of samples since filter is implemented in time not samples
con_filt_tshift = [0, 0.75, 0.01];   %filter shift (ie lag, delay, rightward shift of filter) in seconds, implemented with spline interp
con_filt_bias = [-depvp_extreme_alldim, depvp_extreme_alldim, 0.01]; %"y intercept", "bias", added to linear filter output
con_filt_norm = [-2, 2, 1]; %L1 norm of whole filter (con_filt_tau1 filter minus con_tau2 filter, assuming latter is not norm zero )
con_filt_free_weights = [-depvp_extreme_alldim*2, depvp_extreme_alldim*2, depvp_mean_alldim];

% constraints for old 'd' filter function, 'linear_filter_1d_deprecated', more flexible but not as well behaved; now trying derivative of monophasic instead
% con_tau2 = [0.1, 2, 0.5]; %fraction by which con_tau2 is larger than con_filt_tau1 (better behaved)
% con_tc = [0, 1, 0.1]; %L1 norm of con_tau2 filter, redundant with con_filtnorm somewhat, so make con_filtnorm constant
% con_filtnorm = [-inf, inf, 1]; %L1 norm of whole filter (con_filt_tau1 filter minus con_tau2 filter, assuming latter is not norm zero )

con_genlog_slope = [0.1, depvp_extreme_alldim, 1]; %previously [0.1, inf, 1]  %force positive, letting left/right asymptotes determine sign without redundancy from slope (no constraint that left must be greater than right)
con_genlog_asympleft = [-depvp_extreme_alldim*2, depvp_extreme_alldim*2, depvp_min_alldim];
con_genlog_asympright = [-depvp_extreme_alldim*2, depvp_extreme_alldim*2, depvp_max_alldim];
con_genlog_inflection = [0, depvp_extreme_alldim*2, 1]; %must be positive, previous was [0, inf, 1]
con_genlog_xshift = [-indvp_extreme_alldim*2, indvp_extreme_alldim*2, mean([indvp_min_alldim indvp_max_alldim])];  %since con_filtnorm is forced to be 1, filter output will be on order of indv

hotnonlin_weights = [-depvp_extreme_alldim*2, depvp_extreme_alldim*2, depvp_mean_alldim];


%%


if strcmp(fnetspec.layer_in{1}, 'A')
    num_dim_in = numel(fnetspec.channel_in{1})*num_samp_mdl; %account for mdl samples on first layer, which currently only layer allowing multi mdl samples
else
    if multi_time_in_layer_one_only
    num_dim_in = numel(fnetspec.channel_in{1});
    else
        error("check this")
    end
end

lbnd = [];
ubnd = [];
x0 = [];
linineq_min_difference = 0; %zero allows equality, could try -2*options.ConstraintTolerance instead of zero (why -2, why not just -options.ConstraintTolerance?)
unit_ind_total = 0;
num_par_this_unit_cum = 0;

for fi = 1:num_fun

    fun_name = fnet_funlist.Properties.VariableNames{fi};

    fnet_onefun = fnet_funlist{:,fi}{1};

    unit_ind_total = unit_ind_total + 1;

    if strcmp(fnet_onefun, 'zzzzzzzz') %skips linear filter
        lbnd_tmp = [];
        ubnd_tmp = [];
        x0_tmp = [];
    elseif any(strcmp(fnet_onefun, {'s', 'r', 'd', 'c'})) %makes 2-param monophasic or biphasic linear filter, positive or negative 
        fnet.funh{fi} = @fun_linfilt_1d;
        lbnd_tmp = [con_filt_tau1(1), con_filt_tshift(1)];
        ubnd_tmp = [con_filt_tau1(2), con_filt_tshift(2)];
        x0_tmp = [con_filt_tau1(3), con_filt_tshift(3)];
    elseif strcmp(fnet_onefun, 'zzzzzz') %old approach for d filter, 'd2' specifier currently not supported %makes biphasic filter, 4 params, ie includes params for 2nd filter (constrained to be slower), subtracted from first
        fnet.funh{fi} = @linear_filter_1d_deprecated;
        lbnd_tmp = [con_filt_tau1(1), con_filt_tshift(1), con_tau2(1), con_tc(1)];
        ubnd_tmp = [con_filt_tau1(2), con_filt_tshift(2), con_tau2(2), con_tc(2)];
        x0_tmp = [con_filt_tau1(3), con_filt_tshift(3), con_tau2(3), con_tc(3)];
    elseif strcmp(fnet_onefun, 'f') %freeform filter, non-parametric
        fnet.funh{fi} = @fun_linfilt_1d;
        % lbnd_tmp = [ones(1, num_dim_in)*con_filt_free_weights(1) con_filt_bias(1)];
        % ubnd_tmp = [ones(1, num_dim_in)*con_filt_free_weights(2) con_filt_bias(2)];
        % x0_wt = rand(1, num_dim_in);%*con_filt_free_weights(3);
        % x0_wt = x0_wt / norm(vec(x0_wt(:)),1); %L1 norm=1 for starting filter 
        % x0_tmp = [x0_wt con_filt_bias(3)];
        lbnd_tmp = [ones(1, num_dim_in)*con_filt_free_weights(1)];
        ubnd_tmp = [ones(1, num_dim_in)*con_filt_free_weights(2)];
        x0_wt = rand(1, num_dim_in);%*con_filt_free_weights(3);
        x0_wt = x0_wt / norm(vec(x0_wt(:)),1); %L1 norm=1 for starting filter
        x0_tmp = x0_wt;
    elseif strcmp(fnet_onefun, 'zzzzzzz') || strcmp(fnet_onefun, 'zzzzzzzz') %skip activation function
        fnet.funh{fi} = [];
        lbnd_tmp = [];
        ubnd_tmp = [];
        x0_tmp = [];
    elseif any(strcmp(fnet_onefun, {'e', 'i', 'l'}))
        fnet.funh{fi} = @fun_genlog;
        lbnd_tmp = [con_genlog_slope(1), con_genlog_asympleft(1), con_genlog_asympright(1), con_genlog_inflection(1), con_genlog_xshift(1)];
        ubnd_tmp = [con_genlog_slope(2), con_genlog_asympleft(2), con_genlog_asympright(2), con_genlog_inflection(2), con_genlog_xshift(2)];
        x0_tmp = [con_genlog_slope(3), con_genlog_asympleft(3), con_genlog_asympright(3), con_genlog_inflection(3), con_genlog_xshift(3)];
    elseif strcmp(fnet_onefun, 'g')
        fnet.funh{fi} = @fun_gaussian;
        lbnd_tmp = [0,-5,0,0];
        ubnd_tmp = [3000,5,10,3000];
        x0_tmp = [1,1,1,0];
    elseif strcmp(fnet_onefun, 'v')
        fnet.funh{fi} = @fun_vonmises;
        lbnd_tmp = [-inf,-inf,-inf,-inf];
        ubnd_tmp = [inf,inf,inf,inf];
        x0_tmp = [con_genlog_asympleft(3),8,0,0];
        x0_tmp = [0,0,0,0];
    elseif strcmp(fnet_onefun, 'n')
        fnet.funh{fi} = @fun_sin;
        lbnd_tmp = [-inf,-inf,-inf,-inf];
        ubnd_tmp = [inf,inf,inf,inf];
        x0_tmp = [0,0,0,0];
    elseif startsWith(fnet_onefun, 'h')
        % previous approach ---> fnet = mfit_setup_ohe(fnet, fnetspec, fi, num_dim_indvp, num_samp_mdl, num_unit);
        num_bin_hot = sscanf(fnet_onefun, 'h%d');
        hotcombos = repmat(vec([1:num_bin_hot]), [1 num_dim_in]);
        fnet.funh{fi} = @fun_ohe;
        lbnd_tmp = ones(1, num_bin_hot)*hotnonlin_weights(1);
        ubnd_tmp = ones(1, num_bin_hot)*hotnonlin_weights(2);
        x0_tmp = ones(1, num_bin_hot)*hotnonlin_weights(3);
    end

    num_par_this_fun = length(x0_tmp);
    parind_this_fun = [1:num_par_this_fun] + num_par_this_unit_cum;
    num_par_this_unit_cum = num_par_this_unit_cum + num_par_this_fun;
    pind{fi} = parind_this_fun;
    funstr{fi} = fnet_onefun;

    linineq_A_tmp = zeros(1, num_par_this_fun);
    if strcmp(fnet_onefun, 'e')  %left asymptote <= right asymptote will make positive slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
        linineq_A_tmp(2) = 1;
        linineq_A_tmp(3) = -1;
    elseif strcmp(fnet_onefun, 'i')  %right asymptote <= left asymptote will make negative slope (assuming slope param constrained positive) but we want strictly less than (right?), so modify linineq_b to not be zero?
        linineq_A_tmp(2) = -1;
        linineq_A_tmp(3) = 1;
    end

    lbnd = [lbnd lbnd_tmp];
    ubnd = [ubnd ubnd_tmp];
    x0 = [x0 x0_tmp];
    linineq_A(unit_ind_total, parind_this_fun) = linineq_A_tmp;
    linineq_b(unit_ind_total) = 0 + linineq_min_difference;

end



fnet.num_fun = num_fun;
fnet.fnetspec = fnetspec;
fnet.pind = pind;
fnet.funstr = funstr;
fnet.max_num_fun_per_unit = max_num_fun_per_unit;


%% nested model functions


    function [out, filt] = fun_linfilt_1d(in, filttype, doplt, outflag, pars)


        %make linear filter
        if strcmp(filttype, 'f') %freeform, ie non-parametric, linear filter, directly optimize weights

            filt = pars;
            filt_bias = 0;
            % filt = pars(1:end-1);
            % filt_bias = pars(end);

        elseif any(strcmp(filttype, {'s', 'r', 'd', 'c'})) % otherwise, it's a parametric filter

            filt_tau1 = pars(1);
            filt_tshift = pars(2);
            if numel(pars)>2
                filt_norm = pars(3);
            else
                filt_norm = 1;
            end
            if numel(pars)>3
                filt_bias = pars(4);
            else
                filt_bias = 0;
            end

            filt_tlong = tlong./filt_tau1^2.*exp(-tlong./filt_tau1); %t = t minus filt_tshift does not work for this, so using interp below for filt_tshift
            if strcmp(filttype, 'd')
                filt_tlong = [0 diff(filt_tlong)];
            end

            if doplt
                tmpplot = filt_tlong(1:numel(t));
                tmpplot = tmpplot / norm(tmpplot(:),1) * filt_norm; %normalize by L1
                hfg = figure; hax = axes('Parent', hfg); plot(hax, t, tmpplot); hold on;
            end

            filt_padded(:) = 0; %initialized earlier, re-zeroed here each time through this function
            filt_padded(filt_padlen+1:end-filt_padlen) = filt_tlong;
            filt_padded = spline(t_shifted+filt_tshift,filt_padded,t_shifted);
            if strcmp(filttype, 's')
                filt_padded(filt_padded<0) = 0; %hack to remove interp artifacts when filter should be nonnegative
            end
            filt = filt_padded(filt_padlen+1:end-filt_padlen); %shorten to numel(tlong)
            filt = filt / norm(filt(:),1) * filt_norm; %normalize by L1
            filt = filt(1:numel(t)); %shorten to final length, numel(t)
            filt = filt / norm(filt(:),1) * filt_norm; %normalize by L1

            if doplt
                plot(hax, t, filt);
                close(hfg)
            end
        end

        %apply linear filter
        out = sum(in.*filt, 2);
        out = out + filt_bias;

    end



    function [out, out2] = fun_genlog(in, typeflag, doplt, outflag, pars)

        out2 = [];
        if numel(pars)==5
            B = pars(1);
            A = pars(2);
            K = pars(3);
            V = pars(4);
            M = pars(5);
        else
            error("currently (temporarily) written to accept 5 params")
        end

        out = A + ( (K - A) ./ ( C + Q * exp( -B * (in-M) ) .^ 1/V ) );

    end


    function [out, out2] = fun_vonmises(in, typeflag, doplt, outflag, pars)

        out2 = [];
        out = pars(1)*exp(pars(2)*cos(in-pars(3)))+pars(4);

    end

    function [out, out2] = fun_sin(in, typeflag, doplt, outflag, pars)

        out2 = [];
        out = pars(1).*(sin(2*pi*in./pars(2) + 2*pi/pars(3))) + pars(4);

    end


    function [out, out2] = fun_gaussian(in, typeflag, doplt, outflag, pars)

        out2 = [];
        out = pars(1)*exp(-(((in-pars(2)).^2)/(2*pars(3).^2)))+pars(4);
    
    end


    function [out, binmns] = fun_ohe(in, typeflag, doplt, outflag, pars)

        % indvin_hot(:) = 0;
        [indvin_hot, binmns] = probability_bin(in, num_bin_hot, outflag);

        [~, levs_full_hot] = ismember(indvin_hot, hotcombos, 'rows');

        indshot = [1:num_bin_hot]; 
        in = levs_full_hot==indshot;

        in = double(in);

        if doplt
            pthspre = '';
            filename_save_hot_levels = [pthspre '_hotlevels_.png'];
            figure; imagesc(hotcombos)
            saveas(gcf, filename_save_hot_levels)
        end

        out = in*pars';

    end


end
