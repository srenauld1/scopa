function chan = stackchan(md)

arguments
    md = []
end

if isempty(md)
    mdsild()

end
id = idmake(pthstack);

[~, fn, ~] = fileparts(pthstack);
if contains(fn, 'trial_') && contains(fn, '-') || contains(fn, 'raw_.')
    rawstack = 1;
else
    rawstack = 0;
end

if isfield(md, ['chanrm_' id.suffix])
    chanrm = md.(['chanrm_' id.suffix]);
else
    if rawstack
        chanrm = [];
    else
        error("chanrm_" + id.suffix + " is not a field in mdsi_.txt; it is required to track discarded channels; you may be using an old mdsi file; rerun the code that created this tif: " + pthstack + " and chanrm_" + id.suffix + " will be added to mdsi" + newline + "you can also add the field to mdsi manually, the syntax is: " + sprintf('"chanrm: 1," or "chanrm: 2," or "chanrm: null,"') + newline)
    end
end

% chan = setdiff(md.channel_save, chanrm); %this is if ic were pmt index, but right now ic is stack chan index 

if isempty(chanrm)
    chan = 1:numel(md.channel_save);
else
    chan = setdiff(1:numel(md.channel_save), chanrm);
end