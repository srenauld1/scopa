function mdl = mdlmake(indvp, depvp, imrate, pthstack, optid, opt, epochts, doplt)

% for docs, see file mdl_notes.m

% indvp and depvp are independent and dependent variables before processing
% the unintuitive thing that needs to be changed is that depvp first dimension is the number of dependent variables (model is fit to vector dependent variables, looping over first dim),
% while for indvp, the whole array input to mdlmake is the independent variable . . . need to check if there's a goodreason for this or whether tsget should output vector depvp (and input them to this function mdlmake)

% indvp
% depvp
% mdl.num_dim_indvp
% mdl.num_samp_indvp
% mdl.num_dim_depvp
% mdl.num_samp_depvp
% mdl.pthpre

% mdl_prepvars adds to mdl struct with prepared vars and also outputs mdl.stats
% mdl_setup output mdl.op with model options, and mdl.op.supp with model params
% mdl_epochs output mdl.fit with fit info
%   within mdl_epochs is mdl_fit with the actual fit


arguments
    indvp
    depvp
    imrate
    pthstack
    optid
    opt
    epochts = []
    doplt = []
end


%% check some inputs and prepare save path

pthpre = [erase(pthstack, '.mat') optid '_mdl_'];
pthmdl = [pthpre '.mat'];

if isempty(epochts)
    epochts = ones(1, size(depvp, 2));
end
if isempty(doplt)
    doplt = any(strcmp('mdl', glb('plt')));
end

mdl.vars.indvp = indvp; 
indvp = [];
mdl.vars.depvp = depvp; 
depvp = [];

opt.hsv_background = "";

if ~iscell(opt.epochnum)
    opt.epochnum = {opt.epochnum};
end

if isvector(mdl.vars.indvp) & iscolumn(mdl.vars.indvp)
    mdl.vars.indvp = mdl.vars.indvp(:)';
end

[ mdl.num_dim_indvp, mdl.num_samp_indvp ] = size(mdl.vars.indvp);
[ mdl.num_dim_depvp, mdl.num_samp_depvp ] = size(mdl.vars.depvp);

if mdl.num_samp_indvp~=mdl.num_samp_depvp | ndims(mdl.vars.depvp)~=2 | ndims(mdl.vars.indvp)~=2
    error("incorrectly sized input(s)")
end

%% prepare indv and depv

mdl = mdl_prepvars(mdl, opt, imrate, pthpre, epochts);

%% set up model fitting and plotting options

mdl.op = mdl_setup(mdl.num_samp_mdl, mdl.num_dim_indv, mdl.num_dim_indvp, opt, imrate, mdl.stats, pthpre);

%% loop over epochnum, fitting model to each (fit to different requested subsets of indv/depv)

for epi = 1:length(opt.epochnum) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv
    mdl = mdl_epochs(mdl, opt, epi, pthpre);
end

% if doplt
%     mdl_plots(mdl, roidat, stack, opt, pthpre)
% end

