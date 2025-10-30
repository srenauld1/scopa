function [stack, tform, sr] = stackwarp(stack, opt)

% rotate and/or translate stack; operates individually on each frame (t) and pmt channel (c) and rgb channel (k) if they exist
% if you pass in multiple rotations or translations, will automatically average tck dimensions and warp the spatial (yxz) dimensions,
% then plot results and prompt user to choose rotation to apply to full stack (which is output)
% for convenience, rotations and/or translations can be passed in, optionally, along each axis individually, and any axis warp not specified is set to 0

arguments
    stack
    opt.rot = [] %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]; size(rot,1)>1 for multiple rotations (for plotting, will only output last rotated stack))
    opt.trans = [] %translation in pixels; size(rot,1)>1 for multiple translations (just for plotting, will only output last rotated stack)
    opt.method = []
    opt.bb = []
    opt.rotx = []
    opt.roty = []
    opt.rotz = []
    opt.transx = []
    opt.transy = []
    opt.transz = []
    opt.doplt (1,1) {mustBeBinary} = 0
end
rot = opt.rot;
rotx = opt.rotx;
roty = opt.roty;
rotz = opt.rotz;
trans = opt.trans;
transx = opt.transx;
transy = opt.transy;
transz = opt.transz;
method = opt.method;
bb = opt.bb;
doplt = opt.doplt;

rot = format_warp(rot, rotx, roty, rotz);
trans = format_warp(trans, transx, transy, transz);

if isempty(method)
    method = 'linear';
end

if ndims(stack)<3 || ndims(stack)>4
    error("stack must be 3d-6d (2d,5d,6d coming soon)")
end
if isempty(bb)
    bb = 'FollowOutput';
end
if ~ismember(bb, {'CenterOutput', 'FollowOutput', 'SameAsInput'})
    error("if rotation is single axis, and no translation, bb must be 'CenterOutput', 'FollowOutput', 'SameAsInput'")
end

if ndims(stack)>3 && (size(rot,1)>1 || size(trans,1)>1)
    stackmn = mean(stack, 4:6);
    stackwarp(stackmn, rot=rot, doplt=1);
    prompt = sprintf("ENTER DEGREES TO ROTATE STACK, FORMAT [x,y,z] (POSITIVE IS CLOCKWISE LOOKING TOWARD ORIGIN ALONG EACH AXIS), OR EMPTY TO SKIP: ");
    commandwindow();
    rot = input(prompt);
    if isempty(rot)
        rot = [0,0,0];
    end
    if ~isvector(rot) || numel(rot)~=3
        error("rot input to command line must be length 3 vector, or empty")
    end
    prompt = sprintf("ENTER PIXELS TO TRANSLATE STACK, FORMAT [x,y,z] (POSITIVE IS AWAY FROM ORIGIN ALONG EACH AXIS), OR EMPTY TO SKIP: ");
    commandwindow();
    trans = input(prompt);
    if isempty(trans)
        trans = [0,0,0];
    end
    if ~isvector(trans) || numel(trans)~=3
        error("trans input to command line must be length 3 vector, or empty")
    end
end

sz = size(stack, 1:6); %make sure sz is length 6

if isequal(rot, [0,0,0]) && isequal(trans, [0,0,0])  %if it's a rotation of 180 degrees about a single axis (in future will deal with multiple 180, which can also use flip)
    dowarp = 0;
else
    dowarp = 1;
end

if isequal(sort(rot), [0,0,180]) && isequal(trans, [0,0,0])  %if it's a rotation of 180 degrees about a single axis (in future will deal with multiple 180, which can also use flip)
    doflip = 1;
else
    doflip = 0;
end

if dowarp

    if doflip %flip x and/or y (not z)

        sznew = sz;
        szn = prod(sz(3:end));

        stack = reshape(stack, sz(1), sz(2), []);
        for k = 1:szn
            tmp = stack(:,:,k);
            if isequal(rot, [180,0,0]) || isequal(rot, [0,0,180]) %180 x or z rotation, flip first dim (for z, also flip 2nd below)
                tmp = flip(tmp,1);
            end
            if isequal(rot, [0,180,0]) || isequal(rot, [0,0,180]) %180 x or z rotation, flip second dim (for z, also flip 1st above)
                tmp = flip(tmp,2);
            end
            stack(:,:,k) = tmp;
        end

    else

        szn = prod(sz(4:end));

        stack = reshape(stack, sz(1), sz(2), sz(3), []);


        rf = imref3d(sz(1:3));


        numwarp = size(rot,1)*size(trans,1);
        if doplt && numwarp>1
            stackp = cell(1, numwarp);
        end
        cnt = 0;
        for qr = 1:size(rot,1)
            for qt = 1:size(trans,1)
                cnt = cnt+1;

                tform = rigidtform3d(rot(qr,:), trans(qt,:));
                ov = affineOutputView(sz(1:3), tform, BoundsStyle=bb);

                for k = 1:szn
                    if strcmpi(bb, 'sameasinput') && qr==size(rot,1) && qt==size(trans,1)
                        [stack(:,:,:,k), sr] = imwarp(stack(:,:,:,k), rf, tform, method, OutputView=ov); %default output view is followoutput
                    else
                        [tmp, sr] = imwarp(stack(:,:,:,k), rf, tform, method, OutputView=ov); %default output view is followoutput
                        if k==1
                            sznew = [size(tmp) sz(4:end)];
                            if (qr==1 && qt==1) || ~isequal(sznew, size(stack2))
                                stack2 = zeros(sznew, class(stack));
                            else
                                stack2(:) = 0;
                            end
                        end
                        stack2(:,:,:,k) = tmp;
                        if k==szn && qr==size(rot,1) && qt==size(trans,1) %at the end of all loops, set output (don't output all rot and trans)
                            stack = stack2; %we use intermediate stack2 so we can input and output stack, in case bb is samasinput
                        end
                    end
                end

                if doplt
                    if numwarp==1
                        stackrotmn = mean(stack, 4:6);
                        stackplt(stackrotmn, dmplt='yx(z)');
                        stackplt(stackrotmn, dmplt='yxz');
                    else
                        stackp{cnt} = stack2;
                        if qr==size(rot,1) && qt==size(trans,1)
                            szmax = max(cell2mat(cellfun(@size, stackp, 'UniformOutput', false)'));
                            tmpyx = zeros([szmax(1:2), numel(stackp)]);
                            tmpyxz = zeros([szmax, numel(stackp)]);
                            for k = 1:numel(stackp)
                                tmpyx(1:size(stackp{k},1), 1:size(stackp{k},2), k) = mean(stackp{k}, 3);
                                tmpyxz(1:size(stackp{k},1), 1:size(stackp{k},2), 1:size(stackp{k},3), k) = stackp{k};
                            end
                            stackplt(tmpyx, dmplt='yx(z)');
                            stackplt(tmpyx, dmplt='yxz');
                        end
                    end
                end

            end
        end
    end

    stack = reshape(stack, sznew);


end


end

function w = format_warp(w, wx, wy, wz)

nm = inputname(1);
numaxrot = max([numel(wx), numel(wy), numel(wz)]);
if numaxrot>0
    if ~isempty(w)
        error("cannot pass in name-value arguments " + nm + "x, "  + nm + "y, " + nm + "z, along with " + nm)
    end
    if isempty(wx)
        wx = zeros(numaxrot,1);
    end
    if isempty(wy)
        wy = zeros(numaxrot,1);
    end
    if isempty(wz)
        wz = zeros(numaxrot,1);
    end
    if ~isequal(numel(wx), numel(wy), numel(wz))
        error(nm + "x "  + nm + "y and " + nm + "z must all be equal length (if not empty)")
    end
    w = [wx(:) wy(:) wz(:)];
end
if isempty(w)
    w = [0,0,0];
end

end