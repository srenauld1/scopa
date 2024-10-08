function o = oset(recin)

%{

these docs are slightly outdated 
FOR SIMPLICITY, THIS FILE SHOWS ONLY OPTIONS THE USER IS LIKELY TO WANT TO ADJUST
DOCS ON ALL OPTIONS ARE IN odf

this function (oset) sets options for all major routines in a2p
output is nested (o) and flattened (oflat) struct containing all options used in a2p
use function odf to set default options, like this:
    callingRoutine.updatedRoutine = odf(tmpPlaceholder, dataBin1, dataBin2, ..., dataBinN), where . . . 
        tmpPlaceholder is a struct with one field, updatedRoutine, which specifies how defaults for updatedRoutine will change (defaults are in o.updatedRoutine in function odf)
        callingRoutine.updatedRoutine will have substructs dataBin1, dataBin2, ..., dataBinN, if any dataBin arguments were passed to odf; 
            for example,  after this call 
                    o.b = 2
                    a = odf(o, 'c', 'd')
                struct k contains user-defined k.c.b and k.d.b, and default values for any other field (see defaults in in o.k in function odf)
        updatedRoutine can be nonscalar struct; if at least one field specification for updatedRoutine includes index p, all unspecified fields for all struct indices up to index p are filled with defaults (e.g see how options are set in 'mfit' section below); alternatively, struct index can be assigned in the output of odf
    note odf will only set options for structs recursively within updatedRoutine; it will not set options for structs placed above input struct by position in output
        for example: o.hires.sld.sp = odf(o) will set options for o.hires.sld.sp, but not for o.hires.sld; that must be set separately, and it must be done before o.hires.sld.sp
            section order below sets options for all routines, so if you leave the section order unchanged, and do not delete any calls to odf, no routine's options will be skipped
        for this reason, every routine's options are set below (at least on scopa 'main' branch); this shows how a2p is organized; 
        every call to odf shows output for a major routine that can be called, and the nesting of that output struct shows where in a2p that routine is called (o.k means routine k is called directly from a2p, while o.m.k means k is called from within routine m, which is called directly from a2p)
        it's done this way because because several routines get called multiple times in different locations, so this reduces the number of default options (ie this way you don't have to set unique defaults for routine x when called from different locations

YOU CAN NEST FIELDS THAT ARE FIELDS OF d IN odf, or subfields of fields of d; 

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

o.mn.dodaq = 1;
o.mn.doftv = 1;
o.mn.dopop = 0; 
o.mn.dofit = 0;
o.mn.dopltx = 1;

o.daq.useinds = 'none';

o.sld.chanuse = 1;
o.sld.suffixplt = 'cmrg_dcdn';

o.sp.it = [50.3];

o.ftv.doplt = 1;


o.pop.bump.domain_method = 'functional';
o.pop.bump.mfit.varnms.depvp{1} = {['resp.fb256.mo*.*rsc000100_*chn1']}; 
o.pop.bump.mfit.varnms.indvp{1} = {['vis.yaw']};


o.mfit(1).varnms.depvp{1} = {['resp.fb256.mo*.*_chn1']}; 
o.mfit(1).varnms.indvp{1} = {['ball.forvel']};
o.mfit(1).validation_fold = 0; 
o.mfit(1).mdlname = 'fnet_A01_s'; 
o.mfit(1).plt.doplt = 0;

o.mfit(2).varnms.depvp{1} = {['resp.fb256.mo*.*_chn1']}; 
o.mfit(2).varnms.indvp{1} = {['ball.forvel']};
o.mfit(2).validation_fold = 0; 
o.mfit(2).mdlname = 'fnet_A01_s'; 
o.mfit(2).plt.doplt = 0;

o.pltx.varnms.ts1{1} = {['ball.forvel']};
o.pltx.varnms.ts5{1} = {['resp.fb256.mo*.*chn1.ind1']}; 
o.pltx.lagsxy_sec = linspace(-1, 1, 1e4);
o.pltx.lagsz_sec = linspace(-1, 1, 1e4); 


o.hires.do_reg_plots = 0;
o.hires.disttype = 'monomodal';
o.hires.regtype = 'rigid';
o.hires.sld.dostats = 0;
o.hires.sld.sp.it = [1];

o.mroi.dodraw = 1;
o.mroi.auto.chan = 99;
o.mroi.imhsv.do = 100;
o.mroi.imhsv.fg = 'allrois'; 
o.froi.roistr = {'2_1_*_*_*_*_*_1000_*_*_graph_3dex'};
o = odf(o, {'froi', 'mroi'}, {'fb', 'ga'});


o.mroi.imhsv.fg = 'pixels'; 
o = odf(o, {'mroi'}, {'pb', 'eb'}); 




%% find files 

if isstruct(recin) %if recin was empty or was struct
    o.recspec = recin;
    o.recspec = odf(o); %call defaults for any missing recspec field; if no fields missing, nothing will change
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

oldcarlo %ignored if you're not carl

o = fieldord(o);

[oflat, oflatfn, oflatflex] = structflat(o);

if ~strcmp(recin, 'nofile') && isempty(cell2mat(o.rec))
    error("NO STACKS FOUND")
end

end








