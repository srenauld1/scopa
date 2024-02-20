function [flag_choice] = checkrois(stack, roimask, title_prefix)

fontsize = 15;

numimcols = 2; %assume x is usually larger than y, hack to get decent resolution in montage
numimrows = ceil(size(stack, 3) / numimcols);

roimaskall = nan(size(stack, 1)*numimrows, size(stack, 2)*numimcols);
stackall = nan(size(stack, 1)*numimrows, size(stack, 2)*numimcols);
for tti = 1:size(stack, 3) %make a montage this way for portability (since function "montage" doesn't come with base matlab)
    [cltmp, rwtmp] = ind2sub([numimcols, numimrows], tti); %invert output of ind2sub since this is subplot layout
    rwinds = [1:size(stack, 1)] + size(stack, 1)*(rwtmp-1);
    clinds = [1:size(stack, 2)] + size(stack, 2)*(cltmp-1);
    stackall(rwinds,clinds) = stack(:,:,tti);
    roimaskall(rwinds,clinds) = roimask(:,:,tti);
end

overlay = rescale(0.2*rescale(roimaskall) + rescale(stackall, 0, 1));

hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;
imshow(overlay, 'InitialMagnification', 'fit')
axis image
figure(hfg)
set(hfg, 'KeyPressFcn', @roi_check_key_press_fcn);

title({title_prefix;
    'press "f" to move forward to the next roi, press "b" to move back and draw roi again, press "q" to quit drawing rois altogether for this region'}, ...
    'FontSize', fontsize)


pause(0.01);
fid = fopen('tmp_roi_flag_choice_.bin', 'r');
if fid>=3
    delete('tmp_roi_flag_choice_.bin') %try delete first in case you errored in the middle of drawing last time
    fclose(fid);
end

flag_choice = [];

while true
    
    pause(0.01);
    fid = fopen('tmp_roi_flag_choice_.bin', 'r');
    if fid>=3
        flag_choice = fread(fid, '*uchar');
        print(flag_choice)
        delete('tmp_roi_flag_b_.bin')
        fclose(fid);
    end


    pause(0.01);
    if flag_choice
        break;
    end

end

close;

end


function roi_check_key_press_fcn(hfg, event)

flag_choice = event.Key;

if strcmpi(flag_choice, 'f') || strcmpi(flag_choice, 'b') || strcmpi(flag_choice, 'q')
    close(hfg)
    fid = fopen('tmp_roi_flag_choice_.bin', 'wb');
    fwrite(fid, flag_choice, 'uchar');
    fclose(fid);
else
    fprintf('NOTHING WILL HAPPEN BECAUSE YOU DID NOT PRESS "f", "b", or "q" ')
end

end