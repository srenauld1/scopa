
function [subsequence_type, ttl, val_tinds] = pltexp_sequence_t(user_input, subsequence_type, save_buttons, sampinc, ti, tinds_use)

persistent get_tend
persistent tmp_tstart
persistent tmp_tend
persistent changed_t
persistent val_tinds_tmp

context_buttons = {'hyphen'};

if strcmp(subsequence_type, 'digit')
    ttl = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten
elseif strcmp(subsequence_type, 'click')
    ttl = 'CLICKED A STACK IMAGE OUT OF CONTEXT, NOTHING WILL HAPPEN'; %default title, in case not overwritten
end

if isstrprop(user_input, 'digit') | isnumeric(user_input)

    if get_tend
        if strcmp(subsequence_type, 'digit')
            tmp_tend = [tmp_tend str2double(user_input)];
            tmp_tend = str2double(strrep(num2str(tmp_tend), ' ', ''));
        elseif strcmp(subsequence_type, 'click')
            tmp_tend = user_input;
        end
        ttl = ['PRESSED ' num2str(tmp_tend) ', PRESS MORE DIGITS FOR t END, OR PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING t'];
    else
        if strcmp(subsequence_type, 'digit')
            tmp_tstart = [tmp_tstart str2double(user_input)];
            tmp_tstart = str2double(strrep(num2str(tmp_tstart), ' ', ''));
        elseif strcmp(subsequence_type, 'click')
            tmp_tstart = user_input;
            get_tend = 1;
        end
        ttl = ['PRESSED ' num2str(tmp_tstart) ', PRESS MORE DIGITS FOR t START, OR PRESS HYPHEN TO ALLOW t END SELECTION'];
    end

elseif any(strcmpi(user_input, context_buttons)) && strcmp(subsequence_type, 'digit') %for pltexp_sequence_t, 'hyphen' is only context_button right now, but more may come

    if strcmpi(user_input, 'hyphen')
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

elseif any(strcmpi(user_input, save_buttons))

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
        if strcmpi(user_input, 'n')
            ttl = 'PRESSED "n", OVERWRITING EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
            val_tinds_tmp = [];
        end
        if strcmpi(user_input, 'a')
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
        subsequence_type = [];

    end

end

val_tinds = val_tinds_tmp;

end


