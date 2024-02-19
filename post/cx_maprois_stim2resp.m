function cx_maprois_stim2resp(md, cue, resp)

for dii = 1:size(resp{ci+1}.in_rawf_pc_null_cl_null_w_null, 1)
    resp{ci+1}.in_rawf_pc_null_cl_fbox_w_null = rescale(resp{ci+1}.in_rawf_pc_null_cl_null_w_null(dii,:));
end

dur_filt_sec = 2;
lnth = round(length(md.ti)/max(md.ti)*dur_filt_sec);
lnth = 5;
pvar = 0.8;
[lfittmp, ~] = cx_linfit(md, cue, resp{ci+1}.in_rawf_pc_null_cl_fbox_w_null, lnth, pvar, doplots);
lfittmp = mean(lfittmp, 2);
figure; plot(lfittmp)


end