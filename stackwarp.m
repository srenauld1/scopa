function [stack, tform, sr] = stackwarp(stack, opt)

arguments
    stack
    opt.rot = [] %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]
    opt.trans = [] %translation in pixels
    opt.method = []
    opt.bb = []
end
rot = opt.rot;
trans = opt.trans;
method = opt.method;
bb = opt.bb;

if isempty(rot)
    rot = [0,0,0];
end
if isempty(trans)
    trans = [0,0,0];
end
if isempty(method)
    method = 'linear';
end

if ndims(stack)<3 || ndims(stack)>6
    error("stack must be greater than 3d and less than 6d (2d coming soon)")
end
if isempty(bb)
    bb = 'FollowOutput';
end
if ~ismember(bb, {'CenterOutput', 'FollowOutput', 'SameAsInput'})
    error("if rotation is single axis, and no translation, bb must be 'CenterOutput', 'FollowOutput', 'SameAsInput'")
end

sz = size(stack);

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

    if doflip

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
        tform = rigidtform3d(rot, trans);
        ov = affineOutputView(sz(1:3), tform, BoundsStyle=bb);

        for k = 1:szn
            if strcmpi(bb, 'sameasinput')
                [stack(:,:,:,k), sr] = imwarp(stack(:,:,:,k), rf, tform, method, OutputView=ov); %default output view is followoutput
            else
                [tmp, sr] = imwarp(stack(:,:,:,k), rf, tform, method, OutputView=ov); %default output view is followoutput
                if k==1
                    sz = [size(tmp) sz(4:end)];
                    stack2 = zeros([size(tmp) szn], class(stack));
                end
                stack2(:,:,:,k) = tmp;
                if k==szn
                    stack = stack2;
                end
            end
        end

    end

    stack = reshape(stack, sz);

end