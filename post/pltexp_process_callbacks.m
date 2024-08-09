function [cbflags, ttl] = pltexp_process_callbacks(cbflags, hndls, varsz, varsp, roipixindp, ti, tinds_use, sampinc)


% valid main sequences:
%   pltexp_sequence_v (change plotted variable with index or stack image click): v, digits, [ i, [ digits, save ] ] OR [ click, save ]
%   pltexp_sequence_t (change plotted t with digits or x-axis click): t [ digits, hyphen, digits, save ] OR [ click, click, save ]

% where 'save' denotes any save-change button (n,a,c,backspace)
% where 'digits' refer to the completed number, not each digit comprising it (which are registered one-at-a-time)
% where brackets denote sub-sequences; sub-sequences can be repeated within the main sequence; different sub-sequences, when multiple, can be mixed within a single main sequence

% init buttons are: v (modify current plot variable), t (modify plotted t)
% pressing an init button erases any unsaved changes (changes that have not been finilized with a save button)

% context buttons are: hyphen (sequence_t), r (sequence_v)
% context buttons have only meaning after init and before save

% save buttons are: n (new), a (add), backspace (delete), c (concatenate)
% save buttons save changes made in the current sequence

% stack image clicks select spherical roi centroids, with optional specification of radius using button r with digit; only relevant in sequence_v

% timeseries clicks (on x axis) select t plot range; after t or save, 1st click is tstart, 2nd is tstop; only relevant in sequence_t

% todo: elaborate context buttons after roi click (like radius digit, etc)


persistent sequence_init
persistent subsequence_type
persistent changed_v
persistent changed_t
persistent ttl_tmp


plot_buttons = {'return'};
init_buttons = {'v', 't'};
save_buttons = {'n', 'a', 'c', 'backspace'};

if ~isempty( hndls.hfg.UserData) && ~isempty(hndls.ts.hax{1}.UserData) && any(~cellfun(@(x) isempty(x.UserData), hndls.st.hol))
    error("multiple callback buttons recorded; should only be one at a time")
end

if numel(find(~cellfun(@(x) isempty(x.UserData), hndls.st.hol)))>1
    error("multiple images have callback data; should only be one at a time")
end


if numel(cbflags.val.v)==numel(changed_v)
    v_being_changed = 0;
else
    v_being_changed = 1; % v flag has been set but changes not finalized by pressing v again (to initiate another set of changes), or by pressing enter (to plot changes)
end

user_input = hndls.hfg.UserData;
if isempty(subsequence_type) && ~any(strcmpi(user_input, init_buttons)) && ~isempty(user_input)
    subsequence_type = 'digit';
end
hndls.hfg.UserData = [];

if isempty(user_input)
    user_input = hndls.ts.hax{1}.UserData;
    hndls.ts.hax{1}.UserData = [];
    if ~isempty(user_input) && isempty(subsequence_type)
        subsequence_type = 'click';
    end
end

if isempty(user_input)
    for j = 1:numel(hndls.st.hol)
        user_input = hndls.st.hol{j}.UserData; %add image index, which is z slice
        hndls.st.hol{j}.UserData = [];
        if ~isempty(user_input)
            user_input = [user_input j];
            if isempty(subsequence_type)
                subsequence_type = 'click';
            end
            break
        end
    end
end


if ~isempty(user_input)

    if strcmp(subsequence_type, 'digit')
        ttl_tmp = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten
    else
        ttl_tmp = 'CLICKED A PLOT OF CONTEXT, NOTHING WILL HAPPEN'; %default title, in case not overwritten
    end


    if any(strcmpi(user_input, plot_buttons))  % pressing enter plots any changes

        if cbflags.val.tinds
            cbflags.restart.t = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING t';
        end

        if ( ~isempty(cbflags.val.roicen) && any(~cellfun(@isempty, cbflags.val.roicen)) ) || ( ~isempty(cbflags.val.i) && any(~cellfun(@isempty, cbflags.val.i)) ) %don't use elseif since there can be v and t changes
            if any(~cellfun(@isempty, cbflags.val.roicen))
                cbflags.restart.v = 1;
                ttl_tmp = 'PRESSED "enter", CHANGING plot variables';
            end
        end


    elseif any(strcmpi(user_input, init_buttons)) %pressing an init button initializes a sequence with a unique set of valid buttons (and erases any unsaved sequence in process)

        sequence_init = user_input;
        ttl_tmp = ['PRESSED "' sequence_init '", INITIATING SEQUENCE "' sequence_init '", USE DIGITS, CONTEXT BUTTONS, SAVE BUTTONS, OR PLOT CLICKS TO MAKE CHANGES TO "' sequence_init '"'];
        if strcmpi(user_input, 'v')
            changed_v = [changed_v 1];
        elseif strcmpi(user_input, 't')
            changed_t = [changed_t 1];
        end

        clear pltexp_sequence_t pltexp_sequence_v %clear all sequences' persistent variables after any init button


    elseif strcmp(sequence_init, 'v')

        [subsequence_type, ttl_tmp, cbflags.val.v, cbflags.val.i, cbflags.val.roicen] = pltexp_sequence_v(user_input, subsequence_type, save_buttons, v_being_changed, roipixindp, varsz);

    elseif strcmp(sequence_init, 't')

        [subsequence_type, ttl_tmp, cbflags.val.tinds] = pltexp_sequence_t(user_input, subsequence_type, save_buttons, sampinc, ti, tinds_use);

    end

end


ttl = ttl_tmp;


end

