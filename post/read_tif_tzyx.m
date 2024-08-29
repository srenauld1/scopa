function out = read_tif_tzyx(filename_tif, opt)

% scanimage, and scopa 'pre' pipeline (everything output by pipeline_init.py) write stacks as 3d tifs,
% with dim order tzcyx, where t and z and c dimensions are collapsed into one
% matlab file exchange function TIFFStack reads these tifs as 3d with dim order yxczt (even if they were written as >3d, at least with imwrite from tifffile.tifffile)

% tsStack cannot be reshaped until it has been assigned to a variable
% out=tsStack does not read stack into memory, you must use indexing
% this function creates indexes (even for the entire stack by default)

%TIFFStack seems to fail reading floats

%option to just read a subset of z and t indices to save memory/time (inds_z_read_from, inds_t_read_from)
%fullsize_z_read_from and fullsize_t_read_from must match z and t dimensions of tif
%tifs from scopa can be 3d or 4d and can be read here without issue

%cannot reshape tsStack from its 3d form and then subset with inds*
%must subset tsStack first, which reads it into memory, then you can subset
%so if you know size, you can subset when reading into memory to save memory
%if you don't, you read the whole tsStack then can subset using inds*,
% as long as they are not out of bounds

arguments
    filename_tif char
    opt.size_read_from = []
    opt.inds_y_read_from = []
    opt.inds_x_read_from = []
    opt.inds_c_read_from = []
    opt.inds_z_read_from = []
    opt.inds_t_read_from = []
end

size_read_from = opt.size_read_from;
inds_y_read_from = opt.inds_y_read_from;
inds_x_read_from = opt.inds_x_read_from;
inds_c_read_from = opt.inds_c_read_from;
inds_z_read_from = opt.inds_z_read_from;
inds_t_read_from = opt.inds_t_read_from;

if isempty(size_read_from) %put these warnings before call to TIFFStack because it can be slow, good to know in advance (if you know size_read_from)
    stack_size_is_known = 0;
else
    stack_size_is_known = 1;
end

if stack_size_is_known %put these warnings before call to TIFFStack because it can be slow, good to know in advance (if you know size_read_from)
    
    if ~all(inds_y_read_from >= 1 & inds_y_read_from <= size_read_from(1))
        error("REQUESTED inds_x_reaa2d_from are not subset of available stack")
    end
    if ~all(inds_x_read_from >= 1 & inds_x_read_from <= size_read_from(2))
        error("REQUESTED inds_x_read_from are not subset of available stack")
    end
    if ~all(inds_c_read_from >= 1 & inds_c_read_from <= size_read_from(3))
        error("REQUESTED inds_c_read_from are not subset of available stack")
    end
    if ~all(inds_z_read_from >= 1 & inds_z_read_from <= size_read_from(4))
        error("REQUESTED inds_x_read_from are not subset of available stack")
    end
    if ~all(inds_t_read_from >= 1 & inds_t_read_from <= size_read_from(5))
        error("REQUESTED inds_x_read_from are not subset of available stack")
    end
        
    fullsize_c_read_from = size_read_from(3);
    fullsize_z_read_from = size_read_from(4);
    fullsize_t_read_from = size_read_from(5);
    if isempty(inds_c_read_from)
        inds_c_read_from = 1:fullsize_c_read_from; %this default can only be assigned if stack_size_is_known==1
    end
    if isempty(inds_z_read_from)
        inds_z_read_from = 1:fullsize_z_read_from; %this default can only be assigned if stack_size_is_known==1
    end
    if isempty(inds_t_read_from)
        inds_t_read_from = 1:fullsize_t_read_from; %this default can only be assigned if stack_size_is_known==1
    end

else
    if ~isempty(inds_c_read_from) || ~isempty(inds_z_read_from) || ~isempty(inds_t_read_from)
        error("you must know stack size to pass nonempty inds_z_read_from or inds_t_read_from or inds_c_read_from")
    end
end



tsStack = TIFFStack(filename_tif); % Construct a TIFF stack associated with a file, this doesn't read the stack into memory


if isempty(inds_y_read_from)
    inds_y_read_from = 1:size(tsStack,1); %this default can be assigned even if stack_size_is_known==0
end
if isempty(inds_x_read_from)
    inds_x_read_from = 1:size(tsStack,2); %this default can be assigned even if stack_size_is_known==0
end

if stack_size_is_known

    inds_t_read_from_all = repelem(inds_t_read_from,numel(inds_c_read_from)*numel(inds_z_read_from));
    inds_z_read_from_all = repmat(repelem(inds_z_read_from,numel(inds_c_read_from)), [1 numel(inds_t_read_from)]);
    inds_c_read_from_all = repmat(inds_c_read_from, [1 numel(inds_z_read_from)*numel(inds_t_read_from)]);
    inds_czt_read_from = sub2ind([fullsize_c_read_from, fullsize_z_read_from, fullsize_t_read_from], inds_c_read_from_all, inds_z_read_from_all, inds_t_read_from_all); %define 1d inds_zt_read_from for z and t

    out = tsStack(inds_y_read_from, inds_x_read_from, inds_czt_read_from); %this reads into memory; out = tsStack just copies the tsStack object so cant do that
    out = reshape(out, numel(inds_y_read_from), numel(inds_x_read_from), numel(inds_c_read_from), numel(inds_z_read_from), numel(inds_t_read_from) );

else

    out = tsStack(inds_y_read_from, inds_x_read_from, :); %this reads into memory; if you don't know stack size, you can't subset z or t in tsStack;  out = tsStack just copies the tsStack object so cant do that

    sprintf("WARNING, fullsize_z_read_from AND fullsize_t_read_from were not passed as arguments, or are empty; output tif is 3d, and may have collapsed z and t dimensions")

end


