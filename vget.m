function [datout, tsout] = vget(its, vg, opt)

% find variable(s)
% takes input options, finds their optid(s) in their opt files, finds files with those optid, loads variables from those files, assembles them according to input options, tags variable set with its own id (varid) and writes that id to opt_var file

%var subfield should not just have vg options used when creating the first variable, since the vars it returns may not be the same every time (changes to filesystem); so var must refer to specific variable files

arguments (Input)
    its %index of found variable combos; [] or 'all' for all; otherwise, scalar number
end
arguments (Repeating, Input)
    vg
end
arguments (Input)
    opt.unpack = 1 %output timeseries not in cell, only works when
    opt.dm = [] %dim order of timeseries to be found; used to apply indices
    opt.pthpar = []
    opt.usegit {mustBeMember(opt.usegit,[0,1])} = [] % use git to sync file pth across filesystems (to prevent conflicting changes)
    opt.obin_ided = []
end
arguments (Output)
    datout
end
arguments (Repeating, Output)
    tsout
end

dm = opt.dm;
pthpar = opt.pthpar;
usegit = opt.usegit;
obin_ided = opt.obin_ided;

usegit = optorglb(usegit, 0);
if ~ismember(usegit, [0,1])
    error("usegit must be 0 or 1")
end

scopausername = userdatfile('scopausername');

numvarin = numel(vg); %number of independent output variables (number of nonempty input arguments to vget)
tsout = cell(1, numvarin);
persistent dattmp
persistent tsouttmp


if isempty(dm)
    dm = 'it';
end
if isempty(pthpar)
    error("you must pass in pthpar or set glb('pthpar')")
end
if isempty(obin_ided)
    error("obin_ided are not defined in glb, using default defined in vget, but you should define them in glb")
end
if isstring(obin_ided)
    obin_ided = convertStringsToChars(obin_ided);
end

pthscopa = pthscopaget();
pthvar = [pthscopa 'opt_var_' scopausername '_.txt'];

if isempty(dattmp) && isempty(tsouttmp) %reset counter if vget is called from a different location, or a2p starttime has changed

    dattmp_hold = cell(numvarin,1); %use hold tmp variable, don't assign variable until end of this if clause 
    tsouttmp_hold = cell(numvarin,1);  %use hold tmp variable, don't assign variable until end of this if clause 

    for m = 1:numvarin %loop over number of repeated vg inputs
        if ~isempty(vg{m})
            [tsouttmp_hold{m}, dattmp_hold{m}] = vget2(vg{m}, dm, pthpar, scopausername, pthscopa, obin_ided, usegit);
        end
    end

    datflat = cellflat(dattmp_hold);
    datflat = [datflat{:}];
    cnt = 0;
    for k = 1:numel(datflat)
        if ~isempty(datflat(k))
            cnt = cnt+1;
            md = mdsild(datflat(k).pth);
            if cnt==1
                vrtmp = md.volrate;
                eptmp = glb('epochts');
            else
                if ~isequal(vrtmp, md.volrate) || ~isequal(eptmp, glb('epochts'))
                    error("metadata does not agree across found ts, need to write how to deal with this")
                end
            end
        end
    end

    tsouttmp = tsouttmp_hold;
    dattmp = dattmp_hold;

end

%%% SELECT FROM FOUND VARIABLES (PERSISTENT) USING INDEX OF ITS FROM ALL COMBOS %%%% 
last = 0;
if any(~cellfun(@isempty, cellflat(tsouttmp))) %if any are nonempty

    % if any(cellfun(@isempty, cellflat(tsouttmp))) %if any are empty
    %     error("for all vg input, output must be empty or not") <----this is no longer always required 
    % end

    if numvarin==1
        iv = 1;
    elseif numvarin==2
        if isempty(tsouttmp{1})
            [ivc,ivr] = meshgrid(1, 1:numel(tsouttmp{2}));
        elseif isempty(tsouttmp{2})
            [ivc,ivr] = meshgrid(1:numel(tsouttmp{1}), 1);
        else
            [ivc,ivr] = meshgrid(1:numel(tsouttmp{1}), 1:numel(tsouttmp{2}));
        end
        iv = [ivc(:) ivr(:)];
    else
        error("write this for more than 2 vg inputs")
    end

    if its>size(iv,1)
        error("requested index is too great")
    end

    kcnt = 0;
    for k = 1:size(iv,1) %loop over var combos
        if isempty(its) || isequal(k, its)
            kcnt = kcnt + 1;

            if isequal(k, size(iv,1)) %if on final var combo
                last = 1;
            end

            cnt = 0;
            for m = 1:numel(tsouttmp) %loop over number vars in combo, previously was 1:size(iv,2)
                if ~isempty(tsouttmp{m})
                    tsout{m,kcnt} = tsouttmp{m}{iv(k,m)};
                    cnt = cnt+1;
                    if cnt==1 %when writing datcombo, just omit empty (rather than writing an empty)
                        datcombo = dattmp{m}{iv(k,cnt)};
                    else
                        newinds = cnt:cnt+numel(dattmp{m}{iv(k,cnt)})-1;
                        datcombo(newinds) = dattmp{m}{iv(k,cnt)};
                    end
                else
                    tsout{m,kcnt} = [];
                end
            end

            [~, varid] = structfile(pthvar, s=datcombo, usegit=usegit, dupe=0, dosort=1);
            if size(iv,2)==1
                pthc = datcombo.pth;
            else
                pthc = {datcombo.pth};
                pthc = intersectchar(pthc);
            end
            pthc = fileparts(pthc); %crop to nearest folder
            if ~endsWith(pthc, filesep)
                pthc = [pthc filesep];
            end
            datout(kcnt).vdat = datcombo;
            datout(kcnt).varid = varid;
            datout(kcnt).pthc = pthc;
            datout(kcnt).last = last;
        end

    end

else %if all empty

    tsout = {};
    datout.vdat = [];
    datout.varid = [];
    datout.pthc = [];
    datout.last = 1;

end



end

function [tsout, dat] = vget2(vg, dm, pthpar, scopausername, pthscopa, obin_ided, usegit)

if isstruct(vg) && all(startsWith(fieldnames(vg), 'vg')) && isscalar(vg)
    vg = vg.vg; %since the input to this function is also named vg
else
    error("each input to vget must be scalar struct containing field vg, and nothing else")
end

numvg = numel(vg); %number of separate structs used to find variables (all results will be concatenated)
tsout = cell(numvg,1);
dattmp = cell(numvg,1);
group = cell(numvg,1);
for m = 1:numvg %loop over vg elements
    [tsout{m}, dattmp{m}, group{m}] = vget3(vg(m), dm, pthpar, scopausername, pthscopa, obin_ided, usegit);
end


if all(cellfun(@isempty, cellflat(tsout))) %isempty(cell2mat(vec(cellflat(tsout))))
    group2 = '1';
else
    if isempty(getfieldns(vg, 'group2'))
        tmp = group;
        if ~isempty(tmp)
            tmp = unique(tmp(~cellfun(@isempty, tmp)));
        end
        if isscalar(tmp)
            group2 = tmp{1};
            fprintf("group2 is empty, setting default group2 to " + tmp{1} + " since this is the nonempty value of group for all elements of vg" + newline)
        else
            group2 = '3';
            fprintf("group2 is empty, and not all elements use the same value for groupsetting default group2 '3', nothing will be grouped at the outer level" + newline)
        end
    else
        tmp = getfieldns(vg, 'group2');
        tmp = unique(tmp(~cellfun(@isempty, tmp)));
        if isscalar(tmp)
            group2 = tmp{1};
        else
            error("group2 must be equal (or empty) for all elements of vg")
        end
    end
end

tstmp = vec(cellflat(tsout));
tstmp = cellfun(@single, tstmp, 'UniformOutput', false);


dat = [];
switch group2
    case '1'
        for k = 1:numel(dattmp)
            dat = cat(2, dat, dattmp{k});
        end
        dat = {dat};
        tsout = {cell2mat(tstmp)};
    case '3'
        cnt = 0;
        for k = 1:numel(dattmp)
            for m = 1:numel(dattmp{k})
                cnt = cnt+1;
                dat{cnt} = dattmp{k}(m);
            end
        end
        tsout = num2cell(cell2mat(tstmp), 2);
    case 'flat'
        for k = 1:numel(dattmp)
            dat = cat(2, dat, dattmp{k});
        end
        dat = {dat};
        tsout = {transpose(cell2vec(tstmp))}; %make it row vector, so time is 2nd dim
    otherwise
        error("group2 must be 1, 3, or flat")
end

end


function [tsout, dat, group] = vget3(vg, dm, pthpar, scopausername, pthscopa, obin_ided, usegit)


if isfield(vg, 'optid') && ~isempty(vg.optid)
    optid = vg.optid;
    if isstring(optid)
        optid = convertStringsToChars(optid);
    end
    if ~iscell(optid)
        optid = {optid};
    end
else
    optid = {};
end
optid = transpose(optid(:));

if isfield(vg, 'varid') && ~isempty(vg.varid)
    varid = vg.varid;
    if isstring(varid)
        varid = convertStringsToChars(varid);
    end
    if ~iscell(varid)
        varid = {varid};
    end
else
    varid = {};
end
varid = transpose(varid(:));

if isfield(vg, 'vnm') && ~isempty(vg.vnm)
    vnm = vg.vnm;
    if isstring(vnm)
        vnm = convertStringsToChars(vnm);
    end
    if ~iscell(vnm)
        vnm = {vnm};
    end
else
    vnm = {};
end
vnm = transpose(vnm(:));

if isfield(vg, 'ii') && ~isempty(vg.ii)
    ii = vg.ii;
else
    ii = [];
end

if isfield(vg, 'it') && ~isempty(vg.it)
    it = vg.it;
else
    it = [];
end

if isfield(vg, 'ic') && ~isempty(vg.ic)
    ic = vg.ic;
else
    ic = [];
end

if isfield(vg, 'recid') && ~isempty(vg.recid)
    recid = vg.recid;
    if isstring(recid)
        recid = convertStringsToChars(recid);
    end
    if ~iscell(recid)
        recid = {recid};
    end
else
    recid = {'curr'};
end

if isfield(vg, 'group') && ~isempty(vg.group)
    group = vg.group;
else
    fprintf("group is empty, setting default group '3', all found variables will be considered separate" + newline)
    group = '3';
end

if isfield(vg, 'group2') && ~isempty(vg.group2)
    group2 = vg.group2;
else
    fprintf("group2 is empty, leaving empty for now, to be set in vget, outside vget3" + newline)
    group2 = [];
end

if ~isscalar(vg)
    error("INPUT STRUCT TO vget MUST BE SCALAR")
end

if strcmp(recid, 'curr')
    recid = {glb('recid')};
end




nonemptyinds = [];
obin_ided_in_vg = obin_ided(isfield(vg, obin_ided));
for k = 1:numel(obin_ided_in_vg)
    if ~isempty(vg.(obin_ided_in_vg{k}))
        nonemptyinds = [nonemptyinds k];
    end
end

if isscalar(obin_ided_in_vg)
    obin = cell2mat(obin_ided_in_vg(1));
elseif numel(obin_ided_in_vg)>1
    if isscalar(nonemptyinds)
        obin = cell2mat(obin_ided_in_vg(nonemptyinds));
    else
        error("obin can be empty if there is only one; if there are multiple, they must all be empty except one")
    end
elseif isempty(obin_ided_in_vg)
    error("there are no obin in vg")
end

if isequal(vg.(obin), '*')
    vg.(obin) = []; %now that you've distinguished the obin from other potentially empty obin, you can set it to empty if it was star, since star is meant to be empty
end


if isempty(cell2mat(optid))
    vgopt.(obin) = vg.(obin);
    if isempty(vgopt.(obin))
        vgopt = [];
    end
    try
        vgopt = ofill(vgopt, obin, rec=1, wild=1); %make sure any unspecified option gets wildcard (rather than default value)
    catch ME
        error("you must have made an invalid options struct for vget (vg) because ofill failed with this message: " + ME.message + newline);
    end
    vgopt = oid(vgopt, getonly=1, usegit=usegit);
    if ~isempty(vgopt.(obin))
        optid = transpose(fieldnames(vgopt.(obin))); %make it row vector, although here i don't think it matters
    else
        fprintf("no variable found" + newline)
    end
else
    if ~isempty(vg.(obin))
        error("obin substruct and optid cannot both exist in vg")
    end
end



if isfield(vg, 'var')
    if isempty(cell2mat(varid))
        pthvarpat = [pthscopa 'opt_var_' scopausername '_.txt'];
        [~, varid] = structfile(pthvarpat, s=svar, nm=varid, usegit=usegit, dupe=0, dosort=1);
    else
        error("var substruct and varid cannot both exist in vg")
    end
else
    varid = {''};
end


tsout = {};
dattmp = {};
cnt = 0;
for w = 1:numel(varid)
    varid_tmp = varid{w};
    for k = 1:numel(optid)
        optid_tmp = optid{k};
        fnpat = ['*' varid_tmp optid_tmp '_' obin '_.mat'];
        pthpat = fullfile(pthpar, '**', fnpat);
        pthtmpall = rdir(pthpat);
        pthtmp = cell(numel(pthtmpall),1);
        for m = 1:numel(pthtmpall)
            [~, fntmp, fnext] = fileparts(pthtmpall(m).name);
            fnpat2 = regexprep(strcat(regexprep(strcat('^', recid), '*', '\\d*'), fnpat, '$'), '*', '.*');
            if any(cellfun(@(x) isequal(x,1), regexp([fntmp, fnext], fnpat2))) %filter by recid
                pthtmp{m} = pthtmpall(m).name;
            end
        end
        pthtmp = pthtmp(~cellfun(@isempty, pthtmp));
        if isempty(cell2mat(pthtmp))
            fprintf("WARNING, optid '" + optid_tmp + "' was matched but there is no corresponding data file for domain '" + obin + "'; you may have created it and then deleted it; skipping this optid" + newline)
        else
            if numel(pthtmp)>1
                error("there are multiple files with matched optid and domain, you may have created them from different versions of the same stack (or, od, etc); need to make this fixible; for now just rename one" + newline)
            end
            pth = pthtmp{1}; %there should only be one here
            fprintf("loading data file for domain '" + obin + "', optid '" + optid_tmp + "'" + newline)
            saved_struct = load(pth);
            if isfield(saved_struct, obin)
                saved_struct = saved_struct.(obin);
                fprintf("saved variable was not saved as struct (maybe it was nonscalar), so indexing into with with obin" + newline)
            end
            if isempty(cell2mat(vnm))
                vnm = transpose(fieldnames(saved_struct)); % all variables if vnm is empty
            end

            for f = vnm
                try
                    saved_var = saved_struct.(f{1});
                catch
                    saved_var = saved_struct.dat.(f{1});
                end
                if isempty(saved_var)
                    error("you are trying to load an empty variable; if this is domain 'roi', you may intend these to be pixel rois, which are not created separately from the stack; need to write this option here, where if domain is roi, we load or point to a spacetime reshaped stack")
                end

                if iscell(saved_var)
                    if isempty(ic)
                        ic = find(~cellfun(@isempty, saved_var)); %if ic isempty, load ts for all nonempty channels
                    end
                    for q = 1:numel(ic)
                        cnt = cnt+1;
                        tsout{cnt} = stackind(saved_var{ic(q)}, dm=dm, ii=ii, it=it);
                        dattmp{cnt} = vgdatmake(pth, optid_tmp, f, ii, it, ic, group, group2);
                    end
                else
                    if isempty(ic)
                        cnt = cnt+1;
                        tsout{cnt} = stackind(saved_var, dm=dm, ii=ii, it=it);
                        dattmp{cnt} = vgdatmake(pth, optid_tmp, f, ii, it, ic, group, group2);
                    else
                        error("ic is not valid for indexing anything but cell array right now")
                    end
                end

            end
        end
    end
end

szt = cellfun(@(x) size(x,2), tsout, 'UniformOutput', false);
if numel(szt)>1 && ~isequal(szt{:}) && any(strcmp(group, {'1','3'}))
    error("all tsout must be same size in time dimension if group is 1 or 3")
end

dat = [];
if ~isempty(szt)
    switch group
        case '1'
            for k = 1:numel(dattmp)
                dat = cat(2, dat, dattmp{k});
            end
            tsout = {cell2mat(tsout(:))};
        case '3'
            for k = 1:numel(dattmp)
                dattmp2 = repelem(dattmp{k}, size(tsout{k},1));
                for m = 1:numel(dattmp2)
                    if isempty(dattmp2(m).ii)
                        dattmp2(m).ii = m;
                    else
                        dattmp2(m).ii = dattmp2(m).ii(m);
                    end
                end
                dat = cat(2, dat, dattmp2);
            end
            tsout = num2cell(cell2mat(tsout(:)), 2);
        case 'flat'
            for k = 1:numel(dattmp)
                dat = cat(2, dat, dattmp{k});
            end
            tsout = {transpose(cell2vec(tsout))}; %make it row vector, so time is 2nd dim
        otherwise
            error("group must be 1, 3, or flat")
    end
end

end



function dat = vgdatmake(pth, optid, f, ii, it, ic, group, group2)

dat.pth = pth;
dat.optid = optid;
dat.vnm = f{1};
dat.ii = ii;
dat.it = it;
dat.ic = ic;
dat.group = group;
dat.group2 = group2;

end

%{

these docs are a bit outdated

each domain has a different set of available timeseries 
    roi: ts
    mdl: pred
    bmp: respcl, mu, rho, ampmean, amppeak, ampmu, vel, offset
    fmf: every feature id (like CON_51)
    daq: t, bf, bvf, bs, bvs, by, bvy, vh, vvy, vvynom

vget recovers timeseries from saved files, using the options used to create the timeseries, or various identifiers  



    domain
        domain is char array, must exist in ts
        empty returns all
        
    optused 
        optused is a struct containing a subset of the options used to create timeseries, or just the optid assigned to an options set
        since all unique options sets have an optid, optused.optid is sufficient to recover timeseries 
        optused.optid is a char array, which can contain asterisk as wildcard
        for more control, or if you don't know the optid, pass in individual options in optused (in this case you cannot pass in optid)
        optused must be valid given the domain argument
        if any optused are cell arrays, they are expanded and all results are found 
        empty returns all for the given domain

    name
        name is a numeric scalar or vector, or empty vector
        name must be valid given the domain and optused arguments
        empty vector returns all for the given domain and optused

    group
        group determines how output timeseries are arrayed in the 3rd dimension 
        the 3rd dimenion is the looping dimension in all functions that use vget (eg mdlmake loops over 3rd dim to fit seperate models with the same options but different timeseries, pltx loops over the 3rd dimension to present groups of variables, fmf loops over 3rd dim to extract features from different sets of timeseries)
        group can take the following values: 'all', 'domain', 'optused', 'name', 
        these refer to vget input arguments, which can each be expanded to return multiple timeseries; 
        group determines whether output should be group according to that expansion; 
            all: like the inverse of 'name'; output 1st dimension length matches number of found timeseries and 3rd dimension is singleton; 
            domain: array domain groups along 3rd dimension 
            optused: array optused groups along 3rd dimension 
            name: like the invserse of 'all'; output 3rd dimension length matches number of found timeseries, and 1st dimension is singleton; 

%}
