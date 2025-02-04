function fitin = mdlmake(indvp, depvp, imrate, fitopt, doplt, pthpre, epochts, stack, roidat)

% for docs, see file mfit_notes.m

% indvp and depvp are independent and dependent variables before processing
% the unintuitive thing that needs to be changed is that depvp first dimension is the number of dependent variables (model is fit to vector dependent variables, looping over first dim),
% while for indvp, the whole array input to mdlmake is the independent variable . . . need to check if there's a goodreason for this or whether tsget should output vector depvp (and input them to this function mdlmake)

% indvp
% depvp
% fitin.num_dim_indvp
% fitin.num_samp_indvp
% fitin.num_dim_depvp
% fitin.num_samp_depvp
% fitin.pthpre

% mfit_prepvars adds to fitin struct with prepared vars and also outputs fitin.stats
% mfit_setup output fitin.op with model options, and fitin.op.supp with model params
% mfit_epochs output fitin.fit with fit info
%   within mfit_epochs is mfit_fit with the actual fit


arguments
    indvp
    depvp
    imrate
    fitopt
    doplt = 0
    pthpre = []
    epochts = []
    stack = []
    roidat = []
end

%% check some inputs and prepare save path

fitin.vars.indvp = indvp; indvp = [];
fitin.vars.depvp = depvp; depvp = [];

fitopt.hsv_background = "";

if ~iscell(fitopt.epochnum)
    fitopt.epochnum = {fitopt.epochnum};
end

if isvector(fitin.vars.indvp) & iscolumn(fitin.vars.indvp)
    fitin.vars.indvp = fitin.vars.indvp(:)';
end

[ fitin.num_dim_indvp, fitin.num_samp_indvp ] = size(fitin.vars.indvp);
[ fitin.num_dim_depvp, fitin.num_samp_depvp ] = size(fitin.vars.depvp);

if fitin.num_samp_indvp~=fitin.num_samp_depvp | ndims(fitin.vars.depvp)~=2 | ndims(fitin.vars.indvp)~=2
    error("incorrectly sized input(s)")
end


fitin.pthpre = pthpre;
pth_fitdata_prefix = [fitin.pthpre  '_' fitopt.mdlname '_' num2str(fitopt.mdl_length_sec) '_' num2str(fitopt.mdl_lag_sec)];
pth_fitdata_prefix = strrep(pth_fitdata_prefix, '.', 'p');

%% prepare indv and depv

fitin = mfit_prepvars(fitin, fitopt, imrate, pth_fitdata_prefix, epochts);

%% set up model fitting and plotting options

fitin.op = mfit_setup(fitin.num_samp_mdl, fitin.num_dim_indv, fitin.num_dim_indvp, fitopt, imrate, fitin.stats, pth_fitdata_prefix);

%% loop over epochnum, fitting model to each (fit to different requested subsets of indv/depv)

for epi = 1:length(fitopt.epochnum) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv
    fitin = mfit_epochs(fitin, fitopt, epi, pth_fitdata_prefix);
end

if doplt
    mfit_plots(fitin, roidat, stack, fitopt, pth_fitdata_prefix)
end

