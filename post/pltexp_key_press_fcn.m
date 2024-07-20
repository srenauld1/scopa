
function pltexp_key_press_fcn(hfg, event, varargin)

pth_tmpfiles = varargin{1};

eventkey = event.Key;
eventmod = event.Modifier;

if isstrprop(eventkey, 'digit')
    fid = fopen([pth_tmpfiles 'tmp_cbf_digit_.bin'], 'w');
    fwrite(fid, str2num(eventkey), 'uint16')
else

    if strcmpi(eventkey, 'return') || strcmpi(eventkey, '0')
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, 1, 'uint16');
        fclose('all');

    elseif strcmpi(eventkey, 'p')
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, 2, 'uint16');
        fclose('all');

    elseif strcmpi(eventkey, 'i')
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, 3, 'uint16');
        fclose('all');

    elseif strcmpi(eventkey, 'backspace')
        % error("undo not implemented yet")
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, 9, 'uint16');
        fclose('all');

    elseif strcmpi(eventkey, 'downarrow')
        scaleshift = -1;
        if strcmpi(eventmod, 'shift')
            scaleshift = -5;
        end
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, scaleshift, 'uint16')
        fclose('all');

    elseif strcmpi(eventkey, 'uparrow')
        scaleshift = 1;
        if strcmpi(eventmod, 'shift')
            scaleshift = 5;
        end
        fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'w');
        fwrite(fid, scaleshift, 'uint16')
        fclose('all');

    end

end


end

