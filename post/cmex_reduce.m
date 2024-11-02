
function ored = cmex_reduce(o)


fn = fieldnames(o);
kp = ~startsWith(fn, 'cm_');
otmp = struct2cell(o);
otmp = otmp(kp); %separate non-cmex options
otmp = cell2struct(otmp, fn(kp));

%% assemble reduced cmex struct 

ored.cm__gSig = o.cm__gSig;
ored.cm__nb = o.cm__nb;
ored.cm__low_rank_background = o.cm__low_rank_background;
ored.cm__update_background_components = o.cm__update_background_components;
ored.cm__normalize_init = o.cm__normalize_init;
ored.cm__only_init = o.cm__only_init;

ored.cm__roidensity = o.cm__roidensity; %used to derive K

%init
ored.cm__method_init = o.cm__method_init;

if strcmp(o.cm__method_init, 'greedy_roi')
    if o.cm__rolling_sum
        ored.cm__rolling_sum = o.cm__rolling_sum;
        ored.cm__rolling_length = o.cm__rolling_length;
    end
elseif strcmp(o.cm__method_init, 'graph_nmf') || strcmp(o.cm__method_init, 'sparse_nmf')
    ored.cm__sigma_smooth_snmf_time = o.cm__sigma_smooth_snmf_time;
    ored.cm__perc_baseline_snmf = o.cm__perc_baseline_snmf;
    ored.cm__max_iter_snmf = o.cm__max_iter_snmf;
    ored.cm__sparsity_penalty = o.cm__sparsity_penalty;
    if strcmp(o.cm__method_init, 'graph_nmf')
        ored.cm__SC_sigma = o.cm__SC_sigma;
        ored.cm__SC_thr = o.cm__SC_thr;
        ored.cm__SC_normalize = o.cm__SC_normalize;
        ored.cm__SC_use_NN = o.cm__SC_use_NN;
        ored.cm__SC_nnn = o.cm__SC_nnn;
    end
end

if o.cm__only_init==0 %if not doing initialization only

    %temporal
    ored.cm__p = o.cm__p;
    ored.cm__ITER = o.cm__ITER;

    %deconvolution
    if o.cm__p~=0
        ored.cm__bas_nonneg = o.cm__bas_nonneg;
        ored.cm__fudge_factor = o.cm__fudge_factor;
    end

    %spatial
    ored.cm__thr_method = o.cm__thr_method;
    ored.cm__maxthr = o.cm__maxthr;
    ored.cm__nrgthr = o.cm__nrgthr;
    ored.cm__extract_cc = o.cm__extract_cc;

    %merging
    ored.cm__merge_thr = o.cm__merge_thr;
end

%patches
if ~two_channel_ex && o.cm__patchfac~=0 % was ~isempty(o.cm__rf)
    ored.cm__patchfac = o.cm__patchfac; %USED TO DERIVE RF AND K
    ored.cm__stridefac = o.cm__stridefac; %USED TO DERIVE STRIDE AND K
    if o.cm__low_rank_background
        ored.cm__nb_patch = 0;
    else
        ored.cm__nb_patch = o.cm__nb_patch;
    end
    if o.cm__p~=0
        ored.cm__p_patch = o.cm__p_patch;
    end
end

%evaluation
if o.cm__use_cnn
    ored.cm__use_cnn = o.cm__use_cnn;
    ored.cm__cnn_lowest = o.cm__cnn_lowest;
    ored.cm__min_cnn_thr = o.cm__min_cnn_thr;
end

if startsWith(o.cm__methodex, 'seed') && endsWith(o.cm__methodex, 'py') %python automated morph roi extraction to seed functional extraction (not just two_channel_ex since seedeachpy is not two_channel_ex)
    ored.cm__morph_min_area_size = o.cm__morph_min_area_size;
    ored.cm__morph_min_hole_size = o.cm__morph_min_hole_size;
    ored.cm__morph_expand_method = o.cm__morph_expand_method;
    ored.cm__morph_gSig = o.cm__morph_gSig;
end

%merge non-cm options, and reduced cm options

ored = cell2struct([struct2cell(otmp); struct2cell(ored)], [fieldnames(otmp); fieldnames(ored)]); %combine mdsi (md) and flyg md into one struct, md

ored = structord(ored); %recursively order alphabetically


end
