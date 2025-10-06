function chan = stackchan(pthstack)

%{
chan is computed as stack channel index (index of 5th dimension) in the original scanimage stack
stack referenced by pthstack could have had a channel removed, if it's not the original scanimage stack (ie 'rawstack')
if a channel was removed, this function will return the channel that is present in the stack, since it cannot be determined from index of 5th dimension alone
chan is computed from the metadata file, which keeps track of removed channels 
%}

arguments
    pthstack = [] %path to stack
end

if isempty(pthstack)
    pthstack = glb('pthstack');
    if isempty(pthstack)
        error("must pass in pthstack or set glb('pthstack')")
    end
end
id = idmake(pthstack);
md = mdsild(pthstack);

[~, fn, ~] = fileparts(pthstack);
if endsWith(fn, 'o_') || ( contains(fn, 'trial_') && contains(fn, '-') )  %scopa or flyg raw stack pattern
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

% chan = setdiff(md.channel_save, chanrm); %this commented line of code computes chan as pmt index (eg, chan could be 2 for pmt 2 even if stack only has singleton 5th dimension because only pmt 2 was saved), but right now, below, chan is computed as stack channel index (index of 5th dimension) in the original scanimage stack, without regard for which pmt was used

if isempty(chanrm)
    chan = 1:numel(md.channel_save); 
else
    chan = setdiff(1:numel(md.channel_save), chanrm); 
end