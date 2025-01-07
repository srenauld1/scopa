function val = sistrparse( str, key )
 
%parse scanimage metadata string
%output val will be number if it's a digit

str = transpose(strsplit(str, '\n')); %transpose bc it's easier to read as a column
idx = find(contains(str, key));
if isscalar(idx)
    tmp = str{idx};
elseif isempty(idx)
    error("no match found in SI string")
else
    error("multiple matches found in SI string")
end
tok = regexp(tmp, '= (.*)$', 'tokens'); %match whatever comes after equals sign
if isempty(tok)
    error("cannot parse SI string")
else
    val = str2double(regexp(tok{1}{1}, '\d*[\.]?\d*', 'match')); %try to convert to number (matrix will be vector)
    if ~isnan(val)
        if numel(val)>1 && contains(tok{1}{1}, ';')
            fprintf("WARNING, CHAR CONTAINS SEMICOLON, DO YOU WANT A MATRIX? OUTPUT IS VECTOR; " + newline)
        end
    else %if it's not a number, just output char
        val = strrep(tok{1}{1},  '''', ''); %make sure char output does not have extra quotes
    end
end

end