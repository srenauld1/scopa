function [datout, varout] = vget(vopt, opt)

% find variable(s)
% takes input options, finds their optid(s) in their opt files, finds files with those optid, loads variables from those files, assembles them according to input options, tags variable set with idx own id (varid) and writes that id to opt_var file

%var subfield should not just have vg options used when creating the first variable, since the vars it returns may not be the same every time (changes to filesystem); so var must refer to specific variable files

arguments (Repeating, Input)
    vopt struct
end
arguments (Input)
    opt.idx (1,1) {mustBeInteger, mustBeNonnegative} = 0 %index of found variable combos; 0 for all, otherwise, scalar number
    opt.dat struct = [] %struct holding info about found variables
    opt.unpack (1,1) {mustBeBinary} = 1 %remove varout from cell (only allowed if each varout is scalar)
    opt.usegit {mustBeScalarOrEmpty, mustBeBinary(opt.usegit,'emptyok')} = [] % use git to sync file pth across filesystems (to prevent conflicting changes)
    opt.runtype (1,1) {mustBeMember(opt.runtype,0:2)} = 0 %runtype controls how much of this function to run; 0 to run entire function; 1 to do nothing but validate input arguments (output arguments are all empty; for this function, input arguments are not returned when runtype=1); 2 to do same as 1, then also derive and return datout only (skips loading, indexing, grouping found variables)
    opt.err (1,1) {mustBeBinary} = 0 %1 to error if no variables found
end
arguments (Output)
    datout struct
end
arguments (Repeating, Output)
    varout
end

persistent dattmp
persistent varouttmp

idx = opt.idx;
dat = opt.dat;
unpack = opt.unpack;
usegit = opt.usegit;
err = opt.err;
runtype = opt.runtype;

usegit = optorglb(usegit, 0);
mustBeBinary(usegit)

pthpar = userdatfile('pthpar', err=1);
scopausername = userdatfile('scopausername', err=1);
pthscopa = pthscopaget();

pthvar = [pthscopa 'opt_var_' scopausername '_.txt'];

numvarin = numel(vopt); %number of independent output variables (number of nonempty input arguments to vget)
varout = cell(1, numvarin);

if isempty(dattmp) && isempty(varouttmp) %reset counter if vget is called from a different location, or a2p starttime has changed

    dattmp_hold = cell(numvarin,1); %use hold tmp variable, don't assign variable until end of this if clause 
    varouttmp_hold = cell(numvarin,1);  %use hold tmp variable, don't assign variable until end of this if clause 

    for m = 1:numvarin %loop over number of repeated vopt inputs
        if ~isempty(vopt{m})
            [varouttmp_hold{m}, dattmp_hold{m}] = vget2(vopt{m}, pthpar, scopausername, pthscopa, usegit, runtype);
        end
    end

    
    % datflat = cellflat(dattmp_hold);
    % datflat = [datflat{:}];
    % cnt = 0;
    % for k = 1:numel(datflat)
    %     if ~isempty(datflat(k))
    %         cnt = cnt+1;
    %         md = mdsild(datflat(k).pth);
    %         if cnt==1
    %             vrtmp = md.volrate;
    %             eptmp = glb('epochts');
    %         else
    %             if ~isequal(vrtmp, md.volrate) || ~isequal(eptmp, glb('epochts'))
    %                 error("metadata does not agree across found ts, need to write how to deal with this")
    %             end
    %         end
    %     end
    % end

    varouttmp = varouttmp_hold;
    dattmp = dattmp_hold;

end

%%% SELECT FROM FOUND VARIABLES (PERSISTENT) USING INDEX OF idx FROM ALL COMBOS %%%% 

if any(~cellfun(@isempty, cellflat(varouttmp))) %if any are nonempty

    % if any(cellfun(@isempty, cellflat(varouttmp))) %if any are empty
    %     error("for all vopt input, output must be empty or not") <----this is no longer always required 
    % end

    if numvarin==1
        iv = 1;
    elseif numvarin==2
        if isempty(varouttmp{1})
            [ivc,ivr] = meshgrid(1, 1:numel(varouttmp{2}));
        elseif isempty(varouttmp{2})
            [ivc,ivr] = meshgrid(1:numel(varouttmp{1}), 1);
        else
            [ivc,ivr] = meshgrid(1:numel(varouttmp{1}), 1:numel(varouttmp{2}));
        end
        iv = [ivc(:) ivr(:)];
    else
        error("write this for more than 2 vopt inputs")
    end

    if idx>size(iv,1)
        error("requested index is too great")
    end

    kcnt = 0;
    for k = 1:size(iv,1) %loop over var combos
        if isempty(idx) || isequal(k, idx)
            kcnt = kcnt + 1;

            cnt = 0;
            for m = 1:numel(varouttmp) %loop over number vars in combo, previously was 1:size(iv,2)
                if ~isempty(varouttmp{m})
                    varout{m,kcnt} = varouttmp{m}{iv(k,m)};
                    cnt = cnt+1;
                    if cnt==1 %when writing datcombo, just omit empty (rather than writing an empty)
                        datcombo = dattmp{m}{iv(k,cnt)};
                    else
                        newinds = cnt:cnt+numel(dattmp{m}{iv(k,cnt)})-1;
                        datcombo(newinds) = dattmp{m}{iv(k,cnt)};
                    end
                else
                    varout{m,kcnt} = [];
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
            datout(kcnt).dat = datcombo;
            datout(kcnt).varid = varid;
            datout(kcnt).pthc = pthc;
        end

    end

else %if all empty

    if err
        error("no variables found and err=1; if you don't want to error when no variables are found, make err=0")
    end
    varout = {};
    datout.dat = [];
    datout.varid = [];
    datout.pthc = [];

end


end

function [varout, dat] = vget2(vopt, pthpar, scopausername, pthscopa, usegit, runtype)

if isstruct(vopt) && all(startsWith(fieldnames(vopt), glbfile('fnvget'))) && isscalar(vopt)
    vg = vopt.vg; %since the input to this function is also named vg
else
    error("each positional argument to vget must be a scalar struct containing field vg, and nothing else")
end

numvg = numel(vg); %number of separate structs used to find variables (all results will be concatenated)
varout = cell(numvg,1);
dattmp = cell(numvg,1);
group = cell(numvg,1);
for m = 1:numvg %loop over vg elements
    prs = struct2pairs(vg(m));
    [varout{m}, dattmp{m}, group{m}] = vget3(pthpar, scopausername, pthscopa, usegit, runtype, prs{:});
end


if all(cellfun(@isempty, cellflat(varout))) %isempty(cell2mat(vec(cellflat(varout))))
    group2 = 1;
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
            group2 = 3;
            fprintf("group2 is empty, and not all elements use the same value for group; setting default group2 to 3, so nothing will be grouped at the outer level" + newline)
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

tstmp = vec(cellflat(varout));
tstmp = cellfun(@single, tstmp, 'UniformOutput', false);


dat = [];
switch group2
    case 0
        for k = 1:numel(dattmp)
            dat = cat(2, dat, dattmp{k});
        end
        dat = {dat};
        varout = {transpose(cell2vec(tstmp))}; %make it row vector, so time is 2nd dim
    case 1
        for k = 1:numel(dattmp)
            dat = cat(2, dat, dattmp{k});
        end
        dat = {dat};
        varout = {cell2mat(tstmp)};
    case 3
        cnt = 0;
        for k = 1:numel(dattmp)
            for m = 1:numel(dattmp{k})
                cnt = cnt+1;
                dat{cnt} = dattmp{k}(m);
            end
        end
        varout = num2cell(cell2mat(tstmp), 2);
end

end


function [varout, dat, group] = vget3(pthpar, scopausername, pthscopa, usegit, runtype, opt, mosopt)

arguments
    pthpar char {mustBeTextScalar}
    scopausername char {mustBeTextScalar}
    pthscopa char {mustBeTextScalar}
    usegit (1,1) {mustBeBinary}
    runtype (1,1) {mustBeMember(runtype,0:3)} 
    opt.vnm {mustBeText, mustBeVectorOrEmpty} = '' %name of variable to find
    opt.ii (1,:) {mustBeInteger, mustBeNonnegative, mustBeVectorOrEmpty} = [] %index in ii dimension
    opt.it (1,:) {mustBeInteger, mustBeNonnegative, mustBeVectorOrEmpty} = [] %index in ii dimension
    opt.ic (1,:) {mustBeInteger, mustBeNonnegative, mustBeVectorOrEmpty} = [] %index in ii dimension
    opt.group (1,1) {mustBeMember(opt.group,[0,1,3])} = 3 %how to group found variables at inner level
    opt.group2 (1,1) {mustBeMember(opt.group2,[0,1,3])} = 3 %how to group found variables at outer level
    opt.optid {mustBeText, mustBeVectorOrEmpty} = '' %optid associated with variable(s) to find
    opt.varid {mustBeText, mustBeVectorOrEmpty} = '*' %varid of variable(s) to find (not varid assigned to output of vget)
    opt.stackid {mustBeText, mustBeVectorOrEmpty} = 'curr' %stackid associated to find
    mosopt.s = [] %options associated with variable to be found from mos s
    mosopt.dq = [] %options associated with variable to be found from mos dq
    mosopt.roi = [] %options associated with variable to be found from mos roi
    mosopt.bmp = [] %options associated with variable to be found from mos bmp
    mosopt.fmf = [] %options associated with variable to be found from mos mdl
    mosopt.mdl = [] %options associated with variable to be found from mos mdl
end

if runtype==1
    varout = [];
    dat = [];
    group = [];
    fprintf("vg struct is properly defined; since runtype=1, outputs will be empty" + newline)
    return
end

vnm = opt.vnm;
ii = opt.ii;
it = opt.it;
ic = opt.ic;
group = opt.group;
group2 = opt.group2;
optid = opt.optid;
varid = opt.varid;
stackid = opt.stackid;

if ~iscell(optid) && ~isempty(optid)
    optid = {optid};
end
if ~iscell(varid) && ~isempty(varid)
    varid = {varid};
end
if ~iscell(stackid) && ~isempty(stackid)
    stackid = {stackid};
end

mos = fieldnames(mosopt);
mosrm = mos(cellfun(@(x) isempty(mosopt.(x)), mos));
mosopt = rmfield(mosopt, mosrm);
mos = fieldnames(mosopt);
if isscalar(mos)
    mos = cell2mat(mos);
else
    error("there are either 0 or more than 1 nonempty mos in vg; there must be one and only one")
end

if isequal(mosopt.(mos), '*')
    mosopt.(mos) = []; %now that you've removed all empty mos, you can set a mos with nothing but * to empty, since * acts as empty after this point
end

if isemptyall(optid)
    mosopt = ofill(mosopt, wild=1, unpack=1); %make sure any unspecified option gets wildcard (rather than default value)
    mosopt = oid(mosopt, mos, justld=1); %we don't need usegit since justld=1 here
    for k = 1:numel(mosopt)
        optid{k} = mosopt.optid; %make it row vector, although here i don't think it matters
    end
else
    if ~isempty(mosopt)
        error("mos substruct and optid cannot both exist in vg")
    end
end

if ~strcmp(varid, '*') 
    pthvarpat = [pthscopa 'opt_var_' scopausername '_.txt'];
    [~, varid] = structfile(pthvarpat, nm=varid, usegit=usegit, dupe=0, dosort=1);
end


varout = {};
dattmp = {};
cnt = 0;
for p = 1:numel(stackid)
    for w = 1:numel(varid)
        for k = 1:numel(optid)
            if strcmp(mos, 'dq') %dq does not use stackid in filename because it is not associatedd with stack (just rec)
                recid = strsplit(stackid{p}, '_');
                recid = strjoin(recid(1:end-1), '_');
                fnpat = [recid '_' varid{w} optid{k} '_' mos '_.mat'];
            else
                fnpat = [stackid{p} '_' varid{w} optid{k} '_' mos '_.mat'];
            end
            pthpat = fullfile(pthpar, '**', fnpat);
            pthtmpall = rdir(pthpat);
            pthtmp = cell(numel(pthtmpall),1);
            for m = 1:numel(pthtmpall)
                [~, fntmp, fnext] = fileparts(pthtmpall(m).name);
                % fnpat2 = regexprep(strcat(regexprep(strcat('^', stackid), '*', '\\d*'), fnpat, '$'), '*', '.*');
                fnpat2{1} = fnpat;
                % if any(cellfun(@(x) isequal(x,1), regexp([fntmp, fnext], fnpat2))) %filter by stackid
                %     pthtmp{m} = pthtmpall(m).name;
                % end
                pthtmp{m} = pthtmpall(m).name;
            end
            pthtmp = pthtmp(~cellfun(@isempty, pthtmp));
            if isempty(cell2mat(pthtmp))
                fprintf("WARNING, optid '" + optid{k} + "' was matched but there is no corresponding data file for domain '" + mos + "'; you may have created it and then deleted it; skipping this optid" + newline)
            else
                if numel(pthtmp)>1
                    error("there are multiple files with matched optid and domain, you may have created them from different versions of the same stack (or, od, etc); need to make this fixible; for now just rename one" + newline)
                end
                pth = pthtmp{1}; %there should only be one here
                fprintf("loading data file for domain '" + mos + "', optid '" + optid{k} + "'" + newline)
                saved_struct = load(pth);
                if isfield(saved_struct, mos)
                    saved_struct = saved_struct.(mos);
                    fprintf("saved variable was not saved as struct (maybe it was nonscalar), so indexing into with with mos" + newline)
                end
                if isempty(cell2mat(vnm))
                    vnm = transpose(fieldnames(saved_struct)); % all variables if vnm is empty
                end

                for m = 1:numel(vnm)
                    try
                        saved_var = saved_struct.(vnm{m});
                    catch
                        saved_var = saved_struct.dat.(vnm{m});
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
                            varout{cnt} = stackind(saved_var{ic(q)}, dm=dm, ii=ii, it=it);
                            dattmp{cnt} = vgdatmake(pth, optid{k}, vnm{m}, ii, it, ic, group, group2);
                        end
                    else
                        if isempty(ic)
                            cnt = cnt+1;
                            varout{cnt} = stackind(saved_var, dm=dm, ii=ii, it=it);
                            dattmp{cnt} = vgdatmake(pth, optid{k}, vnm{m}, ii, it, ic, group, group2);
                        else
                            error("ic is not valid for indexing anything but cell array right now")
                        end
                    end

                end
            end
        end
    end
end

szt = cellfun(@(x) size(x,2), varout, 'UniformOutput', false);
if numel(szt)>1 && ~isequal(szt{:}) && ismember(group, [1,3])
    error("all varout must be same size in time dimension if group is 1 or 3")
end

dat = [];
if ~isempty(szt)
    switch group
        case 0
            for k = 1:numel(dattmp)
                dat = cat(2, dat, dattmp{k});
            end
            varout = {transpose(cell2vec(varout))}; %make it row vector, so time is 2nd dim
        case 1
            for k = 1:numel(dattmp)
                dat = cat(2, dat, dattmp{k});
            end
            varout = {cell2mat(varout(:))};
        case 3
            for k = 1:numel(dattmp)
                dattmp2 = repelem(dattmp{k}, size(varout{k},1));
                for m = 1:numel(dattmp2)
                    if isempty(dattmp2(m).ii)
                        dattmp2(m).ii = m;
                    else
                        dattmp2(m).ii = dattmp2(m).ii(m);
                    end
                end
                dat = cat(2, dat, dattmp2);
            end
            varout = num2cell(cell2mat(varout(:)), 2);

    end
end

end



function dat = vgdatmake(pth, optid, vnm, ii, it, ic, group, group2)

dat.pth = pth;
dat.optid = optid;
dat.vnm = vnm;
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
    dq: t, bf, bvf, bs, bvs, by, bvy, vh, vvy, vvynom

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
