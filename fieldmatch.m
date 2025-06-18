function [common, outall] = fieldmatch(s, varargin, opt)

%find fieldname in struct (can be nested)

arguments (Input)
    s
end
arguments (Input,Repeating)
    varargin
end
arguments (Input)
    opt.lev = [];
    opt.multi = [];
    opt.delim = [];
end
arguments (Output)
    common
    outall
end
lev = opt.lev;
multi = opt.multi;
delim = opt.delim;

if isempty(multi)
    multi = 0;
end
multi = logical(multi);
if isempty(delim)
    delim = '__';
end

fncheck = fieldnames(structflat(s, delim=delim, prefix='tmpstructblahblahblah'));
if any(~cellfun(@isempty, regexp(fncheck, [delim '\d' delim] )))
    error("fieldmatch currently does not support nonscalar structs")
end

sf = structflat(s, delim=delim);
fna = fieldnames(sf);
vala = struct2cell(sf);

if isempty(varargin)
    fncr = fna;
    outall{1} = strrep(fncr, delim, '.');
else
    outall = cell(numel(varargin),1);
    for k = 1:numel(varargin)
        if numel(varargin{k})>2
            error("each criterion must be length 2 cell")
        end
        cr = strrep(varargin{k}{1}, '.', delim);
        val = varargin{k}{end};
        idxfn = contains(fna, cr);
        idxval = cellfun(@(x) isequal(x,val), vala);
        idx = idxfn & idxval;
        if isempty(idx)
            error(sprintf("no matches found for cr input number: " + num2str(k)))
        end
        fncr = fna(idx);
        fncr = strrep(fncr, delim, '.');
        for q = 1:numel(fncr)
            chk = getfieldns(s, fncr{q});
            if ~isequal(cell2mat(chk), val)
                error("check failed")
            end
        end

        outall{k} = fncr;
    end
end


for k = 1:numel(outall)
    if ~isempty(lev)
        for q = 1:numel(outall{k})
            tmp = strsplit(outall{k}{q}, '.');
            outall{k}{q} = strjoin(tmp(lev), '.');
        end
    end
    if k==1
        common = outall{k};
    else
        common = intersect(common, outall{k});
    end
end

if endsWith(outall{k}, '.')
    outall{k} = outall{k}(1:end-1);
end

common = unique(common, 'stable');

if isscalar(common)
    common = cell2mat(common);
else
    if ~multi
        error("multiple output, but name-value argument 'multi' is set to 0 (which is its default value)")
    end
end



end