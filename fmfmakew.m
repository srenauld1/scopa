function [s, opt, vdat, fmf] = fmfmakew(s, vg, opt, opt2, opt3)

%{

wrapper function for fmfmake; see fmfmake for docs; 
name-value arguments in struct opt (not vg or opt2) have no validation functions because they can be cells here, which get distributed in oid, 
each option set get output by oid is validated in fmfmake; any other name-value structs (eg, opt2) get validated here (and the same way in fmfmake)
name-value argument vg contains a struct for finding input variables to fmfmake; if variables are found they are assigned a varid; 
if vg.pthstack is empty (default) fmfmake operates on input variable pthstack (or interactively chosen path if pthstack is empty)

%}

arguments

    s = '' % if struct, s is the struct output from function smake (contains stack, md, pth, and other fields); if struct, pthsv (output fmf file path) is derived from s.pth (path to stack); if char, s is path to stack; if empty, error

    vg.pthstack = []; %struct containing criteria for vget to find input argument pthstack (rather than using pthstack) 
    
    opt.stimtype = 'drone';
    opt.id = 'CON_51';
    opt.crop_edges = 1;
    opt.rep = 1;
    opt.flipped = 0;
    opt.feat2 = '';
    
    opt2.pthpar = [];
    opt2.pthtemplate = [];
    opt2.getgrid = 1; %get the feature on a grid (phi theta if vistype is sphere, xy if gridtype is plane)
    opt2.vistype = 'plane'; %sphere, plane, or raw
    opt2.it = -100;
    opt2.gridres = 256;
    opt2.downsample_template = 1; %downsamples template, then uses it, rather than using template then downsampling; fine for most cases, just looks a little rougher
    opt2.pthgif = []
    opt2.doplt (1,1) {mustBeBinary} = 0 % 1 to make plots
    
    opt3.idx (1,1) {mustBeInteger, mustBePositive} = 1 %index of input option sets; leave blank if not looping over this wrapper
    opt3.runtype (1,1) {mustBeMember(opt3.runtype,0:3)} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments and return arguments block struct opt (not any other input arguments, since only opt are under id-control); 2 to do same as 1, then also run oid to derive optid and return opt (with newly derived optids); 3 to do same as 2, then also run vget to derive input variables' data struct and return as output

end

if opt3.runtype==1
    opt = oid(opt, 'fmf', noid=1); %for opt3.runtype==1, in oid noid=1, so just distribute and reduce option sets before validating 
    for k = 1:numel(opt)
        prs = struct2pairs(opt(k));
        [~, opt(k)] = fmfmake(prs{:}, runtype=1); %use arguments block in module to validate all name-value arguments in 'opt'
    end
    return
end

persistent idxout
if isempty(idxout) || opt3.idx==1 %idx input is not used except as flag to start or continue persistent variable counter idxout
    idxout = 0;
end

%%%% DERIVE optid (AND DISTRIBUTE ANY CELLS) %%%%

opt = oid(opt, 'fmf'); %assign ids to options sets
if opt3.runtype==2
    return
end


%%%% FIND pthstack, IF REQUESTED %%%%

clear vget %clear persistent variables within vget
vdat = vget(vg.pthstack, runtype=2);

if opt3.runtype==3
    return
end

prs2 = struct2pairs(opt2);

for m = 1:numel(opt) %loop over options sets

    prs = struct2pairs(opt(m));

    for k = 1:numel(vdat) %loop over variable sets

        if ~isempty(vdat.dat) %if pthstack is defined in options struct vg
            [~, s] = vget(vdat=vdat(k), idx=k, err=1);
            s = vdat(k).pthc;
            prs2(end+1:end+2) = {'varid', vdat(k).varid}; %add possible nondefault varid to name-value argument cell (prs and prs2 would work)
        end

        idxout = idxout + 1;
        fmf(idxout) = fmfmake(s, prs{:}, prs2{:});
        if ~isstruct(s)
            s = fmf(idxout).pth; %in case pthstack is empty and vg is empty, if looping, pthstack should be set to pthstack chosen within fmfmake (the tif, not the new mat, since we are looping over options we must want to create new mat from tif on each loop
        end

    end

end

if isstruct(s)
    s.fmf = fmf; %put the new data into s also, 
    matsv(s.pth, 'fmf', s=s) %save new data to s file 
end

end