function pos_cntr = slicemid(zdist, szz)

zeropos = 0;
startmid = zeropos + zdist/2;
for zi = 1:szz
    pos_cntr(zi) = startmid+zdist*(zi-1);
end

