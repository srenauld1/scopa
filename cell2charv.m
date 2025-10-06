function y = cell2charv(x, opt)

%{

convert input cell to char vector, each element delimited by delim 
numeric, char, and string classes all become char in output
structs

%}


arguments
    x %input cell to be printed
    opt.delim = ', ' %default is comma with single whitespace
end
delim = opt.delim;

if ~iscell(x)
    error("input must be cell")
end
if iscellnested(x)
    error("input cannot be nested cell")
end
if ~ischar(delim) && ~isstring(delim)
    error("delim must be char or string")
end
if isstring(delim)
    if ~isscalar(delim)
        error("if delim is string, must be scalar")
    end
    delim = char(delim);
end
if ischar(delim)
    if ~isrow(delim)
        error("if delim is char, must be row vector")
    end
    delim = char(delim);
end

for k = 1:numel(x) %loop in case mixed types
    if isnumeric(x{k})
        x{k} = num2str(x{k});
    elseif ~ischar(x{k}) && ~isstring(x{k})
        error("input cell can only contain char, string, and numeric classes")
    end
end

y = sprintf(['%s' delim], x{:});
y = y(1:end-(numel(delim)));