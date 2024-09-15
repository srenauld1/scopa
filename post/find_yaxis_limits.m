
function lims = find_yaxis_limits(varsin, yaxisroomfac)

%outputs independent channel lims

varrng = range(varsin, 2);
lims.each = [min(varsin, [], 2, 'omitmissing'), max(varsin, [], 2, 'omitmissing')];
lims.each_xtra = [lims.each(:,1,:) - varrng*yaxisroomfac, lims.each(:,2,:) + varrng*yaxisroomfac];
lims.all = [min(lims.each, [], [1 2], 'omitmissing'), max(lims.each, [], [1 2], 'omitmissing')]; %min over first two dims, in case 3rd dim >1 (channels>1)
lims.all_xtra = [min(lims.each_xtra, [], [1 2], 'omitmissing'), max(lims.each_xtra, [], [1 2], 'omitmissing')];
lims.rescale = [0 1];
lims.rescale_xtra = [0 - yaxisroomfac, 1 + yaxisroomfac];

end