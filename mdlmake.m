function mdl = mdlmake(opt, indv, depv, imrate, pthstack, epochts, doplt, numsyn, ld, histinc)


%{
for outdated docs, see file mdl_notes.m

if indv/depv are defined in options struct as struct tg, they get assigned
every resulting indv/depv pairing gets assigned an id; if indv/depv are
defined directly (as numeric or cell array) in options struct, or if
they're defined as input arguments indv and depv, the pairing does not get
an id (since the id relies on their labels, not the data itself)

mdl_varpr adds to mdl struct with prepared vars and also outputs mdl.st
mdl_optimpr output mdl.op with model options, and mdl.op.supp with model params
mdl_epochs output mdl.fit with fit info
  within mdl_epochs is mdl_fit where fit occurs
mdl_plots plots model

%}

arguments
    opt
    indv = [] %independent variable(s) before processing; if indvp and depvp are cells, separate models are fit to all indvp/depvp pairs (loop over mdlmake_one), if mat, only one model is fit
    depv = [] %dependent variable(s) before processing; if indvp and depvp are cells, separate models are fit to all indvp/depvp pairs (loop over mdlmake_one), if mat, only one model is fit
    imrate = [] %imaging rate
    pthstack = [] %path to stack
    epochts = []
    doplt = []
    numsyn = 0 %run numsyn synthetic data tests; test fits use model options in opt, and synthetic data with same bounds as input data after option-dependent processing); numsyn is number of synthetic responses to fit; [] or 0 to skip
    ld = 0 %load saved model if it exists
    histinc = 0; %optimization iteration increment to save; 0 to skip saving optimization history
end

if ~isequal(isempty(indv), isempty(depv), ~isempty(opt.indv), ~isempty(opt.depv))
    error("indv and depv must both be empty or nonempty")
end


%% loop over indv/depv

if isempty(indv) && isempty(depv) %if indv/depv are defined in the options struct, instead of passed in as arguments

    if isstruct(opt.indv) && all(startsWith(fieldnames(opt.indv), 'tg')) 
        indv = tsget(opt.indv);
    elseif isnumeric(opt.indv) || iscell(opt.indv) && all(cellfun(@isnumeric, cellflat(opt.indv))) && all(~cellfun(@isempty, cellflat(opt.indv)))
        indv = opt.indv;
    else
        error("if indv is defined in opt, it must be numeric, or nonempty numeric cells, or struct tg (to define options for tsget)")
    end

    if isstruct(opt.depv) && all(strcmp(fieldnames(opt.depv), 'tg'))
        depv = tsget(opt.depv);
    elseif isnumeric(opt.depv) || iscell(opt.depv) && all(cellfun(@isnumeric, cellflat(opt.depv))) && all(~cellfun(@isempty, cellflat(opt.depv)))
        depv = opt.depv;
    else
        error("if depv is defined in opt, it must be numeric, or nonempty numeric cells, or struct tg (to define options for tsget)")
    end

    if isempty(indv) || isempty(depv)
        error("depv and indv must both be nonempty; tsget did not find indv and/or depv")
    end

end

if ~iscell(indv)
    indv = {indv};
end
if ~iscell(depv)
    depv = {depv};
end

[tmpc,tmpr] = meshgrid(1:numel(indv), 1:numel(depv));
pairind = [tmpc(:) tmpr(:)];
numfit = size(pairind,1);

for k = 1:numel(numfit) %loop over indv/depv pairs
    mdl = mdlmake_one(indv{pairind(k,1)}, depv{pairind(k,2)}, opt, imrate, pthstack, epochts, doplt, numsyn, ld, histinc);
end


end

function mdl = mdlmake_one(indvp, depvp, opt, imrate, pthstack, epochts, doplt, numsyn, ld, histinc)

pthpre = [erase(pthstack, '.mat') opt.optid '_mdl_'];
pthmdl = [pthpre '.mat'];

try

    mdl = load(pthmdl);
    lddat = mdl.lddat;
    chk = dir(opt.ld);
    if ~isequal(lddat.datenum, chk.datenum) || isequal(lddat.bytes, chk.bytes)
        error("file date and/or size has changed since it was used to create fitdata file; it may have been modified; recreate fitdata with the current version of this file")
    end

catch ME

    if isempty(epochts)
        epochts = ones(1, size(depvp, 2));
    end
    if isempty(doplt)
        doplt = any(strcmp('mdl', glb('plt')));
    end

    opt.hsv_background = "";

    if ~isa(indvp, 'single') && ~isa(indvp, 'double')
        indvp = single(indvp);
    end
    if ~isa(depvp, 'single') && ~isa(depvp, 'double')
        depvp = single(depvp);
    end

    if isvector(indvp) && iscolumn(indvp)
        indvp = indvp(:)';
    end

    [ mdl.num_dim_indvp, mdl.num_samp_indvp ] = size(indvp);
    [ mdl.num_dim_depvp, mdl.num_samp_depvp ] = size(depvp);

    if mdl.num_samp_indvp~=mdl.num_samp_depvp | ndims(depvp)~=2 | ndims(indvp)~=2
        error("incorrectly sized input(s)")
    end

    %% prepare indv and depv

    mdl = mdl_varpr(mdl, indvp, depvp, opt, imrate, pthpre, epochts);

    %% set up model params and optimization options

    mdl.op = mdl_optimpr(mdl.num_samp_mdl, mdl.num_dim_indv, mdl.num_dim_indvp, opt, imrate, mdl.st, pthpre);

    %% fit model to requested subset of indv/depv

    mdl = mdl_epochs(mdl, opt, pthpre, numsyn, ld, histinc);

    %% save

    save(pthmdl, 'mdl', '-v7.3', '-mat')

end

%% plot

if doplt
    mdl_plots(mdl, roidat, stack, opt, pthpre)
end

%% clean up

if isfile(mdl.pth_indvaug)
    delete(mdl.pth_indvaug)
end
if isfile(mdl.pth_depvp_bin)
    delete(mdl.pth_depvp_bin)
end
tmp = rdir([pthpre '*_DUMMY_.mat']);
if ~isempty(tmp)
    delete(tmp.name)
end


end

