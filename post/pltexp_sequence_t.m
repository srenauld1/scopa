
function [ttl, val_tinds] = pltexp_sequence_t(tmp_button, tmp_click_t, save_buttons, sampinc, ti, tinds_use)

persistent get_tend
persistent tmp_tstart
persistent tmp_tend
persistent digit_sequence
persistent changed_t
persistent val_tinds_tmp

context_buttons = {'hyphen'};

if ~isempty(tmp_click_t)
    tmp_button = tmp_click_t;
    digit_sequence = 0;
else
    digit_sequence = 1;
end

if isstrprop(tmp_button, 'digit') | isnumeric(tmp_button)

    if get_tend
        if digit_sequence
            tmp_tend = [tmp_tend str2double(tmp_button)];
            tmp_tend = str2double(strrep(num2str(tmp_tend), ' ', ''));
        else
            tmp_tend = tmp_button;
        end
        ttl = ['PRESSED ' num2str(tmp_tend) ', PRESS MORE DIGITS FOR t END, OR PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING t'];
    else
        if digit_sequence
            tmp_tstart = [tmp_tstart str2double(tmp_button)];
            tmp_tstart = str2double(strrep(num2str(tmp_tstart), ' ', ''));
        else
            tmp_tstart = tmp_button;
            get_tend = 1;
        end
        ttl = ['PRESSED ' num2str(tmp_tstart) ', PRESS MORE DIGITS FOR t START, OR PRESS HYPHEN TO ALLOW t END SELECTION'];
    end

elseif any(strcmpi(tmp_button, context_buttons)) %for pltexp_sequence_t, 'hyphen' is only context_button right now, but more may come

    if strcmpi(tmp_button, 'hyphen') & digit_sequence
        if ~isempty(tmp_tstart)
            if tmp_tstart<min(ti)
                ttl = ['CHOSEN t START ' num2str(tmp_tstart) ' IS LESS THAN AVAILABLE MIN t ' num2str(min(ti)) '; MAKING THIS t start EMPTY'];
                tmp_tstart = [];
            elseif tmp_tstart>max(ti)
                ttl = ['CHOSEN t START ' num2str(tmp_tstart) ' IS GREATER THAN AVAILABLE MAX t ' num2str(max(ti)) '; MAKING THIS t start EMPTY'];
                tmp_tstart = [];
            else
                ttl = 'PRESSED "hyphen", NOW USE DIGITS TO CHOOSE t END (SECONDS)';
                get_tend = 1;
            end
        end
    end

elseif any(strcmpi(tmp_button, save_buttons))

    if tmp_tend>max(ti)
        ttl = ['CHOSEN t END ' num2str(tmp_tend) ' IS GREATER THAN AVAILABLE MAX t ' num2str(max(ti))];
        tmp_tend = [];
    elseif tmp_tend<=tmp_tstart
        ttl = ['CHOSEN t END ' num2str(tmp_tend) ' IS LESS THAN OR EQUAL TO CHOSEN t START ' num2str(tmp_tstart)];
        tmp_tend = [];
    else
        t_tmp = [tmp_tstart; tmp_tend];
        tinds_tmp = find(ti>=t_tmp(1) & ti<=t_tmp(2));
        tinds_tmp = tinds_tmp(1):sampinc:tinds_tmp(end);
        if strcmpi(tmp_button, 'n')
            ttl = 'PRESSED "n", OVERWRITING EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
            val_tinds_tmp = [];
        end
        if strcmpi(tmp_button, 'a')
            ttl = 'PRESSED "a", ADDING TO EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
            if isempty(changed_t)
                val_tinds_tmp = tinds_use;
            end
        end
        val_tinds_tmp = unique([val_tinds_tmp tinds_tmp]);
        changed_t = 1;

        get_tend = [];
        tmp_tend = [];
        tmp_tstart = [];
        digit_sequence = [];

    end

end

val_tinds = val_tinds_tmp;

end


