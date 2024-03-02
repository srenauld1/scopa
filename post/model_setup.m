
function [objfcn, lbnd, ubnd, linineq_A, linineq_b, x0, numftpars, ...
    gethue, getsat, getval, gethr_native, gethr_relative, ...
    getsr_native, getsr_relative, getvr_native, getvr_relative, ...
    hrange_out_manual, hue_is_periodic, supp] = ...
    model_setup(modeltype, huestr, hrange_out_manual, ...
    indvaug, num_samp_model, num_dim_indvaug, num_dim_ivin, depvin, dtmni)

%how to do "inline if" (iif)
iif = @(varargin) varargin{2 * find([varargin{1:2:end}], 1, 'first')}();

linineq_A = [];
linineq_b = [];


hue_is_periodic = 0;
if strcmp(modeltype, 'vonmises') & strcmp(huestr, 'loc') %only if the param assigned to hue is periodic, make hrange the full circle
    "WARNING, CHANGING hrange_out_manual TO [0 1] BECAUSE HUE PARAM IS PERIODIC"
    hue_is_periodic = 1;
    hrange_out_manual = [0 1];
end

switch modeltype

    case 'svd'
        objfcn = @fit_svd;
        lbnd = [];
        ubnd = [];
        x0 = zeros(1, num_dim_indvaug);
        switch huestr
            case 'loc'
                gethue = @(ft, st, pr) ft(1);
                gethr_native = @(ft,st,rs) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
            case 'wid'
                error("NO WID PARAM FOR LINEAR MODEL")
            case 'amp'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
        end
        supp.num_model_functions = 1;

        

    case 'linear'

        objfcn = @(bv,x,supp,pthspre) bv(1) * x + bv(2); 
        lbnd = [-inf,-3000]; %[0,0,0,-pi]; %a, c, k, u
        ubnd = [inf,3000]; %[inf,inf,inf,pi];
        x0 = [0,0];

        switch huestr
            case 'loc'
                gethue = @(ft, st, pr) ft(1);
                gethr_native = @(ft,st,rs) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
            case 'wid'
                error("NO WID PARAM FOR LINEAR MODEL")
            case 'amp'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
        end
        supp.num_par_total = length(lbnd);
        supp.NumTrialPoints = 1000;
        supp.NumStageOnePoints = 200;


    case 'plane'

        %objfcn = @(b,x,supp) b(1) * x(:,1) + b(2) * x(:,2) + b(3) * x(:,3) + b(4) * x(:,4) + b(5);
        objfcn = @fit_plane;
        lbnd = [ones(1, num_dim_indvaug)*3000 -inf]; %[0,0,0,-pi]; %a, c, k, u
        ubnd = [ones(1, num_dim_indvaug)*3000 inf]; %[inf,inf,inf,pi];
        x0 = [ones(1, num_dim_indvaug)*2 0];

        switch huestr
            case 'loc'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
            case 'wid'
                error("NO WID PARAM FOR LINEAR MODEL")
            case 'amp'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
        end
        supp = [];


    case 'genlog'

        objfcn = @(bv,x,supp,pthspre) bv(1) + ( (bv(2) - bv(1)) ./ ( bv(3) + bv(4) * exp( -bv(5) * (x-bv(6)) ) .^ 1/bv(7) ) );
        lbnd = -inf(1,7); %[0,0,0,-pi]; %a, c, k, u
        ubnd = inf(1,7); %[inf,inf,inf,pi];
        x0 = ones(1,7);

        switch huestr
            case 'loc'
                gethue = @(ft, st, pr) ft(1);
                gethr_native = @(ft,st,rs) error("NO NATIVE LOC NORMALIZATION FOR LINEAR MODEL, SINCE SLOPE IS UNBOUNDED"); %was [-1 1] which doesn't make sense;
            case 'wid'
                error("NO WID PARAM FOR GENLOG MODEL")
            case 'amp'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
        end
        supp = [];


    case 'vonmises'

        objfcn = @(bv,x,supp,pthspre) bv(1)*exp(bv(2)*cos(x-bv(3)))+bv(4); 
        lbnd = [-inf,-inf,-inf,-inf];
        ubnd = [inf,inf,inf,inf];
        x0 = [0,0,0,0];
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
        supp.num_par_total = length(lbnd);
        supp.NumTrialPoints = 1000;
        supp.NumStageOnePoints = 200;


    case 'gaussian'

        objfcn = @(bv,x,supp,pthspre) bv(1)*exp(-(((x-bv(2)).^2)/(2*bv(3).^2)))+bv(4);
        lbnd = [0,-5,0,0];
        ubnd = [3000,5,10,3000];
        x0 = [1,1,1,0];

        switch huestr
            case 'loc'
                gethue = @(ft, st, pr) ft(2);
                gethr_native = @(ft,st,rs) [min(st(:)) max(st(:))];
            case 'wid'
                gethue = @(ft, st, pr) 2 * ((2 * log( 2 )) ^ 0.5) * abs(ft(3)); %fwhm
                gethr_native = @(ft,st,rs) [min(st(:)) max(st(:))];
            case 'amp'
                gethue = @(ft, st, pr) ft(1);
                gethr_native = @(ft,st,rs) [min(rs(:)) max(rs(:))];
        end
        supp = [];


    case {'glno3', 'glno4', 'glno5'}
        [objfcn, lbnd, ubnd, linineq_A, linineq_b, x0, supp, gethue, gethr_native] = ...
            fit_glno(modeltype, indvaug, depvin, num_samp_model, num_dim_ivin, huestr);

    case 'tm'
        objfcn = @nonadaptive_tm; 
        lbnd = [0, 0, -inf(1,14)];
        ubnd = [45, 360, inf(1,14)];
        x0 = [10, 10, ones(1,14)];
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

        vert_load_path = [filesep 'Users' filesep 'wienecke' filesep 'Documents' filesep 'GitHub' filesep 'flyMax' filesep 'indvGeneration' filesep]; %%path to folder containing vertices
        filename_vertices = 'vertices_8000_0.txt';
        pth = rdir([vert_load_path filename_vertices]);
        phimx = 0.769961614088224; %image max phi
        vert = dlmread( pth.name );
        vert = vert(max(vert(:, 3),-1) >= cos(phimx), :); %crop vertices to be within indv cap, do after find_arc_length
        vert = vert./vecnorm(vert,2, 2);  %normalize it to lie on the sphere!!
        disp("WARNING, HARD CODED CROP TO num_dim_ivin VERTICES")
        vert = vert(1:num_dim_ivin,:);
        supp.vert = vert;

end

numftpars = length(x0);

getsat = @(gof) 1/gof;
getval = @(rs) std(rs);

gethr_relative = @(ft) iif( ...
    length(ft)>1,   @() [min(ft(:)) max(ft(:))], ...
    length(ft)==1,  @() [0 ft] ... %hack to deal with normalizing length 1, will arbitrarily make hue max hue
    );

getsr_native = @(sdata) [0 100]; %need to input values depnding on gof metric
getsr_relative = @(sdata) iif( ...
    length(sdata)>1,   @() [min(sdata(:)) max(sdata(:))], ...
    length(sdata)==1,  @() [0 sdata] ... %hack to deal with normalizing length 1, will arbitrarily make hue max hue
    );

getvr_native = @(vdata) [0 3]; %need to input values depending on indicator
getvr_relative = @(vdata) iif( ...
    length(vdata)>1,   @() [min(vdata(:)) max(vdata(:))], ...
    length(vdata)==1,  @() [0 vdata] ... %hack to deal with normalizing length 1, will arbitrarily make hue max hue
    );


end



