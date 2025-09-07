function [o, optinert] = ored(o, vbin, delim, opt)

%{
ored ("options reduce") removes options that have no effect on the data (like plotting options),
and also removes redundancy (since options can depend on each other)
also checks for problems (like invalid values (problem checking should have its own function eventually)
ored is called before assigning id (optid) to an options set (using structfile in oid)
%}

arguments
    o
    vbin
    delim
    opt.inert_vbin = []
end
opt = glboropt(opt);
inert_vbin = opt.inert_vbin;

if isempty(inert_vbin)
    error("inert_vbin must be defined in glb")
end
if isfield(o, vbin)
    error("you passed o with substruct " + vbin + " but should pass in that substruct itself")
end

o = structflat(o, delim=delim);
fnoflat = fieldnames(o);
expr = [strcat('^', inert_vbin, delim), strcat(delim, inert_vbin, delim), strcat(delim, inert_vbin, '$'), strcat('^', inert_vbin, '$')]; %all possible positions of inert vbin in the flattened names
mtch = zeros(numel(fnoflat), 1, 'logical');
mtch_is_struct = zeros(numel(fnoflat), 1, 'logical');
for k = 1:numel(expr)
    mtchtmp = ~cellfun(@isempty, regexp(fnoflat, expr{k}));
    mtch = mtch | mtchtmp;
    if endsWith(expr{k}, delim)
        mtch_is_struct = mtch_is_struct | mtchtmp;
    end
end

o = struct2cell(o);

optinert = o(mtch);
fninert = fnoflat(mtch);
optinert = cell2struct(optinert, fninert);

dupes = [];
for k = 1:numel(inert_vbin)
    fnoflat(mtch_is_struct) = regexprep(fnoflat(mtch_is_struct), [inert_vbin{k} '.*'], inert_vbin{k});
    [~, w] = unique( fnoflat, 'stable' );
    tmp = setdiff( 1:numel(fnoflat), w );
    dupes = [dupes; tmp(:)];
end

o(mtch) = {[]};
o(mtch_is_struct) = {struct('tg', [])}; %insert empty tg field for json to write empty tg properly (hack needs top be fixed)
o(dupes) = [];
fnoflat(dupes) = [];
o = cell2struct(o, fnoflat);
o = structunflat(o, delim=delim);

switch vbin %further specialized reduction by vbin
    case 'roi'
        o = ored_roi(o);
    case 'bmp'
        o = ored_bmp(o);
end


end



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


if o.docm==1 %unfortunately, a complex reduction scheme is required for caiman options, since there are many interactions

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


end


function o = ored_bmp(o)

%reduce bmp options to minimal functional set

if strcmp(o.domtype, 'm') && isfield(o, 'mdl') %if domtype (domain type) is m (morphological), make empty the options used for domtype f (functional)
    o.mdl = struct; %rmfield(o, 'mdl');
    o.numangrs = [];
    o.maxangrs = [];
end

end