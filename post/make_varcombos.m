function [varcombos, varsz] = make_varcombos(varsc)

varsz = cell2mat(cellfun(@size,varsc,'UniformOutput',false));

if all(varsz ~= varsz(1))
    error("timeseries do not have equal number samples")
end

for vi = 1:size(varsz,1)
    varcombstmp{vi} = 1:varsz(vi,:);
end
varcombos = cell(1, numel(varcombstmp));
[varcombos{:}] = ndgrid(varcombstmp{:});
varcombos = cellfun(@(x) x(:), varcombos, 'uniformoutput', false);
varcombos = [varcombos{:}];

end