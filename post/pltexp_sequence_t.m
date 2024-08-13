
function [ttl, val_tinds, val_sampinc] = pltexp_sequence_t(user_input, save_buttons, sampinc_in, ti, tinds_in)

persistent get_tend
persistent get_sampinc
persistent tmp_tstart
persistent tmp_tend
persistent tmp_sampinc
persistent changed_t
persistent subsequence_type
persistent val_tinds_tmp
persistent val_sampinc_tmp

context_buttons = {'hyphen', 's'};

ttl = ['PRESSED ' num2str(user_input) ' OUT OF CONTEXT, NOTHING WILL HAPPEN']; %default title, in case not overwritten

if isstrprop(user_input, 'digit') || isnumeric(user_input)

    if get_tend
        if strcmp(subsequence_type, 'keyboard')
            tmp_tend = [tmp_tend str2double(user_input)];
            tmp_tend = str2double(strrep(num2str(tmp_tend), ' ', ''));
        elseif strcmp(subsequence_type, 'click')
            tmp_tend = user_input;
        end
        ttl = ['PRESSED ' num2str(tmp_tend) ', PRESS MORE DIGITS FOR t END, OR PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING t'];
    elseif get_sampinc
        tmp_sampinc = [tmp_sampinc str2double(user_input)];
        tmp_sampinc = str2double(strrep(num2str(tmp_sampinc), ' ', ''));
        ttl = ['PRESSED ' num2str(tmp_sampinc) ', PRESS MORE DIGITS FOR sampinc, OR PRESS "n" TO OVERWRITE CURRENT sampinc'];
    else
        if ischar(user_input) %click is numeric, keyboard is char
            subsequence_type = 'keyboard';
            tmp_tstart = [tmp_tstart str2double(user_input)];
            tmp_tstart = str2double(strrep(num2str(tmp_tstart), ' ', ''));
        elseif isnumeric(user_input)
            subsequence_type = 'click';
            tmp_tstart = user_input;
            get_tend = 1;
        end
        ttl = ['PRESSED ' num2str(tmp_tstart) ', PRESS MORE DIGITS FOR t START, OR PRESS HYPHEN TO ALLOW t END SELECTION'];
    end

elseif any(strcmpi(user_input, context_buttons)) 

    if strcmpi(user_input, 'hyphen') && strcmp(subsequence_type, 'keyboard')
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
    elseif strcmpi(user_input, 's') && isempty(subsequence_type)
        ttl = 'PRESSED "s", NOW USE DIGITS TO CHOOSE SAMPINC (SAMPLE INCREMENT, NOT SECONDS)';
        get_sampinc = 1;
        subsequence_type = 'sampinc';
    end

elseif any(strcmpi(user_input, save_buttons))

    if ~isempty(tmp_sampinc) && strcmp(subsequence_type, 'sampinc')

        if strcmpi(user_input, 'n')
            val_sampinc_tmp = tmp_sampinc;
            ttl = 'PRESSED "n", OVERWRITING EXISTING sampinc, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
            get_tend = [];
            get_sampinc = [];
            tmp_tend = [];
            tmp_tstart = [];
            tmp_sampinc = [];
            subsequence_type = [];
        else
            ttl = 'FOR CHANGING SAMPINC, ONLY SAVE BUTTON "n" IS ALLOWED; DOING NOTHING';
        end

    elseif ~isempty(tmp_tend) && ( strcmp(subsequence_type, 'keyboard') || strcmp(subsequence_type, 'click') )

        if tmp_tend>max(ti)
            ttl = ['CHOSEN t END ' num2str(tmp_tend) ' IS GREATER THAN AVAILABLE MAX t ' num2str(max(ti))];
            tmp_tend = [];
        elseif tmp_tend<=tmp_tstart
            ttl = ['CHOSEN t END ' num2str(tmp_tend) ' IS LESS THAN OR EQUAL TO CHOSEN t START ' num2str(tmp_tstart)];
            tmp_tend = [];
        else

            if isempty(val_sampinc_tmp)
                val_sampinc_tmp = sampinc_in;
            end

            t_tmp = [tmp_tstart; tmp_tend];
            tinds_tmp = find(ti>=t_tmp(1) & ti<=t_tmp(2));
            tinds_tmp = tinds_tmp(1):val_sampinc_tmp:tinds_tmp(end);
            if strcmpi(user_input, 'n')
                ttl = 'PRESSED "n", OVERWRITING EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
                val_tinds_tmp = [];
            elseif strcmpi(user_input, 'a')
                ttl = 'PRESSED "a", ADDING TO EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
                if isempty(changed_t)
                    val_tinds_tmp = tinds_in;
                end
            end
            val_tinds_tmp = unique([val_tinds_tmp tinds_tmp]);
            changed_t = 1;

            get_tend = [];
            get_sampinc = [];
            tmp_tend = [];
            tmp_tstart = [];
            tmp_sampinc = [];
            subsequence_type = [];

        end

    end

end

val_tinds = val_tinds_tmp;
val_sampinc = val_sampinc_tmp;

end


