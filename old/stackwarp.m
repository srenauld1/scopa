function stackwarp(stack, trans, rot, opt)

arguments
    stack
    trans = [0,0,0]
    rot = [0,0,0]
    opt.doplt = 0
end
doplt = opt.doplt;

if ndims(stack)<2 || ndims(stack>6)
    error("stack numst be 2d-6d")
end

tform = rigidtform3d(rot,trans);

Rin = imref3d(size(stacktmp));
Rin.XWorldLimits = Rin.XWorldLimits-mean(Rin.XWorldLimits);
Rin.YWorldLimits = Rin.YWorldLimits-mean(Rin.YWorldLimits);
Rin.ZWorldLimits = Rin.ZWorldLimits-mean(Rin.ZWorldLimits);

vout = affineOutputView(size(stacktmp),tform,BoundsStyle='CenterOutput'); % CenterOutput, SameAsInput

for q = 1:size(stack,6)
    for m = 1:size(stack,5)
        for k = 1:size(stack,4)
            stack(:,:,:,k,m) = imwarp(stack(:,:,k,m,q), Rin, tform, OutputView=vout);
        end
    end
end

if doplt
    stackplt(stack, it=30.3)
end