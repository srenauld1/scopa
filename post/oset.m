function o = oset(recin)

%{

IMPORTANT: 
    DO NOT CHANGE ORDER OF SECTIONS (IF YOU DO, SOME OPTIONS MAY NOT GET SET); SECTION TITLES SHOW EACH MAJOR ROUTINE 
    DO NOT DELETE ANY CALLS TO odf (IF YOU DO, SOME OPTIONS MAY NOT GET SET) 
    IF YOU WANT TO USE ALL DEFAULTS FOR ANY ROUTINE k, JUST DON'T PASS INPUT FOR THE CALL TO odf THAT SETS OPTIONS FOR ROUTINE k; 
        FOR EXAMPLE, o.k = odf() WILL USE ALL DEFAULTS FOR ROUTINE k 
        OR YOU CAN COMMENT OUT THE SPECIFICATION FOR INPUT tmp
        FOR SIMPLICITY, THIS FILE SHOWS ONLY OPTIONS THE USER IS LIKELY TO WANT TO ADJUST
    DOCS ON ALL OPTIONS ARE IN odf

this function (oset) sets options for all major routines in a2p
output is nested (o) and flattened (oflat) struct containing all options used in a2p
use function odf to set default options, like this:
    callingRoutine.updatedRoutine = odf(tmpPlaceholder, dataBin1, dataBin2, ..., dataBinN), where . . . 
        tmpPlaceholder is a struct with one field, updatedRoutine, which specifies how defaults for updatedRoutine will change (defaults are in o.updatedRoutine in function odf)
        callingRoutine.updatedRoutine will have substructs dataBin1, dataBin2, ..., dataBinN, if any dataBin arguments were passed to odf; 
            for example,  after this call 
                    tmp.b = 2
                    a = odf(tmp, 'c', 'd')
                struct k contains user-defined k.c.b and k.d.b, and default values for any other field (see defaults in in o.k in function odf)
        updatedRoutine can be nonscalar struct; if at least one field specification for updatedRoutine includes index p, all unspecified fields for all struct indices up to index p are filled with defaults (e.g see how options are set in 'mfit' section below); alternatively, struct index can be assigned in the output of odf
    note odf will only set options for structs recursively within updatedRoutine; it will not set options for structs placed above input struct by position in output
        for example: o.hires.sld.sp = odf(tmp) will set options for o.hires.sld.sp, but not for o.hires.sld; that must be set separately, and it must be done before o.hires.sld.sp
            section order below sets options for all routines, so if you leave the section order unchanged, and do not delete any calls to odf, no routine's options will be skipped
        for this reason, every routine's options are set below (at least on scopa 'main' branch); this shows how a2p is organized; 
        every call to odf shows output for a major routine that can be called, and the nesting of that output struct shows where in a2p that routine is called (o.k means routine k is called directly from a2p, while o.m.k means k is called from within routine m, which is called directly from a2p)
        it's done this way because because several routines get called multiple times in different locations, so this reduces the number of default options (ie this way you don't have to set unique defaults for routine x when called from different locations

%}

arguments
    recin = [] %recin can be empty, or not passed as argument, and will search for file using fspc* below; recin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, pass recin as 'nofile'
end


%% recin

if isempty(recin) %if you're running a2p without arguments (recin is empty), set recording specifiers (recspec) here to find files
    recin.recdate = {'20240907'}; %cell array of char, can use wildcards
    recin.fly = {'*'}; %cell array of char, can use wildcards
    recin.trial = {'*'}; %cell array of char, can use wildcards
    recin.suffix = {'cmrg_dcdn'}; %cell array of char; can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg); valid suffixes are defined in validsuffix
    recin.match = 'each'; %'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
end

%% mn

tmp.mn.dodaq = 1;
tmp.mn.doftv = 1;
tmp.mn.dopop = 0; 
tmp.mn.dofit = 0;
tmp.mn.dopltx = 1;

o.mn = odf(tmp); tmp = [];

%% daq

tmp.daq.useinds = 'none';

o.daq = odf(tmp); tmp = [];

%% sld

tmp.sld.chanuse = 1;
tmp.sld.suffixplt = 'cmrg_dcdn';

o.sld = odf(tmp); tmp = [];

%% sld.sp

tmp.sp.it = [50.3];

o.sld.sp = odf(tmp); tmp = [];

%% ftv

tmp.ftv.doplt = 1;

o.ftv = odf(tmp); tmp = [];

%% mroi

tmp.mroi.dodraw = 1;
tmp.mroi.auto.chan = 99;
tmp.mroi.imhsv.do = 100;

o.mroi = odf(tmp, 'fb256'); tmp = [];

%% mroi.imhsv

tmp.imhsv.do = 0; %1 to plot/save, 0 to just compute hsv image but skip plot/save  
tmp.imhsv.fg = 'allrois'; %'eachroi' plots each individually, 'allrois' plots all together

o.mroi.imhsv = odf(tmp, 'fb256'); tmp = [];

%% froi

tmp.froi.roistr = {'2_1_*_*_*_*_*_1000_*_*_graph_3dex'};

o.froi = odf(tmp, 'fb256', 'fb512'); tmp = [];

%% bump (set within pf, which currently has no options)

tmp.bump.domain_method = 'functional';

o.pf.bump = odf(tmp); tmp = [];

%% bump.mfit (as above, bump is set within pf, which currently has no options) 

tmp.mfit.varnms.depvp{1} = {['resp.fb256.mo*.*rsc000100_*chn1']}; 
tmp.mfit.varnms.indvp{1} = {['vis.yaw']};

o.pf.bump.mfit = odf(tmp); tmp = [];

%% mfit

tmp.mfit(1).varnms.depvp{1} = {['resp.fb256.mo*.*_chn1']}; 
tmp.mfit(1).varnms.indvp{1} = {['ball.forvel']};
tmp.mfit(1).validation_fold = 0; 
tmp.mfit(1).mdlname = 'fnet_A01_s'; 
tmp.mfit(1).plt.doplt = 0;

tmp.mfit(2).varnms.depvp{1} = {['resp.fb256.mo*.*_chn1']}; 
tmp.mfit(2).varnms.indvp{1} = {['ball.forvel']};
tmp.mfit(2).validation_fold = 0; 
tmp.mfit(2).mdlname = 'fnet_A01_s'; 
tmp.mfit(2).plt.doplt = 0;

o.mfit = odf(tmp); tmp = [];

%% pltx

tmp.pltx.varnms.ts1{1} = {['ball.forvel']};
tmp.pltx.varnms.ts5{1} = {['resp.fb256.mo*.*chn1.ind1']}; 
tmp.pltx.lagsxy_sec = linspace(-1, 1, 1e4);
tmp.pltx.lagsz_sec = linspace(-1, 1, 1e4); 
o.pltx = odf(tmp); tmp = [];

%% hires

tmp.hires.do_reg_plots = 0;
tmp.hires.disttype = 'monomodal';
tmp.hires.regtype = 'rigid';
o.hires = odf(tmp); tmp = [];

%% hires.sld

tmp.sld.dostats = 0;
o.hires.sld = odf(tmp); tmp = [];

%% hires.sld.sp

tmp.sp.it = [1];
o.hires.sld.sp = odf(tmp); tmp = [];

%% carl

oldcarlo %this is ignored if you're not carl

%% find files 

if isstruct(recin) %if recin was empty or was struct
    tmp.recspec = recin;
    o.recspec = odf(tmp); %call defaults for any missing recspec field; if no fields missing, nothing will change
    o.rec = filefind(pthparent_local=o.recspec.pthparent_local, pthparent_o2=o.recspec.pthparent_o2, validsuffix=o.recspec.validsuffix, recdate=recspec.recdate, fly=recspec.fly, trial=recspec.trial, suffix=recspec.suffix, match=recspec.match); %find files matching recspec
else
    if strcmp(recin, 'nofile')
        o.rec = [];
        sprintf("SETTING OPTIONS WITHOUT SEARCHING FOR FILES")
    else
        o.rec = fileignore(recin);
        if isempty(o.rec)
            sprintf("NONE OF THE FULL PATH INPUT TO a2p EXIST")
        end
    end
end

%% organize

o = fieldord(o);

[oflat, oflatfn, oflatflex] = structflat(o);

if ~strcmp(recin, 'nofile') && isempty(cell2mat(o.rec))
    error("NO STACKS FOUND")
end

end








