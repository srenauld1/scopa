
function [ttl, val_v_out, val_i_out, val_roicen_out] = pltexp_sequence_v(user_input, save_buttons, roipixindp, varsz)

persistent v_not_set
if isempty(v_not_set) %empty when first initialized, 1 when not set, 0 when set
    v_not_set = 1;
end
persistent get_i
persistent tmp_v
persistent tmp_i
persistent tmp_roicen
persistent changed_roicen
persistent subsequence_type
persistent val_v_out_tmp
persistent val_i_out_tmp
persistent val_roicen_out_tmp

context_buttons = {'i'};

ttl = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

if isstrprop(user_input, 'digit')

    if v_not_set
        tmp_v = [tmp_v str2double(user_input)];
        tmp_v = str2double(strrep(num2str(tmp_v), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_v) ', CONTINUE ENTERING DIGITS, OR PRESS CONTEXT BUTTON TO CHANGE PLOT VARIABLE #' num2str(tmp_v)];
    elseif get_i
        tmp_i = [tmp_i str2double(user_input)];
        tmp_i = str2double(strrep(num2str(tmp_i), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_i) ', CONTINUE ENTERING DIGITS, OR PRESS SAVE BUTTON TO USE INPUT VARIABLE #' num2str(tmp_i)];
    end

elseif ( any(strcmpi(user_input, context_buttons)) || isnumeric(user_input) ) && ~isempty(tmp_v)

    if v_not_set %once an intermediate button is pressed v is set 
        if ~ismember(tmp_v, 1:size(varsz, 1))
            ttl = ['PLOT VARIABLE #' num2str(tmp_v) ' DOES NOT EXIST, CHOOSE INDEX 1 TO ' num2str(size(varsz, 1))];
            return;
        end
        v_not_set = 0;
    end

    if isnumeric(user_input) %click is numeric, keyboard is char
        subsequence_type = 'click';
        tmp_roicen = user_input;
        ttl = ['CLICKED ' mat2str(vec(tmp_roicen)') ', PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING ROI FOR PLOT VARIABLE #'];
    elseif ischar(user_input)
        subsequence_type = 'keyboard';
        if strcmpi(user_input, 'i')
            ttl = ['PRESSED "i", USE DIGITS TO CHOOSE WHICH INPUT VARIABLE TO ASSIGN TO PLOT VARIABLE #' num2str(tmp_v)];
            get_i = 1;
        end
    end

elseif any(strcmpi(user_input, save_buttons)) && ~isempty(subsequence_type)

    val_v_out_tmp = tmp_v; %don't run unique in case you modify same v multiple times

    if ~isempty(tmp_i)

        if ~ismember(tmp_i, 1:varsz(val_v_out_tmp, 1))
            tmp_i = [];
            ttl = ['INPUT VARIABLE #' num2str(tmp_i) ' DOES NOT EXIST FOR PLOT VARIABLE #' num2str(val_v_out_tmp) ', CHOOSE INDEX 1 TO ' num2str(varsz(val_v_out_tmp, 1))];
        else
            if strcmpi(user_input, 'n')
                val_i_out_tmp = [];
                ttl = ['PRESSED "n", OVERWRITING PLOT VARIABLE # ' num2str(val_v_out_tmp) ' WITH INPUT VARIABLE # ' num2str(tmp_i)];
            else
                error('currently only save_button "n" works with context_button "i"');
            end
            val_i_out_tmp = unique([val_i_out_tmp tmp_i]);
        end

    elseif ~isempty(tmp_roicen)

        if strcmpi(user_input, 'n')
            ttl = ['PRESSED "n", OVERWRITING PLOT VARIABLE #' num2str(val_v_out_tmp) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
            val_roicen_out_tmp = [];
        elseif strcmpi(user_input, 'a')
            ttl = ['PRESSED "a", ADDING TO EXISTING PLOT VARIABLE #' num2str(val_v_out_tmp) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
            if isempty(changed_roicen)
                val_roicen_out_tmp = roipixindp;
                error("roipixindp contains roi pixels not roi centroid; insert find_centroid function")
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


val_v_out = val_v_out_tmp;
val_i_out = val_i_out_tmp;
val_roicen_out = val_roicen_out_tmp;

end
