function o = oset_wenyi(o)

o.mn.plt = ["spr"]; %which modules get plots; by defualt plots are skipped in all modules (modules with do* switches will not get plotted if the do switch is false, even if you list them here in o.mn.plt; comment this out to plot nothing (or input empty string [""]); specify specific modules for plotting here; o.mn.plt = ["spr"] will plot only from spr module (stackpr); 
% o.spr.suffixplt = {'cmrg_dcdn'}; %by default stackpr will plot all available stacks in the automatic gif (calling stackplt from stackpr), but you can change which stacks get plotted here
% o.spr.sp.it = -100; %specify how many frames of automatically plotted stack gif you want plotted (if you want it plotted when you run a2p)default (d.sp.it, in odfsv.m) is -100, which is 100 equidistant frames; you can change that here
