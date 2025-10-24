function newstr = regexprep2(str, expr, rep, opt)

%{

replace one or more pieces of text using regular expressions
same as regexprep except cell-valued expr and rep behave differently 
in particular, for each element of str, expr{k} becomes rep{k}

that is, each element of expr is paired with element in rep with same index (or rep can be single element, in which case all expr are mapped to the one rep)
each pairing of expr and rep operates independently of other pairings (unlike regexprep, where they operate sequentially)
because this is the only difference with regexprep, expr and rep must be cell
str can be cell, or string, or char vector; 
    if nonscalar cell or string array, each element is operated on independently by expr and rep

newstr matches str class (char, string, or cell of char)

%}


arguments
    str {mustBeText, mustBeVector}
    expr {mustBeText, mustBeVector}
    rep {mustBeText, mustBeVector}
    opt.whole = 0 %match whole expressions, shorthand for ^expr$, so user doesn't have to do this for all elements
end
whole = opt.whole;

stringinput = 0;
if isstring(str)
    stringinput = 1;
    str = convertStringsToChars(str); %in case str is string
end
cellinput = 1;
if ~iscell(str) && ~isstring(str)
    cellinput = 0;
    str = {str};
end

expr = convertStringsToChars(expr); %in case rep is string
if ~iscell(expr)
    expr = {expr};
end

rep = convertStringsToChars(rep); %in case rep is string
if ~iscell(rep)
    rep = {rep};
end

if ~isequal(numel(expr), numel(rep))
    if isscalar(rep)
        rep = repelem(rep, numel(expr));
    else
        error("expr and rep must be equal in length")
    end
end

if whole
    expr = regexprep(expr, '^\^', ''); %remove starts with carot, if it exists
    expr = regexprep(expr, '\$$', ''); %remove ends with dollar sign, if it exists
    expr = strcat('^', expr, '$'); %put carot and dollar sign on expr, to match "whole word"
end


newstr = str;
matched = zeros(1, numel(str));
for k = 1:numel(str)
    for m = 1:numel(expr)
        tmp = regexprep(str{k}, expr{m}, rep{m});
        if ~strcmp(str{k}, tmp)
            if matched(k)
                error("multiple matches found for str element '" + str{k} + "'")
            else
                newstr{k} = tmp;
                matched(k) = 1;
            end
        end
    end
end

if ~cellinput
    newstr = newstr{1};
end
if stringinput
    newstr = convertCharsToStrings(newstr); %in case input is string
end
