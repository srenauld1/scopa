function opt = ored(opt, mos)

%{

ored ("options reduce") removes ambiguity/redundancy in options struct (since options can depend on each other, and multiple values can have the same effect)
ored is called before structfile assigns optid to an options set (in oid)

%}

arguments
    opt
    mos
end


switch mos %further specialized reduction by mos
    case 'roi'
        opt = ored_roi(opt);
    case 'bmp'
        opt = ored_bmp(opt);
end


end



function opt = ored_roi(opt)

two_channel_ex = 1; %hard coding for now, soon, parse methodex

if ~isempty(opt.nrm) && opt.nrm.channorm==0
    opt.nrm.mincoh = []; %rmfield(opt.nrm, 'mincoh');
end


if ~isempty(opt.cm) %unfortunately, a complex reduction scheme is required for caiman options, since there are many interactions

    % if any(structfun(@(x) any(strcmp(x, '*')), opt.cm))
    %     error("caiman options do not work right now for wild=1 in ofill - why not??")
    % end

    %%assemble reduced cmex struct (gets special attention because it's relatively more complicated)

    cmred.gSig = opt.cm.gSig;
    cmred.nb = opt.cm.nb;
    cmred.low_rank_background = opt.cm.low_rank_background;
    cmred.update_background_components = opt.cm.update_background_components;
    cmred.normalize_init = opt.cm.normalize_init;
    cmred.only_init = opt.cm.only_init;

    cmred.roidensity = opt.cm.roidensity; %used to derive K

    %init
    cmred.method_init = opt.cm.method_init;

    if strcmp(opt.cm.method_init, 'greedy_roi')
        if opt.cm.rolling_sum
            cmred.rolling_sum = opt.cm.rolling_sum;
            cmred.rolling_length = opt.cm.rolling_length;
        end
    elseif strcmp(opt.cm.method_init, 'graph_nmf') || strcmp(opt.cm.method_init, 'sparse_nmf')
        cmred.sigma_smooth_snmf_time = opt.cm.sigma_smooth_snmf_time;
        cmred.perc_baseline_snmf = opt.cm.perc_baseline_snmf;
        cmred.max_iter_snmf = opt.cm.max_iter_snmf;
        cmred.sparsity_penalty = opt.cm.sparsity_penalty;
        if strcmp(opt.cm.method_init, 'graph_nmf')
            cmred.SC_sigma = opt.cm.SC_sigma;
            cmred.SC_thr = opt.cm.SC_thr;
            cmred.SC_normalize = opt.cm.SC_normalize;
            cmred.SC_use_NN = opt.cm.SC_use_NN;
            cmred.SC_nnn = opt.cm.SC_nnn;
        end
    end

    if opt.cm.only_init==0 %if not doing initialization only

        %temporal
        cmred.p = opt.cm.p;
        cmred.ITER = opt.cm.ITER;

        %deconvolution
        if opt.cm.p~=0
            cmred.bas_nonneg = opt.cm.bas_nonneg;
            cmred.fudge_factor = opt.cm.fudge_factor;
        end

        %spatial
        cmred.thr_method = opt.cm.thr_method;
        cmred.maxthr = opt.cm.maxthr;
        cmred.nrgthr = opt.cm.nrgthr;
        cmred.extract_cc = opt.cm.extract_cc;

        %merging
        cmred.merge_thr = opt.cm.merge_thr;
    end

    %patches
    if ~two_channel_ex && opt.cm.patchfac~=0 % was ~isempty(opt.cm.rf)
        cmred.patchfac = opt.cm.patchfac; %USED TO DERIVE RF AND K
        cmred.stridefac = opt.cm.stridefac; %USED TO DERIVE STRIDE AND K
        if opt.cm.low_rank_background
            cmred.nb_patch = 0;
        else
            cmred.nb_patch = opt.cm.nb_patch;
        end
        if opt.cm.p~=0
            cmred.p_patch = opt.cm.p_patch;
        end
    end

    %evaluation
    if opt.cm.use_cnn
        cmred.use_cnn = opt.cm.use_cnn;
        cmred.cnn_lowest = opt.cm.cnn_lowest;
        cmred.min_cnn_thr = opt.cm.min_cnn_thr;
    end

    if startsWith(opt.cm.methodex, 'seed') && endsWith(opt.cm.methodex, 'py') %python automated morph roi extraction to seed functional extraction (not just two_channel_ex since seedeachpy is not two_channel_ex)
        cmred.morph_min_area_size = opt.cm.morph_min_area_size;
        cmred.morph_min_hole_size = opt.cm.morph_min_hole_size;
        cmred.morph_expand_method = opt.cm.morph_expand_method;
        cmred.morph_gSig = opt.cm.morph_gSig;
    end

    %% merge non-cm and cm options

    opt.cm = cmred;

    opt = structsort(opt); %recursively order alphabetically


end


end


function opt = ored_bmp(opt)

if strcmp(opt.domtype, 'm') && isfield(opt, 'mdl') && ~isempty(opt.mdl) %if domtype (domain type) is m (morphological), make empty the options used for domtype f (functional)
    opt.mdl = []; %rmfield(opt, 'mdl');
    opt.numangrs = [];
    opt.maxangrs = [];
end

end