
suffix = 'roi';
ff = rdir(['/Users/wienecke/stacks/**/*' suffix '_.mat']);
for k = 1:numel(ff)
    roi = load(ff(k).name);
    for kk = 1:numel(dat)
        roi.dat{kk}.mm.rg.id = erase(roi.dat{kk}.mm.rg.id, 'rd_');
        roi.dat{kk}.rg.id = erase(roi.dat{kk}.rg.id, 'rd_');
    end
    save(ff(k).name, '-struct', 'roi', '-v7.3')
end