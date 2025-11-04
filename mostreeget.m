function [mostree, mostree_open, mostree_top, options_o] = mostreeget(o, du, mosc)

%{

derive mostree (and related) from du (unnested default o struct) and a nested version of du (could be d, could be a subset of d) 
mostree: compact representation of the field arrangement in o
mostree_open: verbose representation of the field arrangement in o (for example, for mostree element "roi.mdl", mostree_open will have elements "roi" and "roi.mdl")
mostree_top: fields at the top level of o, ie fieldnames(o)

%}

arguments
    o struct % options struct to derive mostree from; if empty struct, all outputs will be empty
    du struct % unnested default options struct (du, defined in odf.m, which is the unnested version of d, also defined in odf.m) 
    mosc = [] % if o contains mosc, pass in list of those mosc (to prevent error identifying options vs mos)
end

delimflat = glbfile('delimflat');

fn_du = fieldnames(du);

oflat = structflat(o, delim=delimflat);
fn_oflat = fieldnames(oflat);

options_o = fn_oflat; %options only, not mos
while true
    options_tmp = options_o;
    options_o = regexprep(options_o, strcat('^', fn_du, delimflat, '|^\d', delimflat), ''); %remove contiguous sequence of mos and/or mosc at the beginning  
    if isequal(options_o, options_tmp) %once all not-mos have been removed, break from the loop
        break
    end
end

if ~isempty(mosc)
    fn_invalid_mosc = fn_oflat(~cellfun(@isempty, regexp(fn_oflat, sprintf([delimflat '%s$|'], mosc{:})))); %empty struct mosc (or mosc with same name as option) will be end with [delimflat mosc] in oflat
    if ~isempty(fn_invalid_mosc)
        error("mosc must be struct, and cannot be empty struct")
    end
end

options_du = {};
for k = 1:numel(fn_du)
    options_du = cat(1, options_du, fieldnames(du.(fn_du{k})));
end

options_o_no_vg = options_o(cellfun(@isempty, regexp(options_o, [delimflat glbfile('fnvget') '(' delimflat '.*)*$']))); %remove vg
invalid_options_o = options_o_no_vg(~ismember(options_o_no_vg, cat(1, options_du(:), fn_du(:))));
if ~isempty(invalid_options_o)
    error("the following options in o do not exist in du (in odf.m): " + newline + sprintf('%s\n', invalid_options_o{:}) + newline)
end

fn_oflat_mos_only = cell(1, numel(options_o));
for k = 1:numel(options_o) %use this in loop because we are removing mos_not for each fn_optin_flat (don't want removal across indices)
    fn_oflat_mos_only{k} = regexprep(fn_oflat{k}, strcat(delimflat, options_o{k}, '$'), ''); %keep only the mos
end
fn_oflat_mos_only = unique(fn_oflat_mos_only);

fn_oflat_mos_only = strrep(fn_oflat_mos_only, delimflat, '.');
fn_oflat_mos_only = regexprep(fn_oflat_mos_only, '\.(\d+)', '($1)'); % .# becomes (#) (safe because these are all structs)
fn_oflat_mos_only = regexprep(fn_oflat_mos_only, '\.(\d+)\.', '($1)'); % .#. becomes (#)
fn_oflat_mos_only = regexprep(fn_oflat_mos_only, '(\w+)\.', '$1(1).'); % .#. becomes (#)
fn_oflat_mos_only = regexprep(fn_oflat_mos_only, '([^\)])$', '$1(1)'); %add (1) to end if there is no struct index
mostree_open = {};
for k = 1:numel(fn_oflat_mos_only)
    tmp = strsplit(fn_oflat_mos_only{k}, '.');
    for q = 1:numel(tmp)
        mostree_open = cat(2, mostree_open, {strjoin(tmp(1:q), '.')});
    end
end
mostree_open = unique(mostree_open);
mostree_open = convertCharsToStrings(mostree_open);
mostree_open = sort(mostree_open);

mostree = string([]);
q = 0;
for k = 1:numel(mostree_open)
    if isequal(sum(startsWith(mostree_open, mostree_open{k})), 1)
        q = q+1;
        mostree(q) = mostree_open(k);
    end
end

mostree_top = mostree_open(~contains(mostree_open, '.')); %this keeps indices if nonscalar, while fieldnames(o) doens't
