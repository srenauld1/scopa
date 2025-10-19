function mdl = mdlmake(opt, indv, depv, pthstack, opt2)


%{
for outdated docs, see file mdl_notes.m

if indv/depv are defined in options struct as struct vg, they get assigned
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
    opt = []
    indv = [] %independent variable(s) before processing; if indv and depv are cells, separate models are fit to all indv/depv pairs (loop over mdlmake_one), if mat, only one model is fit
    depv = [] %dependent variable(s) before processing; if indv and depv are cells, separate models are fit to all indv/depv pairs (loop over mdlmake_one), if mat, only one model is fit
    pthstack = [] %path to stack
    opt2.srate = [] %imaging rate
    opt2.epochts = []
    opt2.doplt = []
    opt2.ldval = 0 %load saved model if it exists
    opt2.numsyn = 0 %run numsyn synthetic data tests; test fits use model options in opt, and synthetic data with same bounds as input data after option-dependent processing); numsyn is number of synthetic responses to fit; [] or 0 to skip
    opt2.histinc = 0; %optimization iteration increment to save; 0 to skip saving optimization history
end
srate = opt2.srate;
epochts = opt2.epochts;
doplt = opt2.doplt;
ldval = opt2.ldval;
numsyn = opt2.numsyn;
histinc = opt2.histinc;

[opt, doplt, pthstack] = fset('mdl', opt, doplt, pthstack);

if isempty(srate)
    error("must pass in srate or set glb('srate'), or set name-value argument srate")
end
if isempty(epochts)
    error("must pass in epochts or set glb('epochts')")
end

%% set up indv/depv

if ~isequal(isempty(indv), isempty(depv), ~isempty(opt.indv.vg), ~isempty(opt.depv.vg))
    error("indv and depv must both be empty or nonempty, with opt.indv and opt.depv the inverse")
end

if isempty(indv) && isempty(depv)
    dovget = 1;
else
    dovget = 0;
end

clear vget %clear persistent variables within vget (just in case)
its = 0;
while true
    its = its+1;

    if dovget %if indv/depv are defined in the options struct, instead of passed in as arguments
        [vdat, indv, depv] = vget(its, opt.indv, opt.depv);
        pthmdl = [vdat.pthc vdat.varid opt.optid '_mdl_.mat'];
        varid = vdat.varid;
        last = vdat.last;
    else
        varid = 'z0';
        id = idmake(pthstack);
        pthmdl = [id.pthstackdir varid opt.optid '_mdl_.mat'];
        last = 1;
    end

    mdl = mdlmake2(indv, depv, opt, varid, pthmdl, srate, epochts, doplt, numsyn, ldval, histinc);

    if last
        break
    end
end


end



function mdl = mdlmake2(indv, depv, opt, varid, pthmdl, srate, epochts, doplt, numsyn, ldval, histinc)


pthpre = erase(pthmdl, '.mat');

try

    mdl = load(pthmdl);
    if any(~isfield(mdl, {'ft', 'st', 'op', 'opt', 'varid', 'maketime_optfile_mdl'}))
        error("mdl struct must contain fields 'ft', 'st', 'op', 'maketime_optfile_mdl'; you may have loaded an old mdl struct")
    end
    if ~isequal(mdl.maketime_optfile_mdl, glb('maketime_mdl'))
        error("mdl id is derived from an optid file different from original")
    end

catch ME

    if isempty(indv) || isempty(depv)
        error("depv and indv must both be nonempty; vget did not find indv and/or depv")
    end
    if isempty(epochts)
        epochts = ones(1, size(depv, 2));
    end

    opt.hsv_background = "";

    if ~isa(indv, 'single') && ~isa(indv, 'double')
        indv = single(indv);
    end
    if ~isa(depv, 'single') && ~isa(depv, 'double')
        depv = single(depv);
    end

    if isvector(indv) && iscolumn(indv)
        indv = indv(:)';
    end

    [ mdl.num_dim_indvp, mdl.num_samp_indvp ] = size(indv);
    [ mdl.num_dim_depvp, mdl.num_samp_depvp ] = size(depv);

    if mdl.num_samp_indvp~=mdl.num_samp_depvp || ~ismatrix(depv) || ~ismatrix(indv)
        error("incorrectly sized input(s)")
    end

    %% prepare indv and depv

    mdl = mdl_varpr(mdl, indv, depv, opt, srate, pthpre, epochts);

    %% set up model params and optimization options

    mdl.op = mdl_optimpr(mdl.num_samp_mdl, mdl.num_dim_indv, mdl.num_dim_indvp, mdl.num_samp_data_train, opt, srate, mdl.st, pthpre);

    %% fit model to requested subset of indv/depv

    mdl = mdl_epochs(mdl, opt, pthpre, numsyn, ldval, histinc, doplt);

    %% save

    mdl.optid = opt.optid;
    mdl.varid = varid;
    mdl.maketime_optfile_mdl = glb('maketime_mdl');
    %save(pthmdl, '-struct', 'mdl', '-v7.3', '-mat')

end

%% plot

if doplt
    % mdl_plots(mdl, roidat, stack, opt, pthpre)
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

