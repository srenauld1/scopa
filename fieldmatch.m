function [common, outall] = fieldmatch(s, varargin, opt)

%find fieldname in struct (struct can be nested and nonscalar)

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

if ~isempty(lev)
    if ~isequal(lev, sort(lev), min(lev):max(lev)) || any(mod(lev,1)) || any(lev<1)
        error("lev must be empty, or a positive integer, or contiguous increasing positive integers")
    end
end
if isempty(multi)
    multi = 0;
end
multi = logical(multi);
if isempty(delim)
    delim = '__';
end

sf = structflat(s, delim=delim);
fna = fieldnames(sf);
vala = struct2cell(sf);

if isempty(varargin)
    [~, outall{1}] = structunflat(cell2struct(vala, fna)); %get string
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
        [~, fncr] = structunflat(cell2struct(vala(idx), fna(idx)));
        outall{k} = fncr;
    end
end


for k = 1:numel(outall)
    tmp1 = cellflat(outall{k});
    prevn = 0;
    tmp3 = {};
    for q = 1:numel(tmp1)
        tmp2 = strsplit(tmp1{q}, '.');
        for w = 1:numel(tmp2)
            iwq = w+prevn;
            tmp3{iwq} = strjoin(tmp2(1:w), '.');
        end
        prevn = prevn + numel(tmp2);
    end
    if k==1
        common = tmp3;
    else
        common = intersect(common, tmp3);
    end
end
if isempty(common)
    error("there are no matches to the criteria you entered")
end
nm = cellfun(@(x) numel(strsplit(x, '.')), common);
if ~isempty(lev)
    common = common(nm>=lev(end));
    if isempty(common)
        error("there are no matches at the requested level (although there are matches at lower levels)")
    end
    common = cellfun(@(x) strsplit(x,'.'), common, 'UniformOutput', false);
    common = cellfun(@(x) strjoin(x(lev),'.'), common, 'UniformOutput', false);
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