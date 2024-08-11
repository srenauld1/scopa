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


user_input = hndls.hfg.UserData;
hndls.hfg.UserData = [];

if isempty(user_input)
    user_input = hndls.ts.hax{1}.UserData;
    hndls.ts.hax{1}.UserData = [];
end

if isempty(user_input)
    for j = 1:numel(hndls.st.hol)
        user_input = hndls.st.hol{j}.UserData; %add image index, which is z slice
        hndls.st.hol{j}.UserData = [];
        if ~isempty(user_input)
            user_input = [user_input j];
            break
        end
    end
end


if ~isempty(user_input)

    ttl_tmp = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

    if any(strcmpi(user_input, plot_buttons))  % pressing enter plots any changes

        if cbflags.val.tinds
            cbflags.restart.t = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING t';
        end

        if ( ~isempty(cbflags.val.roicen) && any(~cellfun(@isempty, cbflags.val.roicen)) ) || ( ~isempty(cbflags.val.i) && any(~cellfun(@isempty, cbflags.val.i)) ) %don't use elseif since there can be v and t changes
            cbflags.restart.v = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING plot variables';
        end


    elseif any(strcmpi(user_input, init_buttons)) %pressing an init button initializes a sequence with a unique set of valid buttons (and erases any unsaved sequence in process)

        sequence_init = user_input;
        ttl_tmp = ['PRESSED "' sequence_init '", INITIATING SEQUENCE "' sequence_init '", USE DIGITS, CONTEXT BUTTONS, SAVE BUTTONS, OR PLOT CLICKS TO MAKE CHANGES TO "' sequence_init '"'];
        clear pltexp_sequence_t pltexp_sequence_v %clear all sequences' persistent variables after any init button

    elseif strcmp(sequence_init, 'v')

        [ttl_tmp, val_v_out, val_i_out, val_roicen_out] = pltexp_sequence_v(user_input, save_buttons, roipixindp, varsz);
        if ~isempty(val_v_out)
            cbflags.val.v = [cbflags.val.v val_v_out];
            cbflags.val.i{cbflags.val.v(end)} = val_i_out;
            cbflags.val.roicen{cbflags.val.v(end)} = val_roicen_out;
        end


    elseif strcmp(sequence_init, 't')

        [ttl_tmp, cbflags.val.tinds, cbflags.val.sampinc] = pltexp_sequence_t(user_input, save_buttons, sampinc, ti, tinds_use);

    end

end


ttl = ttl_tmp;


end

