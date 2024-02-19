function cx_update_tif(inp, filename_read, filename_write)

inp = reshape(inp, size(inp, 1), size(inp, 2), []);
tr = Tiff(filename_read, 'r');

% tag_struct = struct;
% tag_struct.SubFileType = 0;
% tag_struct.ImageWidth = 256;
% tag_struct.ImageLength = 140;
% tag_struct.BitsPerSample = 16;
% tag_struct.Compression = 1;
% tag_struct.Photometric = 1;
% %tag_struct.StripOffsets = 22024; %Tag number (273) is unrecognized by the TIFF library.
% tag_struct.Orientation = 1;
% tag_struct.SamplesPerPixel = 1;
% tag_struct.RowsPerStrip = 140;
% % tag_struct.StripByteCounts = 71680;
% tag_struct.MinSampleValue = 0;
% tag_struct.MaxSampleValue = 65535;
% tag_struct.XResolution = 1.2174e+04;
% tag_struct.YResolution = 1.2174e+04;
% tag_struct.PlanarConfiguration = 1;
% tag_struct.ResolutionUnit = 3;
% %tag_struct.NumberOfInks = 4;
% tag_struct.SampleFormat = 2;
% %tag_struct.YCbCrSubSampling = [2 2];
% %tag_struct.ImageDepth = 1;

for ti = 1:size(inp, 3)

    % tr.nextDirectory()

    if ti == 1
        permission_flag_write = 'w';
    else
        permission_flag_write = 'a';
    end
    tw = Tiff(filename_write, permission_flag_write);
    %     writeDirectory(tw);
    %     currentDirectory(tw)


    % % transfer tags from read file to write file,
    % % some are required for others so use a while loop,
    % % exit loop when all are complete or nothing changes after a loop
    tagnames = tr.getTagNames();
    finishedtags = cell (1, length(tagnames));
    numunfinished = numel(find(cellfun(@isempty, finishedtags)));
    numunfinished_prev = -1;
    tag_struct = struct;
    tag_struct_prev = struct;
    for ji = 1 %ti = 1:3
        tr.nextDirectory()
        while any(cellfun(@isempty, finishedtags)) & numunfinished~=numunfinished_prev
            numunfinished = numel(find(cellfun(@isempty, finishedtags)));
            for tni = 1:length(tagnames)
                try
                    %tag_struct.(tagnames{tni}) = getTag(tr,tagnames{tni});
                    tw.setTag(tagnames{tni}, getTag(tr,tagnames{tni}));
                    %setTag(tw, tagnames{tni}, getTag(tr,tagnames{tni}));
                    finishedtags{tni} = tagnames{tni};
                catch
                    fuk=2;
                    %disp(tagnames{tni})
                end
            end
            numunfinished_prev = numel(find(cellfun(@isempty, finishedtags)));
        end
        if ~isequal(tag_struct, tag_struct_prev) & ti>1
            stibbb=2;
        end
        tag_struct_prev = tag_struct;

    end

    %setTag(tw, tag_struct);
    %tw.setTag(tag_struct);

    %imwrite(inp(:, :, 1), filename_write, 'Compression', 'none');

    %tw.nextDirectory()
    %tw.setDirectory(ti)
    tw.write(inp(:,:,ti));
    %write(tw, inp(:,:,ti));
    %imwrite(inp(:, :, ti), filename_write, 'WriteMode', 'append',  'Compression', 'none');
end


tr.close();
tw.close();
%close(tw);


