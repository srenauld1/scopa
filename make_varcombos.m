function varcombos = make_varcombos(vars)

for vi = 1:numel(vars)
    if 0 %isempty(vars)
        varcombstmp{vi} = 1;
    else
        varcombstmp{vi} = 1:size(vars{vi}, 1);
    end
end
varcombos = cell(1, numel(varcombstmp));
[varcombos{:}] = ndgrid(varcombstmp{:});
varcombos = cellfun(@(x) x(:), varcombos, 'uniformoutput', false);
varcombos = [varcombos{:}];

end