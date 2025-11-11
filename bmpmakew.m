function [s, opt, vdat, bmp] = bmpmakew(indv, depv, s, vg, opt, opt2, opt3)

%{

wrapper function for bmpmake; see dqmake for docs; 
name-value arguments in struct opt (not vg or opt2) have no validation functions because they can be cells here, which get distributed in oid, 
each option set get output by oid is validated in bmpmake; any other name-value structs (eg, opt2) get validated here (and the same way in bmpmake)
name-value argument vg contains a struct for finding input variables to bmpmake; if variables are found they are assigned a varid; 
if vg.s is empty (default) bmpmake operates on input variable indv and depv

%}

arguments

    indv = []
    depv = []
    s = '' % if struct, s is the struct output from function smake (contains stack, md, pth, and other fields); if struct, pthsv (output bmp file path) is derived from s.pth (path to stack); if char, s is path to stack depv and indv are associated with; if empty, error

    vg.indv = [] %struct containing criteria for vget to find input argument indv (rather than using indv) 
    vg.depv = [] %struct containing criteria for vget to find input argument depv (rather than using depv) 

    opt.domtype = 'm' %'f' (functional) to define circular domain with fit to each roi, or 'm' (morphological) to define as circle across region mask
    opt.numcirc = 1 %number of circles (eg 1 for eb, 2 for pb), if pb, always use 2 because you can subset with argument 'scope' below
    opt.mthd = 'pva' %'pva' for vector average, pvas for signed vector average, vm for fit von mises to activity across all roi at each sample
    opt.scope = 'all' %which part of compass to use in computing bump parameters, using anything but 'all' doesn't make much sense uunless you have a 2-circle structure, like pb; cell array of char, 'all', 'right', 'left', 'max', 'random', or a digits (numeric or text) denoting left half percentage weight (right will be 100-left)
    opt.dvord = 2 %order of polynomial used to fit sliding window slope (to compute bump speed)
    opt.dvlensec = 0.4 %length of window (in seconds) used to fit sliding window slope (to compute bump speed); rounded to nearest sample
    opt.smlensec = 0 %full width of gaussian smoothing window (5 times std)
    opt.numangrs = 16 %how many clusters/superrois across the entire region (not hemisphere) when resampled uniformly prior to computing bump as vector average
    opt.maxangrs = 8 %max number resolvable ("unaliased") angles in resampled output (ie 1/maxangrs) is highest frequency you wish to capture in output)opt.smfac = 1; %when resampling compass, bandwidth of the antialiasing filter, larger number will have smoother resampled compass
    opt.dorescale = 0 %just before computing bump, rescale each cluster's timeseries to range 0-1
    opt.omitnan = 1 %ignore nans in case there are any (e.g., making hybrid morph-func rois, some morph rois have no func members, making their response 'nan', omit will ignore this in computing pva)
    opt.mdl = [] %mdlmake options returned by mdlmake(runtype=1); empty to skip mdlmake from within bmpmake; fits models to input timeseries to find each roi's preferred head direction

    opt2.srate = []
    opt2.epochts = []
    opt2.doplt (1,1) {mustBeBinary} = 0 % 1 to make plots
    
    opt3.idx (1,1) {mustBeInteger, mustBePositive} = 1 %index of input option sets; leave blank if not looping over this wrapper
    opt3.runtype (1,1) {mustBeMember(opt3.runtype,0:3)} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments and return arguments block struct opt (not any other input arguments, since only opt are under id-control); 2 to do same as 1, then also run oid to derive optid and return opt (with newly derived optids); 3 to do same as 2, then also run vget to derive input variables' data struct and return as output

end

if opt3.runtype==1
    opt = oid(opt, 'bmp', noid=1); %for opt3.runtype==1, in oid noid=1, so just distribute and reduce option sets before validating 
    for k = 1:numel(opt)
        prs = struct2pairs(opt(k));
        [~, opt(k)] = bmpmake(prs{:}, runtype=1); %use arguments block in module to validate all name-value arguments in 'opt'
    end
    return
end

persistent idxout
if isempty(idxout) || opt3.idx==1 %idx input is not used except as flag to start or continue persistent variable counter idxout
    idxout = 0;
end

%%%% DERIVE optid (AND DISTRIBUTE ANY CELLS) %%%%

opt = oid(opt, 'bmp'); %assign ids to options sets
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
        bmp(idxout) = bmpmake(indv, depv, s, prs{:}, prs2{:});

    end

end

if isstruct(s)
    s.bmp = bmp; %put the new data into s also, 
    matsv(s.pth, 'bmp', s=s) %save new data to s file 
end

end