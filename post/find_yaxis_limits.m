
function lims = find_yaxis_limits(varsin, yaxisroomfac)

varrng = range(varsin, 2);
lims.each = [min(varsin, [], 2, 'omitmissing'), max(varsin, [], 2, 'omitmissing')];
lims.each_xtra = [lims.each(:,1) - varrng*yaxisroomfac, lims.each(:,2) + varrng*yaxisroomfac];
lims.all = [min(lims.each, [], 'all', 'omitmissing'), max(lims.each, [], 'all', 'omitmissing')];
lims.all_xtra = [min(lims.each_xtra, [], 'all', 'omitmissing'), max(lims.each_xtra, [], 'all', 'omitmissing')];
lims.rescale = [0 1];
lims.rescale_xtra = [0 - yaxisroomfac, 1 + yaxisroomfac];

end