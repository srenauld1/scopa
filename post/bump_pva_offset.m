function offset = bump_pva_offset(smoothwindow, cue, mu)

mu = smooth_circular_var(mu, smoothwindow);

offset = circ_dist(cue, mu);

offset = single(offset);
