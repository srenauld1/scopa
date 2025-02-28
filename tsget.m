function tsout = tsget(tg, opt)


arguments (Input)
    tg
    opt.dm = [] %dim order of timeseries to be found; used to apply indices
    opt.pthparent = []
end
arguments (Output)
    tsout cell
end
dm = opt.dm;
pthparent = opt.pthparent;

if isempty(dm)
    dm = 'it';
end
if isempty(pthparent)
    pthparent = glb('pthparent');
end

if all(strcmp(fieldnames(tg), 'tg'))
    tg = tg.tg;
else
    error("struct must contain substruct tg (which can be nonscalar) and nothing else")
end

for m = 1:numel(tg) %loop over tg elements
    tsout = tsget_one(tg(m), dm, pthparent);
end

end


function tsout = tsget_one(tg, dm, pthparent)


if isfield(tg, 'optid') && ~isempty(tg.optid)
    optid = tg.optid;
else
    optid = [];
end
if ~iscell(optid)
    optid = {optid};
end
optid = transpose(optid(:));

if isfield(tg, 'vnm') && ~isempty(tg.vnm)
    vnm = tg.vnm;
else
    vnm = [];
end
if ~iscell(vnm)
    vnm = {vnm};
end
vnm = transpose(vnm(:));

if isfield(tg, 'ii') && ~isempty(tg.ii)
    ii = tg.ii;
else
    ii = [];
end

if isfield(tg, 'it') && ~isempty(tg.it)
    it = tg.it;
else
    it = [];
end

if isfield(tg, 'ic') && ~isempty(tg.ic)
    ic = tg.ic;
else
    ic = [];
end

if isfield(tg, 'group') && ~isempty(tg.group)
    group = tg.group;
else
    group = '';
end


id_capable_vbin = glb('id_capable_vbin');
if isempty(id_capable_vbin)
    fprintf("id_capable_vbin are not defined in glb, using default defined in tsget, but you should define them in glb" + newline)
    id_capable_vbin = {'roi', 'mdl', 'bmp', 'daq'};
end
if isstring(id_capable_vbin)
    id_capable_vbin = convertStringsToChars(id_capable_vbin);
end

if ~isscalar(tg)
    error("INPUT STRUCT TO tsget MUST BE SCALAR")
end

cnt = 0;
vbin = [];
for k = 1:numel(id_capable_vbin)
    if isfield(tg, id_capable_vbin{k}) && ~isempty(tg.(id_capable_vbin{k}))
        cnt = cnt + 1;
        vbin = id_capable_vbin(k);
    end
    if cnt>1
        error("INPUT STRUCT TO tsget MUST CONTAIN ONE AND ONLY ONE id_capable_vbin AT THE HIGHEST LEVEL")
    end
end

if isempty(vbin)
    if isempty(cell2mat(optid))
        error("if there is no vbin in tg, there must be optid")
    end
elseif isscalar(vbin)
    vbin = vbin{1};
    if ~isempty(cell2mat(optid))
        error("vbin and optid cannot both exist in tg")
    end
else
    error("there can only be one vbin in tg")
end




trymatch = 1;
if isempty(cell2mat(optid))
    tgopt.(vbin) = tg.(vbin);
    tgopt = odf(tgopt, vbin, fill=1, wild=1); %make sure any unspecified option gets wildcard (rather than default value)
    tgopt = oid(tgopt, getonly=1);
    if ~isempty(tgopt.(vbin))
        optid = transpose(fieldnames(tgopt.(vbin))); %make it row vector, although here i don't think it matters
    else
        fprintf("no variable found" + newline)
        trymatch = 0;
    end
end

tsout = [];
if trymatch

    cnt = 0;
    for k = 1:numel(optid)
        optid_tmp = optid{k};
        fnpat = ['*' '_' optid_tmp '_' vbin '_.mat'];
        pthpat = fullfile(pthparent, '**', fnpat);
        pthtmp = rdir(pthpat);
        if isscalar(pthtmp)
            pth = cell(numel(pthtmp), 1);
            for m = 1:numel(pthtmp)
                pth{m} = pthtmp(m).name;

                fprintf("loading data file for domain '" + vbin + "', optid '" + optid_tmp + "'" + newline)
                saved_struct = load(pth{m}); 
                if isempty(cell2mat(vnm))
                    vnm = transpose(fieldnames(saved_struct)); % all variables if vnm is empty
                end
                for f = vnm
                    saved_var = saved_struct.(f{1});
                    if all(cellfun(@isempty, saved_var))
                        error("you are trying to load an empty roi; you may intend to do pixelwise analysis; need to write this option here (load, or point to, a spacetime reshaped stack)")
                    end
                    itmp.ii = ii;
                    itmp.it = it;

                    if iscell(saved_var)
                        if isempty(ic)
                            ic = find(~cellfun(@isempty, saved_var)); %if ic isempty, load ts for all nonempty channels
                        end
                        for q = 1:numel(ic)
                            cnt = cnt+1;
                            tsout{cnt} = vind(saved_var{ic(q)}, dm, itmp);
                        end
                    else
                        if isempty(ic)
                            cnt = cnt+1;
                            tsout{cnt} = vind(saved_var, dm, itmp);
                        else
                            error("ic is not valid for indexing anything but cell array right now")
                        end
                    end
                end
            end
        elseif numel(pthtmp)>1
            error("there are multiple files with matched optid and domain, you may have created them from different versions of the same stack (cmrg, dcdn, etc); need to make this fixible; for now just rename one" + newline)
        elseif isempty(pthtmp)
            fprintf("WARNING, optid '" + optid_tmp + "' was matched but there is no corresponding data file for domain '" + vbin + "'; you may have created it and then deleted it; skipping this optid" + newline)
        end
    end


    szt = cellfun(@(x) size(x,2), tsout, 'UniformOutput', false);
    if numel(szt)>1 && ~isequal(szt{:}) && any(strcmp(group, {'1','3'}))
        error("all tsout must be same size in time dimension if group is 1 or 3")
    end

    switch group
        case '1'
            tsout = {cell2mat(tsout(:))};
        case '3'
            tsout = num2cell(cell2mat(tsout(:)), 2);
        case 'flat'
            tsout = {transpose(cell2vec(tsout))}; %make it row vector, so time is 2nd dim
    end

end

end


%{

these docs are a bit outdated

each domain has a different set of available timeseries 
    roi: ts
    mdl: pred
    bmp: respcl, mu, rho, ampmean, amppeak, ampmu, vel, offset
    fmf: every feature id (like CON_51)
    daq: t, bf, bfv, bs, bsv, by, byv, vy, vyv, vyvnom

tsget recovers timeseries from saved files, using the options used to create the timeseries, or various identifiers  



    domain
        domain is char array, must exist in ts
        empty returns all
        
    optused 
        optused is a struct containing a subset of the options used to create timeseries, or just the optid assigned to an options set
        since all unique options sets have an optid, optused.optid is sufficient to recover timeseries 
        optused.optid is a char array, which can contain asterisk as wildcard
        for more control, or if you don't know the optid, pass individual options in optused (in this case you cannot pass optid)
        optused must be valid given the domain argument
        if any optused are cell arrays, they are expanded and all results are found 
        empty returns all for the given domain

    name
        name is a numeric scalar or vector, or empty vector
        name must be valid given the domain and optused arguments
        empty vector returns all for the given domain and optused

    group
        group determines how output timeseries are arrayed in the 3rd dimension 
        the 3rd dimenion is the looping dimension in all functions that use tsget (eg mdlmake loops over 3rd dim to fit seperate models with the same options but different timeseries, pltx loops over the 3rd dimension to present groups of variables, fmf loops over 3rd dim to extract features from different sets of timeseries)
        group can take the following values: 'all', 'domain', 'optused', 'name', 
        these refer to tsget input arguments, which can each be expanded to return multiple timeseries; 
        group determines whether output should be group according to that expansion; 
            all: like the inverse of 'name'; output 1st dimension length matches number of found timeseries and 3rd dimension is singleton; 
            domain: array domain groups along 3rd dimension 
            optused: array optused groups along 3rd dimension 
            name: like the invserse of 'all'; output 3rd dimension length matches number of found timeseries, and 1st dimension is singleton; 

%}
