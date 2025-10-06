function c = struct2pairs(s)

% turns a scalar struct s into a cell of string-value pairs c
% if s is a cell already, it will be returned unchanged

if iscell(s)
    c=s;
    return
elseif length(s)>1
    error("Input must be a scalar struct or cell");
end

c = [fieldnames(s).'; struct2cell(s).'];
c = c(:).';