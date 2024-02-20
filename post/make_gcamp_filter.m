function gcamp_filter = make_gcamp_filter(gcamp_on, gcamp_off, gcamp_numframes )

x = 0:gcamp_numframes-1;
y1 = exp(-1 / gcamp_on * x);
y2 = exp(-1 / gcamp_off * x);
gcamp_filter = y2-y1; %2 minus 1 then norm-1 normalization same as 1 minus 2 then sum normalization
gcamp_filter = gcamp_filter / norm(vec(gcamp_filter(:)),1); %normalize by L1
%gcamp_filter = fliplr(gcamp_filter);

