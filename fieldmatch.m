function [common, outall] = fieldmatch(s, varargin, opt)

%{

find fieldname in struct (struct can be nested and nonscalar)

example:
    fieldmatch(roi, {'rg.rgname', 'no'}, {'roiname', 'left'}, lev=1);

%}

arguments (Input)
    s %struct, or path to struct saved with structfile
end
arguments (Input,Repeating)
    varargin %cell arrays {field name, value}
end
arguments (Input)
    opt.lev = []; % level of nesting for output
    opt.multi = []; % 1 to allow output multiple matches
    opt.noerror = 1; % 1 will not stop execution if error just results in empty output (does not apply to syntax errors)
end
arguments (Output)
    common
    outall
end
lev = opt.lev;
multi = opt.multi;
noerror = opt.noerror;

delimflat = '__'; % delimiter in flattened struct

if ~isempty(lev)
    if ~isequal(lev, sort(lev), min(lev):max(lev)) || any(mod(lev,1)) || any(lev<1)
        error("lev must be empty, or a positive integer, or contiguous increasing positive integers")
    end
end
if isempty(multi)
    multi = 0;
end
multi = logical(multi);

if ~isstruct(s)
    if isfile(s)
        [~, ~, s] = structfile(s, usegit=0);
    else
        error("s must be struct, or path to struct written to .txt file with 'structfile'")
    end
end

sf = structflat(s, delim=delimflat);
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
        cr = strrep(varargin{k}{1}, '.', delimflat);
        val = varargin{k}{end};
        idxfn = contains(fna, cr);
        idxval = cellfun(@(x) isequal(x,val), vala);
        idx = idxfn & idxval;
        if isempty(idx)
            if noerror
                fprintf("no matches found for cr input number: " + num2str(k) + newline)
            else
                error("no matches found for cr input number: " + num2str(k))
            end
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
    if noerror
        fprintf("there are no matches to the criteria you entered" + newline)
    else
        error("there are no matches to the criteria you entered")
    end
end
nm = cellfun(@(x) numel(strsplit(x, '.')), common);
if ~isempty(lev)
    common = common(nm>=lev(end));
    if isempty(common)
        if noerror
            fprintf("there are no matches at the requested level (although there are matches at lower levels)" + newline)
        else
            error("there are no matches at the requested level (although there are matches at lower levels)")
        end
    end
    common = cellfun(@(x) strsplit(x,'.'), common, 'UniformOutput', false);
    common = cellfun(@(x) strjoin(x(lev),'.'), common, 'UniformOutput', false);
end


common = unique(common, 'stable');

if isscalar(common) || isempty(common)
    common = cell2mat(common);
else
    if ~multi
        error("multiple output, but name-value argument 'multi' is set to 0 (which is its default value)")
    end
end



end