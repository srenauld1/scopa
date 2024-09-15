function [zinds, stack3d] = croplim_z(stack3d, pth_tmpfiles, regionex_nounderscore)

fontsize_title = 20;
fontsize_xlabel = 25;

num_z_slice_original = size(stack3d, 3);

if num_z_slice_original>=3
    numimcolumns = 3; %assume x is usually larger than y, hack to get decent resolution in montage
else
    numimcolumns = num_z_slice_original; %assume x is usually larger than y, hack to get decent resolution in montage
end
marginsz = 2;
numimrows = ceil(size(stack3d, 3) / numimcolumns);
stack_mnt_flat = ones((size(stack3d, 1)+marginsz)*numimrows, (size(stack3d, 2)+marginsz)*numimcolumns);
marginx = ones(marginsz, size(stack3d, 2), size(stack3d, 3));
stack_mar = cat(1, marginx, stack3d);
marginy = ones(size(stack_mar, 1), marginsz, size(stack_mar, 3));
stack_mar = cat(2, marginy, stack_mar);
for tti = 1:num_z_slice_original %make a montage this way for portability (since function "montage" doesn't come with base matlab)
    [cltmp, rwtmp] = ind2sub([numimcolumns, numimrows], tti); %invert output of ind2sub since this is subplot layout
    rwinds = [1:size(stack_mar, 1)] + size(stack_mar, 1)*(rwtmp-1);
    clinds = [1:size(stack_mar, 2)] + size(stack_mar, 2)*(cltmp-1);
    stack_mnt_flat(rwinds,clinds) = stack_mar(:,:,tti);
end

stack_mnt_flat_rsc = stack_mnt_flat;
indnz = stack_mnt_flat~=0;

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    hfg = figure( 'Units', 'Normalized', 'Windowstyle', 'docked');
else
    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen');
end

set(hfg, 'KeyPressFcn', @(src,evnt)roi_key_press_fcn(src,evnt,pth_tmpfiles));

him = imshow(stack_mnt_flat, 'InitialMagnification', 'fit');
axis image


title({
    ['choose z indices for regions prefixed with "' regionex_nounderscore '" from this mean t image'];
    'press up / down arrows to adjust contrast up / down 10% (50% while also pressing shift) ';
    'press number keys to choose lower z limit (one-indexed), then accept with "enter", then choose upper z limit, then accept with "enter" ';
    'press "delete" to redo last step';
    'press "q" to quit z selection (will select all slices if none selected, or just one slice if one selected)';
    }, ...
    'FontSize', fontsize_title)


delete([pth_tmpfiles 'tmp_scaleshift_.bin']) %try delete first in case you errored in the middle of drawing last time
delete([pth_tmpfiles 'tmp_zchoose_.bin']) %try delete first in case you errored in the middle of drawing last time
delete([pth_tmpfiles 'tmp_controlin_.bin']) %try delete first in case you errored in the middle of drawing last time

zchoose = [];
zinds = [];
scalefac = 1;
quit_flag = 0;
while true

    if length(zinds)==2
        bndstr = 'upper';
    else
        bndstr = 'lower';
    end

    pause(0.01);
    fid = fopen([pth_tmpfiles 'tmp_scaleshift_.bin'], 'r');
    if fid>=3
        scaleshift = fread(fid, '*int8');
        fclose('all');
        delete([pth_tmpfiles 'tmp_scaleshift_.bin'])
        scalefac = scalefac + single(scaleshift)/10;
        if scalefac<0
            scalefac = 0;
        end
        stack_mnt_flat_rsc(indnz) = rescale(stack_mnt_flat(indnz), 0, scalefac);
        him.CData = stack_mnt_flat_rsc;
        him.Parent.XLabel.String{1} = ['RESCALED ORIGINAL CONTRAST BY ' num2str(round((scalefac - 1)*100)) ' PERCENT'];
    end

    pause(0.01);
    fid = fopen([pth_tmpfiles 'tmp_zchoose_.bin'], 'r');
    if fid>=3
        zchoosedigit = transpose(vec(char(fread(fid, '*uchar'))));
        fclose('all');
        delete([pth_tmpfiles 'tmp_zchoose_.bin'])
        zchoose = [zchoose zchoosedigit];
        him.Parent.XLabel.String{2} = ['ENTERED SINGLE DIGIT ' zchoosedigit ', z ' bndstr ' limit frame is now ' zchoose ', ENTER ANOTHER DIGIT OR PRESS ENTER TO ACCEPT'];
    end

    pause(0.01);
    fid = fopen([pth_tmpfiles 'tmp_controlin_.bin'], 'r');
    if fid>=3
        controlin = fread(fid, '*uint8');
        fclose('all');
        delete([pth_tmpfiles 'tmp_controlin_.bin'])
        if controlin==1 %pressed enter
            if length(zinds)<2
                zindstmp = str2double(zchoose);
                if any(~ismember(zindstmp, 1:num_z_slice_original))
                    him.Parent.XLabel.String{2} = ['YOU CHOSE A z ' bndstr ' LIMIT FRAME THAT IS OUT OF BOUNDS, THERE ARE ' num2str(num_z_slice_original) ' z SLICES, TRY THIS LIMIT AGAIN' ];
                else
                    proceedflag = 1;
                    if length(zinds)==1
                        if zindstmp<zinds(1)
                            him.Parent.XLabel.String{2} = 'YOU CHOSE A z UPPER LIMIT FRAME THAT IS LOWER THAN THE LOWER LIMIT FRAME, TRY THIS LIMIT AGAIN';
                            proceedflag = 0;
                        end
                    end
                    if proceedflag
                        zinds = [zinds zindstmp];
                        him.Parent.XLabel.String{2} = ['PRESSED RETURN, MAKING z ' bndstr ' limit frame ' num2str(zchoose) ];
                        if length(zinds)==2
                            him.Parent.XLabel.String{2} = [him.Parent.XLabel.String{2} ', PRESS ENTER AGAIN TO FINALIZE'];
                        end
                    end
                end
            else
                quit_flag = 1;
            end
            zchoose = [];
        elseif controlin==2 %pressed delete
            if length(zinds)>0 %if pressed delete and
                zinds(end) = [];
                him.Parent.XLabel.String{2} = 'PRESSED DELETE, REMOVING LAST Z LIM';
            else
                him.Parent.XLabel.String{2} = 'PRESSED DELETE, BUT NO Z LIM EXISTS SO DOING NOTHING';
            end
        elseif controlin==3  % pressed "q"
            quit_flag = 1;
        end

        controlin = 0;
    end


    if length(zinds)==0
        him.Parent.XLabel.String{3} = ['Z LIMITS ARE [?, ?]'];
    elseif length(zinds)==1
        him.Parent.XLabel.String{3} = ['Z LIMITS ARE: [' num2str(zinds(1)) ', ?]'];
    elseif length(zinds)==2
        him.Parent.XLabel.String{3} = ['Z LIMITS ARE: [' num2str(zinds(1)) ', ' num2str(zinds(2)) ']'];
    end
    him.Parent.XLabel.FontSize = fontsize_xlabel;

    if quit_flag
        zinds_str = regexprep( mat2str(zinds), {'\[', '\]', '\s+'}, {'', '', '-'});
        him.Parent.Title.String = {'QUITTING IN 3 SEC '; ['Z LIMITS ARE: [' zinds_str ']']};
        him.Parent.XLabel.String = '';
        pause(3)
        break;
    end

end

close(hfg)
if isempty(zinds)
    zinds = 1:num_z_slice_original;
else
    zinds = min(zinds):max(zinds);
    stack3d = stack3d(:,:,zinds);
end


end


function roi_key_press_fcn(hfg, event, varargin)

pth_tmpfiles = varargin{1};
eventkey = event.Key;
eventmod = event.Modifier;

if strcmpi(eventkey, 'downarrow')
    scaleshift = -1;
    if strcmpi(eventmod, 'shift')
        scaleshift = -5;
    end
    fid = fopen([pth_tmpfiles 'tmp_scaleshift_.bin'], 'w');
    fwrite(fid, scaleshift, 'int8')

elseif strcmpi(eventkey, 'uparrow')
    scaleshift = 1;
    if strcmpi(eventmod, 'shift')
        scaleshift = 5;
    end
    fid = fopen([pth_tmpfiles 'tmp_scaleshift_.bin'], 'w');
    fwrite(fid, scaleshift, 'int8')

elseif all(isstrprop(eventkey, 'digit'))
    fid = fopen([pth_tmpfiles 'tmp_zchoose_.bin'], 'w');
    fwrite(fid, eventkey, 'uchar')

elseif strcmpi(eventkey, 'return') || strcmpi(eventkey, '0')
    fid = fopen([pth_tmpfiles 'tmp_controlin_.bin'], 'w');
    fwrite(fid, 1, 'uint8')

elseif strcmpi(eventkey, 'backspace')
    fid = fopen([pth_tmpfiles 'tmp_controlin_.bin'], 'w');
    fwrite(fid, 2, 'uint8')

elseif strcmpi(eventkey, 'q')
    fid = fopen([pth_tmpfiles 'tmp_controlin_.bin'], 'w');
    fwrite(fid, 3, 'uint8')


end

fclose('all');

end
