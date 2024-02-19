function pos_cntr = cx_compute_z_centers(pixdist_z, szz)

zeropos = 0;
cntr_firstpix = zeropos + pixdist_z/2;
for zi = 1:szz
    pos_cntr(zi) = cntr_firstpix+pixdist_z*(zi-1);
end

