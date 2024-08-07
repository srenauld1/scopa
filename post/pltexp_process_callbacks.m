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


persistent init_t
persistent init_v
persistent changed_v
persistent ttl_tmp


plot_buttons = {'return'};
init_buttons = {'v', 't'};
save_buttons = {'n', 'a', 'c', 'backspace'};


if numel(cbflags.val.v)==numel(changed_v)
    v_being_changed = 0;
else
    v_being_changed = 1; % v flag has been set but changes not finalized by pressing v again (to initiate another set of changes), or by pressing enter (to plot changes)
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

    if any(strcmpi(user_input, plot_buttons))  % pressing enter plots any changes

        if cbflags.val.tinds
            cbflags.restart.t = 1;
            ttl_tmp = 'PRESSED "enter", CHANGING t';
        end

        if ~isempty(cbflags.val.roicen) || ~isempty(cbflags.val.i) %don't use elseif since there can be v and t changes
            if any(~cellfun(@isempty, cbflags.val.roicen))
                cbflags.restart.v = 1;
                ttl_tmp = 'PRESSED "enter", CHANGING plot variables';
            end
        end


    elseif any(strcmpi(user_input, init_buttons))

        if strcmpi(user_input, 'v')
            init_v = 1;
            changed_v = [changed_v 1];
            ttl_tmp = 'PRESSED "v", USE DIGITS TO CHOOSE WHICH PLOTTED VARIABLE TO CHANGE';
        elseif strcmpi(user_input, 't')
            init_t = 1;
            ttl_tmp = 'PRESSED "t", USE DIGITS OR CLICKS TO CHANGE t (SECONDS)';
        end

        clear pltexp_sequence_t pltexp_sequence_v %clear all sequences' persistent variables after any init button


    elseif ~isempty(init_v)

        [ttl_tmp, cbflags.val.v, cbflags.val.i, cbflags.val.roicen] = pltexp_sequence_v(user_input, user_input, save_buttons, v_being_changed, roipixindp, varsz);

    elseif ~isempty(init_t)

        [ttl_tmp, cbflags.val.tinds] = pltexp_sequence_t(user_input, user_input, save_buttons, sampinc, ti, tinds_use);

    end

end


ttl = ttl_tmp;


end

