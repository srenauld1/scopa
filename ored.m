function [o, optinert] = ored(o, vbin, delim)

% ored ("options reduce") removes options that have no effect on the data (like plotting options),
% and also removes redundancy (since options can depend on each other)
% ored is called before assigning id (optid) to an options set (using structfile in oid)

arguments
    o
    vbin
    delim
end

inert_vbin = glb('inert_vbin');
if isempty(inert_vbin)
    error("inert_vbin must be defined in glb")
end

if isfield(o, vbin)
    error("you passed o with substruct " + vbin + " but should pass that substruct itself")
end

o = structflat(o, delim=delim);
fnoflat = fieldnames(o);
expr = [strcat('^', inert_vbin, delim), strcat(delim, inert_vbin, delim), strcat(delim, inert_vbin, '$'), strcat('^', inert_vbin, '$')]; %all possible positions of inert vbin in the flattened names
mtch = zeros(numel(fnoflat), 1, 'logical');
mtch_is_struct = zeros(numel(fnoflat), 1, 'logical');
for k = 1:numel(expr)
    mtchtmp = ~cellfun(@isempty, regexp(fnoflat, expr{k}));
    mtch = mtch | mtchtmp;
    if endsWith(expr{k}, delim)
        mtch_is_struct = mtch_is_struct | mtchtmp;
    end
end

o = struct2cell(o);

optinert = o(mtch);
fninert = fnoflat(mtch);
optinert = cell2struct(optinert, fninert);

dupes = [];
for k = 1:numel(inert_vbin)
    fnoflat(mtch_is_struct) = regexprep(fnoflat(mtch_is_struct), [inert_vbin{k} '.*'], inert_vbin{k});
    [~, w] = unique( fnoflat, 'stable' );
    tmp = setdiff( 1:numel(fnoflat), w );
    dupes = [dupes; tmp(:)];
end

o(mtch) = {[]};
o(mtch_is_struct) = {struct('tg', [])}; %insert empty tg field for json to write empty tg properly (hack needs top be fixed)
o(dupes) = [];
fnoflat(dupes) = [];
o = cell2struct(o, fnoflat);
o = structunflat(o, delim=delim);

switch vbin %further specialized reduction by vbin
    case 'roi'
        o = ored_roi(o);
    case 'bmp'
        o = ored_bmp(o);
end


end
