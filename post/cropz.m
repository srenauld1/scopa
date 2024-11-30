function [zinds, stackmnt] = cropz(stackmnt, regionex_nounderscore)

numslice = size(stackmnt, 3);

h = stackplt(stackmnt, doui=1, dmplt='yxz', stackjust='center', szf=2);

h.httl.String = {
    ['choose z range (lower, upper) for regionex "' regionex_nounderscore '"'];
    'digits: choose z,    delete: undo last,    enter: accept z,    q: quit,    up/down: adjust contrast';
    };

ndt = numel(h.httl.String);

zchoose = [];
zinds = [];
scalefac = 1;
quit_flag = 0;
while true

    tmp = [];
    if ~isempty(h.hfg.UserData)
        tmp = h.hfg.UserData;
        h.hfg.UserData = [];
    end
    pause(0.01);


    if length(zinds)==2
        bndstr = 'upper';
    else
        bndstr = 'lower';
    end

    if strcmpi(tmp, 'uparrow') || strcmpi(tmp, 'downarrow')
        if strcmpi(tmp, 'uparrow')
            tmpd = -0.1;
        else
            tmpd = 0.1;
        end
        scalefac = scalefac + tmpd;
        for k = 1:numel(h.st.hpl)
            clim = h.st.hax{k}.CLim(2) + h.st.hax{k}.CLim(2)*tmpd;
            if clim<h.st.hax{k}.CLim(1)
                clim = h.st.hax{k}.CLim(1);
            end
            h.st.hax{k}.CLim(2) = clim;
        end
        h.httl.String{ndt+1} = ['RESCALED ORIGINAL CONTRAST BY ' num2str(-1*round((scalefac - 1)*100)) ' PERCENT'];
    end

    if ~isempty(tmp) && all(isstrprop(tmp, 'digit'))
        zchoosedigit = num2str(tmp);
        zchoose = [zchoose zchoosedigit];
        h.httl.String{ndt+2} = ['ENTERED SINGLE DIGIT ' zchoosedigit ', z ' bndstr ' limit frame is now ' zchoose ', ENTER ANOTHER DIGIT OR PRESS ENTER TO ACCEPT'];
    end

    if strcmpi(tmp, 'return') || strcmpi(tmp, '0') %pressed enter
        if length(zinds)<2
            zindstmp = str2double(zchoose);
            if any(~ismember(zindstmp, 1:numslice))
                h.httl.String{ndt+2} = ['YOU CHOSE A z ' bndstr ' LIMIT FRAME THAT IS OUT OF BOUNDS, THERE ARE ' num2str(numslice) ' z SLICES, TRY THIS LIMIT AGAIN' ];
            else
                proceedflag = 1;
                if length(zinds)==1
                    if zindstmp<zinds(1)
                        h.httl.String{ndt+2} = 'YOU CHOSE A z UPPER LIMIT FRAME THAT IS LOWER THAN THE LOWER LIMIT FRAME, TRY THIS LIMIT AGAIN';
                        proceedflag = 0;
                    end
                end
                if proceedflag
                    zinds = [zinds zindstmp];
                    h.httl.String{ndt+2} = ['PRESSED RETURN, MAKING z ' bndstr ' limit frame ' zchoose ];
                    if length(zinds)==2
                        h.httl.String{ndt+2} = [h.httl.String{ndt+2} ', PRESS ENTER AGAIN TO FINALIZE'];
                    end
                end
            end
        else
            quit_flag = 1;
        end
        zchoose = [];
    end

    if strcmpi(tmp, 'backspace') %pressed delete
        if length(zinds)>0 %if pressed delete and
            zinds(end) = [];
            h.httl.String{ndt+2} = 'PRESSED DELETE, REMOVING LAST Z LIM';
        else
            h.httl.String{ndt+2} = 'PRESSED DELETE, BUT NO Z LIM EXISTS SO DOING NOTHING';
        end
    end

    if strcmpi(tmp, 'q')  % pressed "q"
        quit_flag = 1;
    end


    if length(zinds)==0
        h.httl.String{ndt+3} = ['Z LIMITS ARE [?, ?]'];
    elseif length(zinds)==1
        h.httl.String{ndt+3} = ['Z LIMITS ARE: [' num2str(zinds(1)) ', ?]'];
    elseif length(zinds)==2
        h.httl.String{ndt+3} = ['Z LIMITS ARE: [' num2str(zinds(1)) ', ' num2str(zinds(2)) ']'];
    end

    if quit_flag
        zinds_str = regexprep( mat2str(zinds), {'\[', '\]', '\s+'}, {'', '', '-'});
        h.httl.String = {'QUITTING IN 1 SEC '; ['Z LIMITS ARE: [' zinds_str ']']};
        h.httl.String = '';
        pause(1)
        break;
    end

end

close(h.hfg)
if isempty(zinds)
    zinds = 1:numslice;
else
    zinds = min(zinds):max(zinds);
    stackmnt = stackmnt(:,:,zinds);
end


end

