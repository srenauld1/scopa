function offset = cx_bump_pva_offset(smoothwindow, cue, mu)

mu = cx_smooth_circular_var(mu, smoothwindow);

offset = circ_dist(cue, mu);

offset = single(offset);
