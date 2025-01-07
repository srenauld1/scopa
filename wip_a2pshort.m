    f = structunpack(f);
    stack = stackld(pth.stack, f{:});


        % lfit(ts.ball.forvel, ts.roi.i4{1}, t=ts.t, doplt=1, usesaved=1, roipx=roidat.i4{1}.roipx, stack=stack, sortstyle='xyz', flypos=ts.flypos, ipltts=round(linspace(1, numel(roidat.i4{1}.roipx), 100)))
