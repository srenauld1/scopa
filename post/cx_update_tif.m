function cx_update_tif(inp, pth_read, pth_write)

%this is the only way i was able to update image data in a tif file without
%modifying the tags that are required for caiman to read the updated file 
%WARNING, matlab LibTiff cannot read stacks with more than 65536 (2^16)
%frames (z slices times frames)
%cx_read_tif_tzyx has been updated with a custom reading function that can
%handle larger tifs, but it does not write
%the LibTiff functions below probably will fail if z*t>65536
%but it may not error, instead all frames after 65536 will be copies of frame 65536

if size(inp, 3)*size(inp, 4)>65536
    error("cx_update_tif will likely fail for more than 65536 frames, see comments above")
end

copyfile(pth_read, pth_write)

inp = reshape(inp, size(inp, 1), size(inp, 2), []);
tw = Tiff(pth_write, 'r+');

for ti = 1:size(inp, 3)

    tw.write(inp(:,:,ti));
    if ti<size(inp, 3)
        tw.nextDirectory()
    end

end

tw.close();


