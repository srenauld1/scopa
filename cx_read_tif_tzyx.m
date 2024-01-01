function out = cx_read_tif_tzyx(filename_tif, ...
    out_datatype, size_read_to, ...
    size_z_read_from, size_t_read_from, ...
    inds_z_read_from, inds_t_read_from)

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


% TiffInfo=tiff_read_header(filename_tif);

tsStack = TIFFStack(filename_tif); % Construct a TIFF stack associated with a file

tsStack = TIFFStack(filename_tif, true); % Indicate that the image data should be inverted 
   % tsStack = 
   %   TIFFStack handle 
   %   Properties: 
   %      bInvert: 1 
   %      strFilename: [1x9 char] 
   %      sImageInfo: [5x1 struct] 
   %      strDataClass: 'uint16'


allow_data_type_conversion = 0;

info1 = imfinfo(filename_tif);
stripOffset = info1(1).StripOffsets;
stripByteCounts = info1(1).StripByteCounts;
sz_x=info1(1).Width;
sz_y=info1(1).Height;
if length(info1)<2
    num_z_times_num_t=floor(info1(1).FileSize/stripByteCounts);
else
    num_z_times_num_t=length(info1);
end


fID = fopen (filename_tif, 'r');

start_point = stripOffset(1) + (0:1:(num_z_times_num_t-1)).*stripByteCounts + 1;

final_frame_flag_count = 0;
count_all = 0;
count_ti = 0;
for ti = 1:size_t_read_from
    if  ismember(ti, inds_t_read_from)
        count_ti = count_ti + 1;
    end
    
    count_zi = 0;
    for zi = 1:size_z_read_from

        count_all = count_all + 1;
        
        fseek (fID, start_point(count_all), 'bof'); 

        if ismember(zi, inds_z_read_from) & ismember(ti, inds_t_read_from)
            count_zi = count_zi + 1;
            
            if info1(1).BitDepth==32
                tmpframe = fread(fID, [size_read_to(4) size_read_to(3)], 'uint32=>uint32');
            elseif info1(1).BitDepth==16
                tmpframe = fread(fID, [size_read_to(4) size_read_to(3)], 'uint16=>uint16');
            else
                tmpframe = fread(fID, [size_read_to(4) size_read_to(3)], 'uint8=>uint8');
            end

            if count_ti==1 & count_zi==1 %on first frame, find data type and create output array
                in_datatype = class(tmpframe);
                out = zeros(size_read_to, in_datatype);
            end
                
            out(count_ti,count_zi,:,:) = tmpframe';


        end

    end
end

% out = permute(out, [2 3 1]);
% out = reshape(out, size_read_to(2), size_read_to(3), length(inds_t_read_from), length(inds_z_read_from));
out = permute(out, [3 4 2 1]); %reshape into y x z t

fclose(fID);


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



