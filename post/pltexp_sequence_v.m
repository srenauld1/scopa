
function [ttl, val_v_out, val_i_out, val_roicen_out, val_vdel_out, val_linealpha_out] = pltexp_sequence_v(user_input, save_buttons, roipixindp, varsz)

persistent get_i
persistent tmp_v
persistent tmp_i
persistent tmp_roicen
persistent changed_roicen
persistent subsequence_type
persistent val_v_out_tmp
persistent val_i_out_tmp
persistent val_roicen_out_tmp
persistent val_vdel_out_tmp
persistent val_linealpha_out_tmp

linealpha_inc = 0.05;
context_buttons = {'i'};
quick_buttons = {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'};

ttl = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

if isempty(val_v_out_tmp) 
    if isstrprop(user_input, 'digit')
        tmp_v = [tmp_v str2double(user_input)];
        tmp_v = str2double(strrep(num2str(tmp_v), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_v) ', CONTINUE ENTERING DIGITS, OR PRESS CONTEXT BUTTON TO CHANGE PLOT VARIABLE #' num2str(tmp_v)];
    else
        if ~isempty(tmp_v)
            if ~ismember(tmp_v, 1:size(varsz, 1))
                ttl = ['PLOT VARIABLE #' num2str(tmp_v) ' DOES NOT EXIST, CHOOSE INDEX 1 TO ' num2str(size(varsz, 1))];
            else
                val_v_out_tmp = tmp_v; %don't run unique in case you modify same v multiple times
            end
        end
    end
end

if ~isempty(val_v_out_tmp) %don't do elseif here because val_v_out_tmp gets set when another button is pressed

    if ~isempty(get_i) && isstrprop(user_input, 'digit')

        tmp_i = [tmp_i str2double(user_input)];
        tmp_i = str2double(strrep(num2str(tmp_i), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_i) ', CONTINUE ENTERING DIGITS, OR PRESS SAVE BUTTON TO USE INPUT VARIABLE #' num2str(tmp_i)];

    elseif isnumeric(user_input) && isempty(subsequence_type)

        subsequence_type = 'click';
        tmp_roicen = user_input;
        ttl = ['CLICKED ' mat2str(vec(tmp_roicen)') ', PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING ROI FOR PLOT VARIABLE #'];

    elseif any(strcmpi(user_input, context_buttons)) && isempty(subsequence_type)

        subsequence_type = 'keyboard';
        if strcmpi(user_input, 'i')
            ttl = ['PRESSED "i", USE DIGITS TO CHOOSE WHICH INPUT VARIABLE TO ASSIGN TO PLOT VARIABLE #' num2str(val_v_out_tmp)];
            get_i = 1;
        end

    elseif any(strcmpi(user_input, quick_buttons)) && isempty(subsequence_type)

        latmp = zeros(1, size(varsz, 1));
        if strcmpi(user_input, 'uparrow')
            ttl = ['PRESSED "uparrow", RAISING LINE ALPHA FOR PLOT VARIABLE #' num2str(val_v_out_tmp)];
            latmp(val_v_out_tmp) = linealpha_inc;
        elseif strcmpi(user_input, 'downarrow')
            ttl = ['PRESSED "downarrow", LOWERING LINE ALPHA FOR PLOT VARIABLE #' num2str(val_v_out_tmp)];
            latmp(val_v_out_tmp) = -linealpha_inc;
        elseif strcmpi(user_input, 'rightarrow')
            ttl = ['PRESSED "rightarrow", RAISING LINE ALPHA FOR ALL PLOT VARIABLES EXCEPT #' num2str(val_v_out_tmp)];
            latmp = latmp+linealpha_inc;
            latmp(val_v_out_tmp) = 0;
        elseif strcmpi(user_input, 'leftarrow')
            ttl = ['PRESSED "leftarrow", LOWERING LINE ALPHA FOR ALL PLOT VARIABLES EXCEPT #' num2str(val_v_out_tmp)];
            latmp = latmp-linealpha_inc;
            latmp(val_v_out_tmp) = 0;
        end
        val_linealpha_out_tmp = num2cell(latmp);

    elseif any(strcmpi(user_input, save_buttons))

        if strcmpi(user_input, 'd') && isempty(subsequence_type)

            val_vdel_out_tmp = 1;
            ttl = ['PRESSED "d", DELETING PLOT VARIABLE # ' num2str(val_v_out_tmp)];

        elseif ~isempty(tmp_i) && ~isempty(subsequence_type)

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

        elseif ~isempty(tmp_roicen) && ~isempty(subsequence_type)

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

end


val_v_out = val_v_out_tmp;
val_i_out = val_i_out_tmp;
val_roicen_out = val_roicen_out_tmp;
val_vdel_out = val_vdel_out_tmp;
val_linealpha_out = val_linealpha_out_tmp;

end
