
function daqnew = daqrename(daq, vrenm)

%make sure they're all row vectors, or empty

fnold = fieldnames(daq);

daqnew = struct;
for m = 1:numel(daq) %can be nonscalar if useinds requests multiple registers

    for k = 1:numel(vrenm)
        renmtmp = strtrim(strsplit(vrenm{k}, ':'));
        nmnew = renmtmp{1};
        nmold = strtrim(strsplit(renmtmp{2}, ','));
        if any(ismember(fnold,nmold))
            nmoldtmp = fnold(ismember(fnold, nmold));
            nmoldtmp = nmoldtmp{1}; %in case there are multiple old name matches (there probably won't be), just choose one
            daqnew(m,1).(nmnew) = daq(m,1).(nmoldtmp)(:)';
            if ~isempty(daq(m,1).([nmoldtmp '_supp']))
                daqnew(m,1).([nmnew '_supp']) = daq(m,1).([nmoldtmp '_supp'])(:)';
            end
        else
            daqnew(m,1).(nmnew) = []; %if there are no old names corresponding to the new name, make it empty
        end
    end

end

