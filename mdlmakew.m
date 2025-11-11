function [s, opt, vdat, mdl] = mdlmakew(indv, depv, s, vg, opt, opt2, opt3)

%{

wrapper function for mdlmake; see dqmake for docs; 
name-value arguments in struct opt (not vg or opt2) have no validation functions because they can be cells here, which get distributed in oid, 
each option set get output by oid is validated in mdlmake; any other name-value structs (eg, opt2) get validated here (and the same way in mdlmake)
name-value argument vg contains a struct for finding input variables to mdlmake; if variables are found they are assigned a varid; 
if vg.s is empty (default) mdlmake operates on input variable indv and depv

%}

arguments

    indv = []
    depv = []
    s = '' % if struct, s is the struct output from function smake (contains stack, md, pth, and other fields); if struct, pthsv (output mdl file path) is derived from s.pth (path to stack); if char, s is path to stack depv and indv are associated with; if empty, error

    vg.indv = [] %struct containing criteria for vget to find input argument indv (rather than using indv) 
    vg.depv = [] %struct containing criteria for vget to find input argument depv (rather than using depv) 

    opt.epochnum = 1;
    opt.lagsec = 0; %0 is one sample, how many samples indv precedes depv for model fit . . . for now, must be nonnegative integers, range 0 to lenfit_samp-1
    opt.lensec = 0; %model length in seconds, 0 is one sample
    opt.epochmix = 0; %1 to keep multi-timepoint model samples that have multiple epochs
    opt.valnum = 0; %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochnum is divisible by valnum, will validate on numbouts/valnum bouts for each epoch in epochnum; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
    opt.valsplit = 'boutsamples'; %'samples' or 'bouts' or 'boutsamples' %applied to all mdlnames; k in k-fold cross-validation; k non-overlapping validation sets; if numbouts of each epoch in epochnum is divisible by valnum, will validate on numbouts/valnum bouts for each epoch in epochnum; if only one bout for each epoch, will evenly split each bout into k validation sets; otherwise will error; 0 skips validation
    opt.slvrg = 'globalsearch';
    opt.slvrl = 'fmincon'; %'lsqcurvefit';
    opt.max_iter_global = 3; %this will not be assigned to globalsearch object du.opg; instead is used in output function for optimization problem, to stop optimization
    opt.mdlname = 'fnet_A01_s'; %'svd' or fnet string (see docs_mdlname.m)
    opt.rm = []; %options for removing samples
    opt.nrmi = []; %'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
    opt.nrmd = []; %'minmaxcnt'; %'minmax' range [0,1], 'minmaxcnt' range [-1,1], 'zscore' mean 0 unit var, 'none' . . . normalization used in fitting model but not all plotting . . . don't forget mse sensitive to scale
    opt.opl struct = []; %local solver options returned by oplmake(runtype=1), after converting to struct (ie without hidden options); empty to skip using local solver in mdlmake;
    opt.opg struct = []; %global solver options returned by opgmake(runtype=1), after converting to struct (ie without hidden options); empty to skip using global solver in mdlmake;

    opt2.srate = [] %sample rate in hz
    opt2.epochts = []
    opt2.ldval = 0 %load saved model if it exists
    opt2.numsyn = 0 %run numsyn synthetic data tests; test fits use model options in opt, and synthetic data with same bounds as input data after option-dependent processing); numsyn is number of synthetic responses to fit; [] or 0 to skip

    opt2.histinc = 0; %optimization iteration increment to save; 0 to skip saving optimization history
    opt2.doplt (1,1) {mustBeBinary} = 0 % 1 to make plots
    
    opt3.idx (1,1) {mustBeInteger, mustBePositive} = 1 %index of input option sets; leave blank if not looping over this wrapper
    opt3.runtype (1,1) {mustBeMember(opt3.runtype,0:3)} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments and return arguments block struct opt (not any other input arguments, since only opt are under id-control); 2 to do same as 1, then also run oid to derive optid and return opt (with newly derived optids); 3 to do same as 2, then also run vget to derive input variables' data struct and return as output

end

if opt3.runtype==1
    opt = oid(opt, 'mdl', noid=1); %for opt3.runtype==1, in oid noid=1, so just distribute and reduce option sets before validating 
    for k = 1:numel(opt)
        prs = struct2pairs(opt(k));
        [~, opt(k)] = mdlmake(prs{:}, runtype=1); %use arguments block in module to validate all name-value arguments in 'opt'
    end
    return
end

persistent idxout
if isempty(idxout) || opt3.idx==1 %idx input is not used except as flag to start or continue persistent variable counter idxout
    idxout = 0;
end

%%%% DERIVE optid (AND DISTRIBUTE ANY CELLS) %%%%

opt = oid(opt, 'mdl'); %assign ids to options sets
if opt3.runtype==2
    return
end


%%%% FIND indv/depv, IF REQUESTED %%%%

clear vget %clear persistent variables within vget
vdat = vget(vg.indv, vg.depv, runtype=2);

if opt3.runtype==3
    return
end

prs2 = struct2pairs(opt2);

for m = 1:numel(opt) %loop over options sets

    prs = struct2pairs(opt(m));

    for k = 1:numel(vdat) %loop over variable sets

        if ~isempty(vdat.dat) %if indv/depv are defined in the options struct and their do status is true
            [~, indv, depv] = vget(vdat=vdat(k), idx=k, err=1);
            s = vdat(k).pthc;
            prs2(end+1:end+2) = {'varid', vdat(k).varid}; %add possible nondefault varid to name-value argument cell (prs and prs2 would work)
        end

        idxout = idxout + 1;
        mdl(idxout) = mdlmake(indv, depv, s, prs{:}, prs2{:});

    end

end

if isstruct(s)
    s.mdl = mdl; %put the new data into s also, 
    matsv(s.pth, 'mdl', s=s) %save new data to s file 
end

end