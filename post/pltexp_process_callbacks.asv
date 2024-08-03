function cbflags = pltexp_process_callbacks(cbflags, hndls, varsz, varsp, roipixindp, ti, tinds_use, sampinc)


% structure this with only one possible route

if numel(cbflags.val.v)==numel(cbflags.changed.v)
    v_being_changed = 0;
else
    v_being_changed = 1; % v flag has been set but changes not finalized by pressing v again (to initiate another set of changes), or by pressing enter (to plot changes)
end

if ~isempty(hndls.hfg.UserData)

    tmpf = hndls.hfg.UserData;
    hndls.hfg.UserData = [];

    if all(structfun(@isempty, cbflags.get)) %if all 'get' flags are empty

        if strcmpi(tmpf, 'return') || strcmpi(tmpf, '0') % pressing enter plots any changes

            if cbflags.val.tinds
                cbflags.restart.t = 1;
                cbflags.lab.title = 'PRESSED "enter", CHANGING t';
            end

            if ~isempty(cbflags.val.roicen) || ~isempty(cbflags.val.i)
                if any(~cellfun(@isempty, cbflags.val.roicen))
                    cbflags.restart.v = 1;
                    cbflags.lab.title = 'PRESSED "enter", CHANGING plot variables';
                end
            end

            cbflags = reset_cbflags(cbflags, 'get', 'tmp');

        elseif strcmpi(tmpf, 'v')
            cbflags.lab.title = 'PRESSED "v", NOW PRESS DIGITS TO CHOOSE WHICH PLOT VARIABLE INDEX TO CHANGE';
            cbflags = reset_cbflags(cbflags, 'get', 'tmp');
            cbflags.get.v = 1;
            cbflags.changed.v

        elseif strcmpi(tmpf, 'i') && v_being_changed
            cbflags.lab.title = ['PRESSED "i", NOW PRESS DIGITS TO CHOOSE WHICH INPUT VARIABLE TO ASSIGN TO PLOT VARIABLE #' num2str(cbflags.val.v(end))];
            cbflags = reset_cbflags(cbflags, 'get', 'tmp');
            cbflags.get.i = 1;

        elseif strcmpi(tmpf, 't')
            cbflags.lab.title = 'PRESSED "t", NOW PRESS DIGITS FOR t START (SEC)';
            cbflags = reset_cbflags(cbflags, 'get', 'tmp');
            cbflags.get.tstart = 1;

        elseif strcmpi(tmpf, 'hyphen') && ~isempty(cbflags.tmp.tstart)
            if cbflags.tmp.tstart<min(ti)
                cbflags.lab.title = ['CHOSEN t START ' num2str(cbflags.tmp.tstart) ' IS LESS THAN AVAILABLE MIN t ' num2str(min(ti))];
                cbflags = reset_cbflags(cbflags, 'get', 'tmp');
            else
                cbflags.lab.title = ['PRESSED "hyphen", NOW PRESS DIGITS FOR t END (SEC)'];
                tmp2 = cbflags.tmp.tstart;
                cbflags = reset_cbflags(cbflags, 'get', 'tmp');
                cbflags.tmp.tstart = tmp2; %cheat with tmp2, so you can uniformly reset_cbflags get and tmp for all these (alternative is to make a val.tstart; this seemed the most symmetrical
                cbflags.get.tend = 1;
            end

        elseif strcmpi(tmpf, 'n') || strcmpi(tmpf, 'a') || strcmpi(tmpf, 'd')  % pressed 'n' or 'a' or 'd', meaning 'new' (overwrite) or 'add' or 'delete'


            if ~isempty(cbflags.tmp.v)
                if strcmpi(tmpf, 'n')
                    if ~ismember(cbflags.tmp.v, 1:size(varsz, 1))
                        cbflags.tmp.v = [];
                        cbflags.lab.title = ['PLOT VARIABLE #' num2str(cbflags.tmp.v) ' DOES NOT EXIST, CHOOSE INDEX 1 TO ' num2str(size(varsz, 1))];
                    else
                        cbflags.val.v = unique([cbflags.val.v cbflags.tmp.v]);
                        cbflags.lab.title = ['PRESSED "enter" TO PLACE FOCUS ON PLOT VARIABLE #' num2str(cbflags.val.v(end)) ' NOW CHOOSE HOW TO CHANGE IT'];
                    end
                else
                    error("currently can't use a or d with v")
                end


            elseif ~isempty(cbflags.tmp.i)
                if strcmpi(tmpf, 'n')
                    if ~ismember(cbflags.tmp.i, 1:varsz(cbflags.tmp.v, 1))
                        cbflags.tmp.i = [];
                        cbflags.lab.title = ['INPUT VARIABLE #' num2str(cbflags.tmp.i) ' DOES NOT EXIST FOR PLOT VARIABLE #' num2str(cbflags.tmp.v) ', CHOOSE INDEX 1 TO ' num2str(varsz(cbflags.tmp.v, 1))];
                    else
                        cbflags.val.i = unique([cbflags.val.i cbflags.tmp.i]);
                        cbflags.lab.title = ['PRESSED "enter", ASSIGNING INPUT VARIABLE # ' num2str(cbflags.val.i) ' TO PLOT VARIABLE # ' num2str(cbflags.val.v(end))];
                    end
                else
                    error("currently can't use a or d with v")
                end



            elseif ~isempty(cbflags.tmp.roicen)
                if strcmpi(tmpf, 'n')
                    cbflags.lab.title = ['PRESSED "n", OVERWRITING PLOT VARIABLE #' num2str(cbflags.tmp.v) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
                    cbflags.val.roicen{cbflags.val.v(end)} = [];
                end
                if strcmpi(tmpf, 'a')
                    cbflags.lab.title = ['PRESSED "a", ADDING TO EXISTING PLOT VARIABLE #' num2str(cbflags.tmp.v) ', MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES'];
                    if isempty(cbflags.changed.roicen)
                        error("this is pixel not centroid")
                        cbflags.val.roicen{cbflags.val.v(end)} = roipixindp;
                    end
                end
                cbflags.val.roicen{cbflags.val.v(end)} = unique( cat(1, cbflags.val.roicen{cbflags.val.v(end)}, cbflags.tmp.roicen), 'rows');
                cbflags.changed.roicen = 1;
                cbflags = reset_cbflags(cbflags, 'get', 'tmp'); %was just tmp


            elseif ~isempty(cbflags.tmp.tend)
                if cbflags.tmp.tend>max(ti)
                    cbflags.lab.title = ['CHOSEN t END ' num2str(cbflags.tmp.tend) ' IS GREATER THAN AVAILABLE MAX t ' num2str(max(ti))];
                elseif cbflags.tmp.tend<=cbflags.tmp.tstart
                    cbflags.lab.title = ['CHOSEN t END ' num2str(cbflags.tmp.tend) ' IS LESS THAN OR EQUAL TO CHOSEN t START ' num2str(cbflags.tmp.tstart)];
                else
                    t_tmp = [cbflags.val.tstart; cbflags.tmp.tend];
                    tinds_tmp = find(ti>=t_tmp(1) & ti<=t_tmp(2));
                    tinds_tmp = tinds_tmp(1):sampinc:tinds_tmp(end);
                    if strcmpi(tmpf, 'n')
                        cbflags.lab.title = 'PRESSED "n", OVERWRITING EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
                        cbflags.val.tinds = [];
                    end
                    if strcmpi(tmpf, 'a')
                        cbflags.lab.title = 'PRESSED "a", ADDING TO EXISTING t, MAKE MORE CHANGES OR PRESS ENTER TO PLOT CHANGES';
                        if isempty(cbflags.changed.t)
                            cbflags.val.tinds = tinds_use;
                        end
                    end
                    cbflags.val.tinds = unique([cbflags.val.tinds tinds_tmp]);
                    cbflags.changed.t = 1;
                end
                cbflags = reset_cbflags(cbflags, 'get', 'tmp');

            end

        end

    else %if there is a nonempty 'get' flag (get flag gives the ui digits their meaning)

        if cbflags.get.tstart % t start
            cbflags.tmp.tstart = [cbflags.tmp.tstart tmpf];
            cbflags.tmp.tstart = str2double(strrep(num2str(cbflags.tmp.tstart), ' ', ''));
            cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.tstart) ', PRESS MORE DIGITS FOR t START, OR PRESS HYPHEN TO ALLOW t END SELECTION'];
        elseif cbflags.get.tend % t end
            cbflags.tmp.tend = [cbflags.tmp.tend tmpf];
            cbflags.tmp.tend = str2double(strrep(num2str(cbflags.tmp.tend), ' ', ''));
            cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.tend) ', PRESS MORE DIGITS FOR t END, OR PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING t'];
        elseif cbflags.get.v % plot variable
            cbflags.tmp.v = [cbflags.tmp.v tmpf];
            cbflags.tmp.v = str2double(strrep(num2str(cbflags.tmp.v), ' ', ''));
            cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.v) ', WAITING FOR MORE DIGITS, OR PRESS ENTER TO FINALIZE WHICH PLOT VARIABLE INDEX TO CHANGE'];
        elseif cbflags.get.i % input variable
            cbflags.tmp.i = [cbflags.tmp.i tmpf];
            cbflags.tmp.i = str2double(strrep(num2str(cbflags.tmp.i), ' ', ''));
            cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.i) ', WAITING FOR MORE DIGITS, OR PRESS ENTER TO FINALIZE WHICH INPUT VARIABLE INDEX TO CHANGE'];
        end
        cbflags = reset_cbflags(cbflags, 'get'); %reset get flags


    end

elseif ~isempty(hndls.ts.hax{1}.UserData) % currently only full ts can have t callback, does not require a get flag (can click on t without any preceding event)

    tmpf = hndls.ts.hax{1}.UserData;
    hndls.ts.hax{1}.UserData = [];

    if isempty(cbflags.get.tend)
        cbflags.tmp.tstart = tmpf;
        cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.tstart) ', PRESS MORE DIGITS FOR t START, OR PRESS HYPHEN TO ALLOW t END SELECTION'];
        cbflags.get.tend = 1;
    else
        cbflags.tmp.tend = tmpf;
        cbflags.lab.title = ['PRESSED ' num2str(cbflags.tmp.tend) ', PRESS MORE DIGITS FOR t END, OR PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING t'];
    end


elseif any(~cellfun(@(x) isempty(x.UserData.roicen), hndls.st.hol)) && v_being_changed %clicking on stack images only marks rois if v index has been set (which timeseries to change)

    kpind = find(~cellfun(@(x) isempty(x.UserData.roicen), hndls.st.hol));
    if ~isempty(hndls.st.hol{kpind}.UserData.roicen)
        tmpf = hndls.st.hol{kpind}.UserData.roicen;
        hndls.st.hol{kpind}.UserData.roicen = [];
        cbflags.tmp.roicen = tmpf;
        cbflags.lab.title = ['CLICKED ' mat2str(vec(cbflags.tmp.roicen)') ', PRESS "n" TO OVERWRITE OR "a" TO ADD TO EXISTING ROI FOR PLOT VARIABLE #'];
    end

end







