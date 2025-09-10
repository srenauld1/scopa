function lab = num2lab(x, opt)

%{

convert numeric vector into an abbreviated character vector (output 'lab', i.e. label for figures)
lab prints to highest precision in numeric vector input x
name-value argument maxn sets max number of elements to print in label
can also specify name-value arguments delim (element delimiter) and prefix (label prefix) 

TODO: accept non-vector input 
TODO: more complex abbreviation options

%}

arguments
    x  % numeric vector to be converted to char vector (label)
    opt.maxn = 10 %max number elements to print, if numel(x)>maxn, only first and last floor(maxn/2) are included in lab
    opt.delim = ',' %delimiter for each element in output
    opt.prefix = '' %prefix for output
    opt.p = [] %number of elements to include after decimal; if nonempty, must be nonnegative; 0 to print integers; empty to use max precision in input x
end
maxn = opt.maxn;
delim = opt.delim;
prefix = opt.prefix;
p = opt.p;

if ~isempty(x) && ( ~isvector(x) || ~isnumeric(x) )
    error("x must be numeric vector")
end

if ~isempty(x) && isempty(p)
    p = max(cellfun(@numel, convertStringsToChars(extractAfter(string(x), '.'))));
end

if isequal(p,0)
    pstr = ['%d' delim];
else
    pstr = ['%.' num2str(p) 'f' delim];
end

if any(mod(x,1)~=0) && isequal(p,0)
    x = round(x);
end

if isempty(x)
    lab = '[]';
elseif numel(x)<=maxn
    tmpprint = sprintf(pstr, x);
    lab = [prefix tmpprint(1:end-1)];
else
    if isequal(x, x(1):x(end))
        lab = [prefix '[' num2str(x(1)) ':' num2str(x(end)) ']'];
    else
        if maxn==1
            tmpprint = sprintf(pstr, x(1));
            lab = [prefix '[' tmpprint '...]'];
        else
            numtmp = floor(maxn/2);
            tmpprint = sprintf(pstr, x(1:numtmp));
            tmpprint2 = sprintf(pstr, x(end-(numtmp-1):end));
            lab = [prefix '[' tmpprint '...' tmpprint2(1:end-1) ']'];
        end
    end
end

