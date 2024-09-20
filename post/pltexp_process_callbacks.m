function [cb, ttl] = pltexp_process_callbacks(cb, hndls, varsz, varsp, roiplotinds, roipixindp_plane, ti, tinds_in, sampinc_in)


% valid sequences:
%   pltexp_sequence_v (change plotted variable with index or stack image click):
%       [ v, digits, [ i, [ digits, save ] ] ] enter
%           OR
%       [ v, digits, [ click, save ] ] enter
%   pltexp_sequence_i (change stack image):
%       [ i, c, digits, arrows ]
%           OR
%       [ i, [ click, save ] ] enter
%   pltexp_sequence_t (change plotted t with digits or x-axis click):
%       [ t [ digits, hyphen, digits, save ] ] enter
%           OR
%       [ t [ click, click, save ] ] enter

% where brackets denote sub-sequences; sub-sequences can be repeated within their enclosing sequence sequence, but can equivalently be called but repeating the enclosing sequence; different sub-sequences, when multiple, can be mixed within a single enclosing sequence
% where 'save' denotes any save-change button (n,a,c,d)
% where 'digits' refer to the completed number, not each digit comprising it (which are registered one-at-a-time)

% init buttons are: v (modify current plot variable), t (modify plotted t)
% pressing an init button erases any unsaved changes (changes that have not been finilized with a save button)

% context buttons are: hyphen (sequence_t), r (sequence_v)
% context buttons have only meaning after init and before save

% save buttons are: n (new), a (add), d (delete), c (concatenate)
% save buttons save changes made in the current sequence

% stack image clicks select spherical roi centroids, with optional specification of radius using button r with digit; only relevant in sequence_v

% timeseries clicks (on x axis) select t plot range; after t or save, 1st click is tstart, 2nd is tstop; only relevant in sequence_t

% todo: elaborate context buttons after roi click (like radius digit, etc)


persistent sequence_init
persistent changed_v
persistent changed_t
persistent changed_i
persistent ttl_tmp
persistent val_varalpha
persistent val_imalpha
persistent val_varalpha_in
persistent val_imalpha_in


plot_buttons = {'return'};
init_buttons = {'v', 'm',  't'};
save_buttons = {'n', 'a', 'c', 'd'};

if ~isempty( hndls.hfg.UserData) && ~isempty(hndls.ts.hax{1}.UserData) && any(~cellfun(@(x) isempty(x.UserData), hndls.st.hol))
    error("multiple callback buttons recorded; should only be one at a time")
end

if numel(find(~cellfun(@(x) isempty(x.UserData), hndls.st.hol)))>1
    error("multiple images have callback data; should only be one at a time")
end


user_input = hndls.hfg.UserData;
hndls.hfg.UserData = [];

if isempty(user_input)
    user_input = hndls.ts.hax{1}.UserData;
    hndls.ts.hax{1}.UserData = [];
end

if isempty(user_input)
    for j = 1:numel(hndls.st.hol)
        user_input = hndls.st.hol{j}.UserData;
        hndls.st.hol{j}.UserData = [];
        if ~isempty(user_input)
            user_input = [user_input j];
            break
        end
    end
end

numvar = size(varsz,1);
numplane = numel(hndls.st.hol);
numchan = max(varsz(:, 3));

if isempty(val_varalpha)
    val_varalpha = ones(numvar, numchan);
end
if isempty(val_imalpha)
    val_imalpha = ones(numplane, numchan);
end

if isempty(val_varalpha_in)
    val_varalpha_in = val_varalpha;
else
    val_varalpha_in(:) = val_varalpha; %it's so small this preallocation may not be worth the extra lines of code
end
if isempty(val_imalpha_in)
    val_imalpha_in = val_imalpha;
else
    val_imalpha_in(:) = val_imalpha; %it's so small this preallocation may not be worth the extra lines of code
end

if ~isempty(user_input)

    ttl_tmp = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

    if any(strcmpi(user_input, plot_buttons))  % pressing enter plots any changes

        if ~isempty(cb.val.tinds) || ~isempty(cb.val.sampinc)
            if isempty(cb.val.tinds)
                cb.val.tinds = tinds_in;
            elseif isempty(cb.val.sampinc)
                cb.val.sampinc = sampinc_in;
            end
            cb.restart.t = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING t';
        end

        if ~isempty(cell2mat(cb.val.roicen)) || ~isempty(cell2mat(cb.val.i)) || ~isempty(cell2mat(cb.val.vdel)) %don't use elseif since there can be v and t changes
            cb.restart.v = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING plot variables';
        end

    elseif any(strcmpi(user_input, init_buttons)) %pressing an init button initializes a sequence with a unique set of valid buttons (and erases any unsaved sequence in process)

        sequence_init = user_input;
        ttl_tmp = ['PRESSED "' sequence_init '", INITIATING SEQUENCE "' sequence_init '", USE DIGITS, CONTEXT BUTTONS, SAVE BUTTONS, OR PLOT CLICKS TO MAKE CHANGES TO "' sequence_init '"'];
        clear pltexp_sequence_v pltexp_sequence_i pltexp_sequence_t %clear all sequences' persistent variables after any init button

    elseif strcmp(sequence_init, 'v')

        [ttl_tmp, val_v, val_i, val_roicen, val_vdel, val_varalpha] = pltexp_sequence_v(user_input, save_buttons, roipixindp_plane, varsz, numvar, val_varalpha);
        if ~isempty(val_v)
            cb.val.v = [cb.val.v val_v];
            cb.val.i{cb.val.v(end)} = val_i;
            cb.val.roicen{cb.val.v(end)} = val_roicen;
            cb.val.vdel{cb.val.v(end)} = val_vdel;
        end

    elseif strcmp(sequence_init, 'm')

        [ttl_tmp, cb.val.imcen, cb.val.imchan, cb.val.implane, val_imalpha] = pltexp_sequence_i(user_input, save_buttons, roipixindp_plane, numchan, numplane, val_imalpha);

    elseif strcmp(sequence_init, 't')

        [ttl_tmp, cb.val.tinds, cb.val.sampinc] = pltexp_sequence_t(user_input, save_buttons, sampinc_in, ti, tinds_in);

    end

end

imalpha_affects_varalpha = 1;
if imalpha_affects_varalpha && ~isempty(cb.val.imchan)
    cb.quick.varalpha(roiplotinds, cb.val.imchan) = val_varalpha(roiplotinds, cb.val.imchan)*max(val_imalpha(:,cb.val.imchan)); %by default, imalpha change (max across all planes) has proportional effect on varalpha (for roi variables)
    not_roiplotinds = setxor(1:size(cb.quick.varalpha,1), roiplotinds);
    cb.quick.varalpha(not_roiplotinds, :) = val_varalpha(not_roiplotinds, :); %non-roi variables, if anything changed, apply to both columns if there's two 
else
    cb.quick.varalpha = val_varalpha; %by default imalpha change has proportional effect on varalpha
end
cb.quick.imalpha = val_imalpha;

cb.changed.varalpha = val_varalpha_in~=cb.quick.varalpha; %put this after the range clipping
cb.changed.imalpha = val_imalpha_in~=cb.quick.imalpha; %put this after the range clipping


ttl = ttl_tmp;


end

