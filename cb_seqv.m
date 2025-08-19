
function [ttl, val_v_out, val_i_out, val_roicen_out, val_vdel_out, val_varalpha] = cb_seqv(user_input, save_buttons, roipixindp_plane, varsz, numvar, val_varalpha)

persistent get_i
persistent get_c
persistent tmp_v
persistent tmp_i
persistent tmp_c
persistent tmp_varchan
persistent tmp_roicen
persistent require_channel_reentry
persistent changed_roicen
persistent subsequence_type
persistent val_v_out_tmp
persistent val_i_out_tmp
persistent val_roicen_out_tmp
persistent val_vdel_out_tmp

varalpha_inc = 0.05;


context_buttons = {'k', 'c'};
quick_buttons = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};

ttl = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

if isempty(val_v_out_tmp)
    if all(isstrprop(user_input, 'digit'))
        tmp_v = [tmp_v str2double(user_input)];
        tmp_v = str2double(strrep(num2str(tmp_v), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_v) ', CONTINUE ENTERING DIGITS, OR PRESS CONTEXT BUTTON TO CHANGE PLOT VARIABLE #' num2str(tmp_v)];
    else
        if ~isempty(tmp_v)
            if ~ismember(tmp_v, 1:numvar)
                ttl = ['PLOT VARIABLE #' num2str(tmp_v) ' DOES NOT EXIST, CHOOSE INDEX 1 TO ' num2str(numvar)];
                tmp_v = [];
            else
                val_v_out_tmp = tmp_v; %don't run unique in case you modify same v multiple times
            end
        end
    end
end

if ~isempty(val_v_out_tmp) %don't do elseif here because val_v_out_tmp gets set when another button is pressed

    if ~isempty(get_i) && all(isstrprop(user_input, 'digit'))

        [tmp_i, ttl] = get_digit_subsequence(tmp_i, user_input);

    elseif ~isempty(get_c) && all(isstrprop(user_input, 'digit'))

        [tmp_c, ttl] = get_digit_subsequence(tmp_c, user_input);

    elseif isnumeric(user_input) %&& isempty(subsequence_type)

        subsequence_type = 'click';
        tmp_roicen = user_input;
        ttl = ['CLICKED IMAGE VOXEL ' mat2str(vec(tmp_roicen)') ', PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING ROI FOR PLOT VARIABLE #' num2str(tmp_v)];

    elseif any(strcmpi(user_input, context_buttons)) %&& isempty(subsequence_type)

        subsequence_type = 'keyboard';
        if strcmpi(user_input, 'k')
            ttl = ['PRESSED "i", USE DIGITS TO CHOOSE WHICH INPUT VARIABLE TO ASSIGN TO PLOT VARIABLE #' num2str(val_v_out_tmp)];
            get_i = 1;
        elseif strcmpi(user_input, 'c')
            ttl = ['PRESSED "c", USE DIGITS TO CHOOSE WHICH SINGLE CHANNEL TO ADJUST, OR PRESS NO DIGIT TO MODIFY ALL AVAILABLE CHANNELS'];
            get_c = 1;
            require_channel_reentry = 0;
        end

    elseif any(strcmpi(user_input, quick_buttons)) % && isempty(subsequence_type)

        if ~ismember(tmp_c, 1:varsz(val_v_out_tmp, 3))
            ttl = ['CHANNEL #' num2str(tmp_c) ' DOES NOT EXIST FOR PLOT VARIABLE #' num2str(val_v_out_tmp) '; PRESS c AGAIN AND ENTER DIGIT TO MODIFY ONE CHANNEL, OR ENTER NO DIGIT TO MODIFY ALL AVAILABLE CHANNELS'];
            require_channel_reentry = 1;
        else
            if ~isequal(require_channel_reentry, 1) %require_channel_reentry~=1 doesn't work . . . without this, empty tmp_varchan will be read as all channels and arrows can have effect, after the first loop where tmp_c is set to empty; we don't want arrows to work for invalid channel
                if isempty(tmp_varchan) || ~isempty(tmp_c) || isequal(require_channel_reentry,0) %these 3 or expressions allows you to use v-arrow or v-c-arrow or c-arrow (after setting v) to change all channels, and v-c-number-arrow and c-number-arrow to change one channel 
                    tmp_varchan = tmp_c;
                end
                if isempty(tmp_varchan) %if it's still empty after being assigned tmp_c, it gets all channels
                    tmp_varchan = 1:varsz(val_v_out_tmp, 3);
                end
                [val_varalpha, ttl] = arrow_subsequence(val_varalpha, val_v_out_tmp, tmp_varchan, user_input, varalpha_inc);
                ttl = [ttl ', CHANNEL #' regexprep(num2str(tmp_varchan), ' +', ' and ')]; %in case multiple channels
            end
        end
        get_c = [];
        tmp_c = []; %no need to accumulate digits, tmp_c is for channels so can only be 1 or 2 or empty
        require_channel_reentry = [];


    elseif any(strcmpi(user_input, save_buttons))

        if strcmpi(user_input, 'd') && isempty(subsequence_type)

            val_vdel_out_tmp = 1;
            ttl = ['PRESSED "d", DELETING PLOT VARIABLE #' num2str(val_v_out_tmp)];

        elseif ~isempty(tmp_i) && ~isempty(subsequence_type)

            if ~ismember(tmp_i, 1:varsz(val_v_out_tmp, 1))
                tmp_i = [];
                ttl = ['INPUT VARIABLE #' num2str(tmp_i) ' DOES NOT EXIST FOR PLOT VARIABLE #' num2str(val_v_out_tmp) ', CHOOSE INDEX 1 TO ' num2str(varsz(val_v_out_tmp, 1))];
            else
                if strcmpi(user_input, 'n')
                    val_i_out_tmp = [];
                    ttl = ['PRESSED "n", OVERWRITING PLOT VARIABLE #' num2str(val_v_out_tmp) ' WITH INPUT VARIABLE #' num2str(tmp_i)];
                else
                    error('currently only save_button "n" works with context_button "i"');
                end
                val_i_out_tmp = unique([val_i_out_tmp tmp_i]);
            end

        elseif ~isempty(tmp_roicen) && ~isempty(subsequence_type)

            if strcmpi(user_input, 'n')
                ttl = ['PRESSED "n", OVERWRITING PLOT VARIABLE #' num2str(val_v_out_tmp) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
                val_roicen_out_tmp = [];
            elseif strcmpi(user_input, 'a')
                ttl = ['PRESSED "a", ADDING TO EXISTING PLOT VARIABLE #' num2str(val_v_out_tmp) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
                if isempty(changed_roicen)
                    val_roicen_out_tmp = roipixindp_plane;
                    error("roipixindp_plane contains roi pixels not roi centroid; insert find_centroid function")
                end
            end
            val_roicen_out_tmp = unique( cat(1, val_roicen_out_tmp, tmp_roicen), 'rows');
            changed_roicen = 1;

        end

        get_i = [];
        tmp_v = [];
        tmp_i = [];
        tmp_roicen = [];
        subsequence_type = [];

    end

end


val_v_out = val_v_out_tmp;
val_i_out = val_i_out_tmp;
val_roicen_out = val_roicen_out_tmp;
val_vdel_out = val_vdel_out_tmp;

end


function [varalpha, ttl] = arrow_subsequence(varalpha, val_v_out_tmp, tmp_varchan, user_input, inc)
not_val_v_out_tmp = setxor(1:size(varalpha,1), val_v_out_tmp);
not_tmp_varchan = setxor(1:size(varalpha,2), tmp_varchan);
if strcmpi(user_input, 'uparrow')
    ttl = ['PRESSED "uparrow", RAISING LINE ALPHA FOR PLOT VARIABLE #' num2str(val_v_out_tmp)];
    varalpha(val_v_out_tmp,tmp_varchan) = varalpha(val_v_out_tmp,tmp_varchan)+inc;
elseif strcmpi(user_input, 'downarrow')
    ttl = ['PRESSED "downarrow", LOWERING LINE ALPHA FOR PLOT VARIABLE #' num2str(val_v_out_tmp)];
    varalpha(val_v_out_tmp,tmp_varchan) = varalpha(val_v_out_tmp,tmp_varchan)-inc;
elseif strcmpi(user_input, 'rightarrow')
    ttl = ['PRESSED "rightarrow", RAISING LINE ALPHA FOR ALL PLOT VARIABLES EXCEPT #' num2str(val_v_out_tmp)];
    varalpha(not_val_v_out_tmp,not_tmp_varchan) = varalpha(not_val_v_out_tmp,not_tmp_varchan)+inc;
elseif strcmpi(user_input, 'leftarrow')
    ttl = ['PRESSED "leftarrow", LOWERING LINE ALPHA FOR ALL PLOT VARIABLES EXCEPT #' num2str(val_v_out_tmp)];
    varalpha(not_val_v_out_tmp,not_tmp_varchan) = varalpha(not_val_v_out_tmp,not_tmp_varchan)-inc;
end
varalpha(varalpha<0) = 0;
varalpha(varalpha>1) = 1;
end

function [tmp, ttl] = get_digit_subsequence(tmp, user_input)
tmp = [tmp str2double(user_input)];
tmp = str2double(strrep(num2str(tmp), ' ', ''));
ttl = ['PRESSED ' num2str(tmp) ', CONTINUE ENTERING DIGITS, OR PRESS NON-DIGIT TO USE ' num2str(tmp)];
end

