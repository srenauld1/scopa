function cbflags = process_callback_files(cbflags, pth_tmpfiles, varsz, ti)

fid = fopen([pth_tmpfiles 'tmp_cbf_.bin'], 'r');
if fid>=3
    tmpflag = fread(fid, '*uint16');
    fclose('all');
    delete([pth_tmpfiles 'tmp_cbf_.bin'])
    if tmpflag==1 %pressed enter
        if isempty(cbflags.getpvarind) && isempty(cbflags.gett1)
            if ~isempty(cbflags.getivarind) && ~ismember(cbflags.ivarind, 1:varsz(cbflags.pvarind, 1))
                cbflags.newtitle = ['INPUT VARIABLE #' num2str(cbflags.ivarind) ' DOES NOT EXIST FOR PLOT VARIABLE #' num2str(cbflags.pvarind) ', CHOOSE INDEX 1 TO ' num2str(varsz(cbflags.pvarind, 1))];
                cbflags.ivarind = [];
            elseif ~isempty(cbflags.gett2)
                if cbflags.tnew2>max(ti)
                    cbflags.newtitle = ['CHOSEN t END ' num2str(cbflags.tnew2) ' IS GREATER THAN AVAILABLE MAX t ' num2str(max(ti))];
                    cbflags.tnew2 = [];
                elseif cbflags.tnew2<=cbflags.tnew1
                    cbflags.newtitle = ['CHOSEN t END ' num2str(cbflags.tnew2) ' IS GREATER THAN CHOSEN t START ' num2str(cbflags.tnew1)];
                    cbflags.tnew2 = [];
                else
                    cbflags.restart_tloop = 1;
                    cbflags.tnew = [cbflags.tnew1 cbflags.tnew2];
                    cbflags.newtitle = ['PRESSED "enter", RESTARTING WITH NEW t RANGE ' mat2str(cbflags.tnew) ' SEC'];
                    cbflags.getpvarind = [];
                    cbflags.getivarind = [];
                    cbflags.gett1 = [];
                    cbflags.gett2 = [];
                end
            else
                cbflags.restart = 1;
                cbflags.newtitle = 'PRESSED "enter", RESTARTING WITH NEW TIMESERIES';
                cbflags.getpvarind = [];
                cbflags.getivarind = [];
                cbflags.gett1 = [];
                cbflags.gett2 = [];
            end
        elseif ~isempty(cbflags.getpvarind) && ~ismember(cbflags.pvarind, 1:size(varsz, 1))
            cbflags.newtitle = ['PLOT VARIABLE #' num2str(cbflags.pvarind) ' DOES NOT EXIST, CHOOSE INDEX 1 TO ' num2str(size(varsz, 1))];
            cbflags.getpvarind = 1;
            cbflags.pvarind = [];
        elseif ~isempty(cbflags.gett1)
            if cbflags.tnew1<min(ti)
                cbflags.newtitle = ['CHOSEN t START ' num2str(cbflags.tnew1) ' IS LESS THAN AVAILABLE MIN t ' num2str(min(ti))];
                cbflags.gett1 = 1;
                cbflags.tnew1 = [];
            else
                cbflags.newtitle = ['PRESSED "enter", NOW CHOOSE t END'];
                cbflags.gett1 = [];
                cbflags.gett2 = 1;
            end
        else
            cbflags.newtitle = ['PRESSED "enter", NOW CHOOSE HOW TO CHANGE PLOT VARIABLE #' num2str(cbflags.pvarind) ' BY PRESSING "i", OR CLICKING ON PLOT'];
        end
    elseif tmpflag==2
        cbflags.newtitle = 'PRESSED "p", PRESS DIGITS TO CHOOSE WHICH PLOT VARIABLE INDEX TO CHANGE';
        cbflags.getpvarind = 1;
        cbflags.getivarind = [];
        cbflags.gett1 = [];
        cbflags.gett2 = [];
        cbflags.pvarind = [];
    elseif tmpflag==3 && ~isempty(cbflags.getpvarind)
        cbflags.newtitle = ['PRESSED "i", PRESS DIGITS TO CHOOSE WHICH INPUT VARIABLE INDEX TO USE FOR PLOT VARIABLE #' num2str(cbflags.pvarind)];
        cbflags.getpvarind = [];
        cbflags.getivarind = 1;
    elseif tmpflag==4
        cbflags.newtitle = 'PRESSED "t", PRESS DIGITS TO CHOOSE START t';
        cbflags.gett1 = 1;
        cbflags.gett2 = [];
        cbflags.getivarind = [];
        cbflags.getpvarind = [];
        cbflags.tnew1 = [];
        cbflags.tnew2 = [];
    elseif tmpflag==9 && ~isempty(cbflags.getpvarind)
        cbflags.newtitle = 'PRESSED "backspace", PRESS ENTER TO CONFIRM REMOVE LAST ROI';
        cbflags.uiroidelete = 1;
        cbflags.gett1 = [];
        cbflags.gett2 = [];
        cbflags.getivarind = [];
        cbflags.getpvarind = [];
        cbflags.tnew1 = [];
        cbflags.tnew2 = [];
    end
end

if ~isempty(cbflags.getpvarind)
    fid = fopen([pth_tmpfiles 'tmp_cbf_uiroi_.bin'], 'r');
    if fid>=3
        cbflags.getpvarind = [];
        tmpflag = fread(fid, '*uint16');
        fclose('all');
        delete([pth_tmpfiles 'tmp_cbf_uiroi_.bin'])
        if tmpflag %pressed enter
            cbflags.newtitle = ['SELECTED VOXEL ' mat2str(vec(tmpflag)') ', PRESS ENTER TO MAKE THAT THE CURRENT ROI'];
            cbflags.uiroipixind = tmpflag;
        end
    end
end


if ~isempty(cbflags.gett1) || ~isempty(cbflags.gett2) %choose plot variable
    fid = fopen([pth_tmpfiles 'tmp_cbf_digit_.bin'], 'r');
    if fid>=3
        tmpflag_d = fread(fid, '*uint16');
        fclose('all');
        delete([pth_tmpfiles 'tmp_cbf_digit_.bin'])
        cbflags.newtitle = ['PRESSED ' num2str(tmpflag_d) ', WAITING FOR MORE DIGITS, OR PRESS ENTER TO FINALIZE START t'];
        if cbflags.gett1
            cbflags.tnew1 = [cbflags.tnew1 tmpflag_d];
            cbflags.tnew1 = str2double(strrep(num2str(cbflags.tnew1), ' ', ''));
        elseif cbflags.gett2
            cbflags.tnew2 = [cbflags.tnew2 tmpflag_d];
            cbflags.tnew2 = str2double(strrep(num2str(cbflags.tnew2), ' ', ''));
        end
    end
end

if ~isempty(cbflags.getpvarind) %choose plot variable
    fid = fopen([pth_tmpfiles 'tmp_cbf_digit_.bin'], 'r');
    if fid>=3
        tmpflag_d = fread(fid, '*uint16');
        fclose('all');
        delete([pth_tmpfiles 'tmp_cbf_digit_.bin'])
        cbflags.newtitle = ['PRESSED ' num2str(tmpflag_d) ', WAITING FOR MORE DIGITS, OR PRESS ENTER TO FINALIZE WHICH PLOT VARIABLE INDEX TO CHANGE'];
        cbflags.pvarind = [cbflags.pvarind tmpflag_d];
        cbflags.pvarind = str2double(strrep(num2str(cbflags.pvarind), ' ', ''));
    end
end

if ~isempty(cbflags.getivarind) %choose input variable
    fid = fopen([pth_tmpfiles 'tmp_cbf_digit_.bin'], 'r');
    if fid>=3
        tmpflag_d = fread(fid, '*uint16');
        fclose('all');
        delete([pth_tmpfiles 'tmp_cbf_digit_.bin'])
        cbflags.newtitle = ['PRESSED ' num2str(tmpflag_d) ', WAITING FOR MORE DIGITS, OR PRESS ENTER TO FINALIZE WHICH INPUT VARIABLE INDEX TO CHANGE'];
        cbflags.ivarind = [cbflags.ivarind tmpflag_d];
        cbflags.ivarind = str2double(strrep(num2str(cbflags.ivarind), ' ', ''));
    end
end

end
