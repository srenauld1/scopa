function out = read_tif_tzyx_deprecated(filename_tif, ...
    out_datatype, size_read_to, ...
    size_z_read_from, size_t_read_from, ...
    inds_z_read_from, inds_t_read_from)

"this version is very fast, but fails for tif with more than 65536 (2^16) slices (slices means z times t)"
% error

allow_data_type_conversion = 0;

%scanimage writes as tzyx, 
% and so does scopa python pipeline 
% (registration,denoising, roi extraction)
%so read it like this, then permute output afterwards
%option to just read a subset of z and t indices to save time
%size_z_read_from and size_t_read_from must match z and t dimensions of tif
%inds_z_read_from and size_t_read_from can be used to only read those z and t indices 
%out_datatype defines output data type, 
% if allow_data_type_conversion==1 the tif datatype can be converted to
% out_datatype, but this is a work in progress so it's 0 by default 
%if tif is 3d (one z slice) then size_z_read_from==1 and it works fine 

tr = Tiff(filename_tif, 'r');

final_frame_flag_count = 0;
countz_ti = 0;
for ti = 1:size_t_read_from
    if  ismember(ti, inds_t_read_from)
        countz_ti = countz_ti + 1;
    end
    % if mod(ti, 100)==0
    %     display(["on frame " num2str(ti)])
    % end
    countz_zi = 0;
    for zi = 1:size_z_read_from
        if ismember(zi, inds_z_read_from) & ismember(ti, inds_t_read_from)
            countz_zi = countz_zi + 1;
            if countz_ti==1 & countz_zi==1 %on first frame, find data type and create output array
                tmpframe = tr.read();
                in_datatype = class(tmpframe);
                out = zeros(size_read_to, in_datatype);
                out(countz_ti,countz_zi,:,:) = tmpframe; 
            else
                out(countz_ti,countz_zi,:,:) = tr.read(); %tiff read faster than imread
            end
        end
        try
            tr.nextDirectory()
        catch
            "FINAL TIF FRAME"
            final_frame_flag_count = final_frame_flag_count + 1;
        end
    end
end

if final_frame_flag_count>1
    sprintf([ 'message FINAL TIF FRAME appeared multiple times' newline ...
        'two possible reasons are ' newline ...
        '1. you''re reading a raw tif output from scanimage and the header is different ' newline ...
        'than the headers this function was written to process, proceed with caution ' newline ...
        '2. you tried to read too many frames, ' newline ...
        'meaning size_z_read_from and/or size_t_read_from may be too large, ' newline ... 
        'stack read will be wrong if size_z_read_from is wrong, ' newline ...
        'stack read will be fine but slow if size_t_read_from is too large,' newline ...
        'but this should not occur if you''re using the metadatanew.mat file to determine these values,' newline ...
        'in which case #1 seems more likely'])
end

% out = permute(out, [2 3 1]);
% out = reshape(out, size_read_to(2), size_read_to(3), length(inds_t_read_from), length(inds_z_read_from));
out = permute(out, [3 4 2 1]); %reshape into y x z t

%make minimal required adjustments to switch data types
if ~strcmp(in_datatype, out_datatype)
    if ~allow_data_type_conversion
        "ERROR, DATA TYPE MISMATCH"
        error
    else
        "WARNING, DATA TYPE MISMATCH, CONVERTING"
        switch in_datatype
            case'double'
                error

            case 'single'
                error

            otherwise
                inprec = str2double(regexp(in_datatype,'\d*','Match'));
                outprec = str2double(regexp(out_datatype,'\d*','Match'));
                minout = min(out(:));
                if minout<0 & startsWith(out_datatype, 'uint')
                    out = single(out);
                    out = out - double(minout);
                end
                if inprec<=outprec
                    eval(['out = ' out_datatype '(out);'])
                elseif inprec>outprec
                    maxout = max(out(:));
                    if maxout > 2^outprec-1
                        "ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE"
                        error
                    else
                        eval(['out = ' out_datatype '(out);'])
                    end
                end
        end
    end
end

close(tr)

