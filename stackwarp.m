function [stack, sr] = stackwarp(stack, opt)

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

sz = size(stack, 1:6);
szn = prod(sz(4:end));

stack = reshape(stack, sz(1), sz(2), sz(3), []);

if isempty(bb)
    bb = 'FollowOutput';
end
if ~ismember(bb, {'CenterOutput', 'FollowOutput', 'SameAsInput'})
    error("if rotation is single axis, and no translation, bb must be 'CenterOutput', 'FollowOutput', 'SameAsInput'")
end

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

stack = reshape(stack, sz);


end