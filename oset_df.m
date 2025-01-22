function o = oset_df(o)

o.mn.dodaq = 1; %process daq timeseries?

o.mn.plt = [""]; %by defualt plots are created from all modules that you enter (if you don't enter, with a do_*, they are ignored); uncomment this to plot nothing automatically (empty string); or uncomment and specify specific modules for plotting here; o.mn.plt = ["spr"] will plot only from spr module (stackpr); plot only from spr module (stackpr, ie the automatic gifs)

% o.spr.suffixplt = {'cmrg_dcdn'}; %by default stackpr will plot all available stacks in the automatic gif (calling stackplt from stackpr), but you can change which stacks get plotted here
% o.spr.sp.it = -100; %specify how many frames of automatically plotted stack gif you want plotted (if you want it plotted when you run a2p)default (d.sp.it, in optdfsv.m) is -100, which is 100 equidistant frames; you can change that here


o = odf(o, fill=1); %make sure o is filled
