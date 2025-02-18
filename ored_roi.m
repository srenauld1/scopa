
function o = ored_roi(o)

% reduce to minimal effective set based on interactions among options 

two_channel_ex = 1; %hard coding for now, soon, parse methodex

%% remove large submodules if they don't have do true


if o.domm==0 && isfield(o, 'mm')
    o.mm = struct; %rmfield(o, 'mm');
end
if o.doma==0 && isfield(o, 'ma')
    o.ma = struct; %rmfield(o, 'ma');
end
if o.doqc==0 && isfield(o, 'qc')
    o.qc = struct; %rmfield(o, 'qc');
end
if o.docm==0 && isfield(o, 'cm')
    o.cm = struct; %rmfield(o, 'cm');
end

if o.nrm.channorm==0
    o.nrm.mincoh = []; %rmfield(o.nrm, 'mincoh');
end

if o.docm==1 %unfortunately complex reduction scheme for caiman options, since there are many interactions

    if any(structfun(@(x) any(strcmp(x, '*')),o.cm))
        error("need to fix caiman ored for wild")
    end
    %%assemble reduced cmex struct (gets special attention because it's relatively more complicated)

    cmred.gSig = o.cm.gSig;
    cmred.nb = o.cm.nb;
    cmred.low_rank_background = o.cm.low_rank_background;
    cmred.update_background_components = o.cm.update_background_components;
    cmred.normalize_init = o.cm.normalize_init;
    cmred.only_init = o.cm.only_init;

    cmred.roidensity = o.cm.roidensity; %used to derive K

    %init
    cmred.method_init = o.cm.method_init;

    if strcmp(o.cm.method_init, 'greedy_roi')
        if o.cm.rolling_sum
            cmred.rolling_sum = o.cm.rolling_sum;
            cmred.rolling_length = o.cm.rolling_length;
        end
    elseif strcmp(o.cm.method_init, 'graph_nmf') || strcmp(o.cm.method_init, 'sparse_nmf')
        cmred.sigma_smooth_snmf_time = o.cm.sigma_smooth_snmf_time;
        cmred.perc_baseline_snmf = o.cm.perc_baseline_snmf;
        cmred.max_iter_snmf = o.cm.max_iter_snmf;
        cmred.sparsity_penalty = o.cm.sparsity_penalty;
        if strcmp(o.cm.method_init, 'graph_nmf')
            cmred.SC_sigma = o.cm.SC_sigma;
            cmred.SC_thr = o.cm.SC_thr;
            cmred.SC_normalize = o.cm.SC_normalize;
            cmred.SC_use_NN = o.cm.SC_use_NN;
            cmred.SC_nnn = o.cm.SC_nnn;
        end
    end

    if o.cm.only_init==0 %if not doing initialization only

        %temporal
        cmred.p = o.cm.p;
        cmred.ITER = o.cm.ITER;

        %deconvolution
        if o.cm.p~=0
            cmred.bas_nonneg = o.cm.bas_nonneg;
            cmred.fudge_factor = o.cm.fudge_factor;
        end

        %spatial
        cmred.thr_method = o.cm.thr_method;
        cmred.maxthr = o.cm.maxthr;
        cmred.nrgthr = o.cm.nrgthr;
        cmred.extract_cc = o.cm.extract_cc;

        %merging
        cmred.merge_thr = o.cm.merge_thr;
    end

    %patches
    if ~two_channel_ex && o.cm.patchfac~=0 % was ~isempty(o.cm.rf)
        cmred.patchfac = o.cm.patchfac; %USED TO DERIVE RF AND K
        cmred.stridefac = o.cm.stridefac; %USED TO DERIVE STRIDE AND K
        if o.cm.low_rank_background
            cmred.nb_patch = 0;
        else
            cmred.nb_patch = o.cm.nb_patch;
        end
        if o.cm.p~=0
            cmred.p_patch = o.cm.p_patch;
        end
    end

    %evaluation
    if o.cm.use_cnn
        cmred.use_cnn = o.cm.use_cnn;
        cmred.cnn_lowest = o.cm.cnn_lowest;
        cmred.min_cnn_thr = o.cm.min_cnn_thr;
    end

    if startsWith(o.cm.methodex, 'seed') && endsWith(o.cm.methodex, 'py') %python automated morph roi extraction to seed functional extraction (not just two_channel_ex since seedeachpy is not two_channel_ex)
        cmred.morph_min_area_size = o.cm.morph_min_area_size;
        cmred.morph_min_hole_size = o.cm.morph_min_hole_size;
        cmred.morph_expand_method = o.cm.morph_expand_method;
        cmred.morph_gSig = o.cm.morph_gSig;
    end

    %% merge non-cm and cm options

    o.cm = cmred;

    o = structsort(o); %recursively order alphabetically


end
