
function daqnew = daqrename(daq, vrenm)

%make sure they're all row vectors, or empty

fnold = fieldnames(daq);

daqnew = struct;
for k = 1:numel(vrenm)
    renmtmp = strtrim(strsplit(vrenm{k}, ':'));
    nmnew = renmtmp{1};
    nmold = strtrim(strsplit(renmtmp{2}, ','));
    if any(ismember(fnold,nmold))
        nmoldtmp = fnold(ismember(fnold, nmold));
        nmoldtmp = nmoldtmp{1}; %in case there are multiple (there probably won't be), just choose one
        daqnew.(nmnew) = daq.(nmoldtmp)(:)';
        daq = rmfield(daq, nmold(isfield(daq, nmold))); %remove as you rename, so you can append remaining fields to new daq
    else
        daqnew.(nmnew) = []; %if there are no old names corresponding to the new name, make it empty
    end
end


