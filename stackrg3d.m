function [registered, tform] = stackrg3d(moving, fixed, disttype, regtype)

% this registration works, but input params below may need adjusting across recordings

[optimizer,metric] = imregconfig(disttype);
switch disttype
    case 'monomodal' %if images have same intensity and scale
        %will use optimizer RegularStepGradientDescent with metric MeanSquares
        optimizer.GradientMagnitudeTolerance = 1.000000e-05;% 1.000000e-04;
        optimizer.MinimumStepLength = 1.000000e-5;% 1.000000e-05;
        optimizer.MaximumStepLength = 2.250000e-02; %6.250000e-02;
        optimizer.MaximumIterations = 5500; %100
        optimizer.RelaxationFactor = 9.000000e-01;  %5.000000e-01; %larger can be better
    case 'multimodal' %if images have different intensity and scale
        % will use optimizer OnePlusOneEvolutionary with metric MattesMutualInformation,
        metric.NumberOfSpatialSamples = 500; %only relevant if useallpixels=0
        metric.NumberOfHistogramBins = 50; %50
        metric.UseAllPixels = 1; %1
        optimizer.InitialRadius = 1.5e-2; %.009 %making this bigger helped
        optimizer.Epsilon = 1.5e-6; %1.5e-4 %making this smaller helped
        optimizer.GrowthFactor = 1.4; %1.01 %making this bigger helped
        optimizer.MaximumIterations = 2000; %300 bigger helped
end

if 0 % any(size(fixed)<16) %can't remember why this is set to 16
    tform = imregtform(moving, fixed, regtype, optimizer, metric, PyramidLevels=2);
else
    tform = imregtform(moving, fixed, regtype, optimizer, metric);
end

if ndims(fixed)==2
    fixref = imref2d(size(fixed));
elseif ndims(fixed)==3
    fixref = imref3d(size(fixed));
end

registered = imwarp(moving,tform,"OutputView",fixref);


end

