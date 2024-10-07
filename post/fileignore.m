function pthkp = fileignore(pthin)

%remove file from cell if it doesn't exist

if ~iscell(pthin)
    pthin = {pthin};
end

pthkp = [];
cnt = 0;
if any(isfile(pthin))
    for k = 1:numel(pthin)
        if isfile(pthin{k})
            cnt = cnt+1;
            pthkp{cnt} = pthin{k};
        else
            sprintf("WARNING, THE FOLLOWING FILE DOES NOT EXIST:" + newline + pthin{k} + newline + "IT HAS BEEN REMOVED FROM INPUT LIST")
        end
    end
end

end