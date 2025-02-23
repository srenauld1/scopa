
function daqnew = daqrename(daq, renm)

%make sure they're all row vectors

nms = daq.Properties.VariableNames;

daqnew = struct;
for k = 1:numel(renm)
    renmtmp = strtrim(strsplit(renm{k}, ','));
    nmold = renmtmp{1};
    nmnew = renmtmp{2};
    if any(strcmp(nmold,nms))
        daqnew.(nmnew) = daq.(nmold){1}(:)';
    end
end




