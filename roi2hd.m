
function [resptmp, domain] = roi2hd(stack, regionex, indvp, depvp, pthpre, ...
    roidat, imrate, fitopt, numangrs, smfac, doplt, epochts)


numroi = size(depvp, 1);
numsamp = size(depvp, 2);

doplt=0;

fitin = mdlmake(indvp, depvp, imrate, fitopt, doplt, pthpre, epochts, stack, roidat);

fn = fieldnames(fitin.fits);
if numel(fn)>1
    error("you've requested multiple fits to different epochnum, but roi2hd operates on a single fit; decide which epochnum set you want to use to compute bump")
end
angpref = fitin.fits.(fn{1}).indvpf_mean_allval(:)'; %row vector of preferred angle;


[prefang_sorted,sinds] = sort(angpref);
rawsort = depvp(sinds,:);

%% resample functional domain

if numangrs

    fprintf("resampling compass from " + num2str(numroi) + " rois to " + num2str(numangrs) + " rois, with 2pi domain (whether it's PB or not)" + newline)

    if numroi<numangrs*2
        fprintf("WARNING, \nREQUESTED RESAMPLE WITH MORE OUTPUT SAMPLES THAN INPUT SAMPLES" + newline)
    end
    if strcmp(regionex, 'pb')
        fprintf("REGIONEX IS 'pb', TREATING IT AS ONE CIRCLE AND RESAMPLING, RATHER THAN RESAMPLING EACH HALF AND CONCATENATING THE RESULT (ALTHOUGH THAT OPTION DOES EXIST IN roi2hd" + newline)
    end

    maxangrs = 8;
    [resptmp, domain] = compassrs(depvp, angpref, numangrs, maxangrs, doplt);
    resptmp = rescale(resptmp);

    if strcmp(regionex, 'pb')

        fprint("doing pb two halves resampling for optional plotting, but this is not used in the data" + newline)

        %resample each half of the compass, then put them together
        %HALVES ARE NOT WELL DEFINED, FIX THIS (use >pi shift in angpref??, or more precise morphology, or user-defined pb center??)
        %resampling 4pi all together only works if you shift angpref from one half of pb up by pi, right?

        rois_left = 1:numroi/2;
        rois_right = numroi/2+1:numroi;

        numangrs_left = floor(numangrs/2);
        numangrs_right = numangrs-numangrs_left;

        [dfc_left, domain_left] = compassrs(depvp(rois_left,:), angpref(rois_left), numangrs_left, maxangrs, doplt);
        [dfc_left, domain_left] = compassrs(depvp(rois_right,:), angpref(rois_right), numangrs_right, maxangrs, doplt);

        resptmp_2halves = cat(1, dfc_left, dfc_right);
        resptmp_2halves = rescale(resptmp_2halves);

        domain_2halves = [domain_left domain_right];

    end

else

    domain = angpref;

end

%%




