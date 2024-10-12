function [o, oflatfn] = oset(recin)


%{

----- o, oset, and odf ----- 

oset uses function odf to set options for all major functions in a2p
odf defines defaults options for all major functions in a2p
oset is just a wrapper for calling odf in various ways, so the user can set options however they'd like

oset below shows one approach for using odf to set options, but the same options struct cold be created in different ways

first output o is a nested struct containing all options used in major functions in a2p
defaults for all available options are in struct d in function odf
all option defaults are also set within each major function (so the user could skip passing optional arguments with the options struct created here)

oset is a wrapper for odf; it is intended to be the only place the user might want to adjust options to a2p; 
if they don't want to adjust options, they could, in theory, just replace a call to oset with a call to odf (with no arguments, since zero argument syntax returns all defaults and all stack files in the filesystem)

second output oflat is a flattened version of o, and is just for inspection, for the user's convenience; a2p uses o, not oflat  

reason for using o, oset, and odf:
    modularity
    minimize number of defaults
    all options in one place (o output from oset, with defaults d defined in odf)
    can access all default options anywhere in a2p by calling odf without input arguments, or can access user defined o by calling oset from anywhere in a2p (which will just recreate the entire o)

for simplicity, this file shows only options the user is likely to want to change

----- options struct o, organization -----

o is the option struct for a2p
o is a struct containing vbins
each vbin is a container for options that can be passed as arguments to a major function in a2p
the fields of the vbin are the options
some minor functions also have optional arguments, but they are not listed in odf (or oset) because they are less likely to need adjusting 
options set here (ie options with defaults defined in odf) are only used in the functions denoted by their enclosing vbin; 
vbin names are similar to, or abbreviated forms of, their associated functions
here is a complete list of vbins and functions they hold options for (see also section headers in odf)

    mn, a2p
    spec, filefind   (called from odf)
    daq, daqld   (called from a2p)
    sld, stackld   (called from a2p)
    ftv, ftvproc   (called from a2p)
    mroi, mroimake   (called from a2p)
    seg, mroiauto   (called from mroimake)
    froi, froiproc   (called from a2p)
    nrm, respnorm   (called from mroimake and froiproc)
    pop, popcmp   (called from a2p)
    bump, bumpcmp   (called from popcmp)
    mfit, mfit   (called from a2p)
    tg, tsget   (called from, bumpcmp, mfit, and pltx)
    pltx, pltx   (called from a2p)
    hires, hiresld   (called from a2p)
    tp, tsplt   (called from various functions for visualization) 
    sp, stackplt   (called from various functions for visualization) 
    imhsv, imhsvplt   (called from various functions for visualization)


vbin fields are all optional arguments to their associated functions (the user could skip passing the substruct variables, which would just use default values)
each vbin has default values listed in struct d of odf

vbin fields in odf can themselves be structs (optbin) holding options
for example, 
    o.vbin1.optbin1.option1 = 2 and o.vbin1.optbin1.option2 = 3
    this means vbin1 has a struct optbin1 which is a struct that holds option1 and option2
    optbins will be listed in defaults in odf, although there are currently no optbins, for simplicity


----- vbin nesting -----

vbin fields can also be vbins
vbins can be nested within vbins arbitrarily, although the nesting must reflect the organization of a2p (nesting of major functions)
if you reorganize a2p, you might need to reorganize how vbins are nested in o
there is no vbin nesting in default struct d (in odf), since each vbin refers to a function that is meant to be modular (can in theory be called by itself; this also reduces the number of defaults required in odf)  

o.vbin1 means the function vbin1 refers to is called directly from a2p, 
o.vbin1.vbin2 means the function vbin2 refers to is called from the function vbin1 refers to, and the function vbin1 refers to is called directly from a2p
it's done this way because because several functions get called multiple times in different locations, so this reduces the number of default options (ie this way you don't have to set different defaults for the samer function called from different locations

here are the current valid vbin nestings within o (reflecting organization of major functions)
these nested vbins will be set in o, by user or by default
for brevity, only the deepest nesting of each unique branch is shown

    o.sld.sp   (stackplt called from within stackld called from a2p)
    o.pop.bump   (bumpcmp called from within popcmp called from a2p)
    o.mfit.tg   (tsget called from within mfit called from a2p)
    o.mfit.sp   (stackplt called from within mfit called from a2p)
    o.mfit.tp   (tsplt called from within mfit called from a2p)
    o.pltx.tg   (tsget called from within pltx called from a2p)
    o.hires.sld.sp   (tsget called from within pltx called from a2p)
    o.mroi.seg   (mroiauto called from within mroi called from a2p)
    o.mroi.nrm   (respnorm called from within mroimake called from a2p)
    o.mroi.sp   (stackplt called from within mroimake called from a2p)
    o.mroi.imhsv   (hsvplt called from within mroi called from a2p)
    o.froi.nrm   (respnorm called from within froiproc called from a2p)
    o.froi.sp   (stackplt called from within froiproc called from a2p)
    o.froi.imhsv   (hsvplt called from within froiproc called from a2p)

----- nonscalar vbin -----

a vbin can be nonscalar struct; 
if at least one field specification for vbin includes index p, all unspecified fields for all struct indices up to index p are filled with defaults 
(e.g see how options are set in 'mfit' section below); 
alternatively, struct index can be assigned in the output of odf

----- copybin -----

a vbin can contain a copybin, which is a struct that holds options for an experiment-specific quantity 
for example, o.mroi.fb and o.mroi.eb might hold options for mroimake that are different for regions fb and eb
currently, these are the only vbins that will hold copybins by default

    o.mroi
    o.froi

this is because the roi extraction part of the pipeline (functional extraction, and manual and automated morphological extraction) allows the user to identify subregions of the fov (regionex) to designate unique analysis
if the user doesn't use any regionex, o.mroi and o.froi are each given one copybin, named 'default', which will correspond to the entire fov

in general, the user can apply this feature to generate more complex options structs, which might be useful for analyzing large batches of files, or multiple cell types

all the copybin used in creating o are stored in o.copybinprev; this information is not used in analysis (it is only used in creating o itself) 

----- files mode ----

odf can take optional name-value argument 'files'
when files is set to 1, odf will find stack files matching user input file specifiers (or defaults, if user doesn't specify anything)
found files and identifiers are stored in o.id 
o.id is the only field directly within o (besides copybinprev) that does not have defaults, and does not refer to a function (since it holds found files for each run of a2p)
the specifiers used to find those files are stored in o.spec (spec stands for file specifiers)

----- nonscalar o -----

o itself can be nonscalar when odf is run with 'files' option set to true and multiple stack files are found 
in this case odf will have length matching the number of files
the user can use this feature to set different options for different recordings

----- restrictions ----

any vbin or option not in d in odf will cause error, to prevent user setting invalid or unused options
default values in odf currently do not enforce any restrictions, although in the future they should to prevent the user from setting invalid options 


----- examples -----

example 1 (zero-argument syntax):
    
        o = odf

    o will contain all defaults (listed in options struct d in odf)

-----
example 2 (one-argument syntax):
    
        o.vbin1.vbin2.optionA = 2
        o = odf(o);
    
    output o will contain all default values for vbin1 (listed in d.vbin1), and all default values for vbin2 (listed in d.vbin2), except optionA, assuming its value here (2) doesn't match the value of d.vbin2.optionA in odf

-----
example 3 (two-argument syntax)
    
        o.vbin1.optionA = 2
        o.vbin2.optionA = 3
        o = odf(o, {'vbin2'});

    this will only update o with values in substruct vbin2
    output o will contain all defaults for vbin2, except o.vbin2.optionA = 3, while everything else in o will be unchanged 
    if you need to set options for a subfield after it's already been set in o, you can use this syntax to update specific vbin without affecting the others 

        o.vbin1.optionA = 2
        o = odf(o, {'vbin2'});

    output o will contain all defaults for vbin2 (since it is not in input o), and defaults will not be invoked for vbin1 


-----
example 3 (three-argument syntax)

        o.vbin1.vbin2.optionA = 2
        o.vbin3.vbin3.optionA = 2
        o = odf(o, {'vbin3', 'vbin4'}, {'copybin1', 'copybin2');

    output o will contain the same vbin1 described in example 2
    output o will also contain vbin3 and vbin4, each of which will contain copybin1 and copybin2; fubbin3.copybin1.optionA and fubbin3.copybin2.optionA will equal 2, with all other options default, and fubbin4.copybin1 and fubbin4.copybin2 will contain defaults for all options
    if copybins are listed for vbins that are not in o (but which are in d), all defaults are used for those vbins in their copybins
    it is a convenient way to copy all the options in specified vbin into multiple substructs (here, copybin1 and copybin2)
    which allows you to set different options for each substruct (for example, to concisely set different options for different regions of the fov, different neurons, or different recordings, etc)

-----
example 4 (nested vbin, 2- or 3-argument syntax)
    
    vbin arguments can be nested to update a nested vbin  
    nested vbin must start with the top level vbin
   
        o.vbin1.vbin2.optionA = 2
        o = odf(o, {'vbin1.vbin2'});
    
    this will set all defaults throughout the entire branch vbin1.vbin2, except vbin1.vbin2.optionA, which will be set to 2
    
    you can also use nested vbin arguments with copybin arguments
        
        o.vbin1.vbin2.optionA = 2
        o = odf(o, {'vbin1.vbin2'}, {'copybin1', 'copybin2'});
    
    this will create o.vbin1.vbin2.copybin1 and o.vbin1.vbin2.copybin2, with all defaults throughout both branches, except o.vbin1.vbin2.copybin1.optionA and o.vbin1.vbin2.copybin2.optionA will be 2

---- breaking things ----

odf can fail if you have a cell array of structs in o (although there is currently no need for this)

%}

arguments
    recin = [] %recin can be empty, or not passed as argument, and will search for file using fspc* below; recin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, pass recin as 'nofile'
end

if strcmp(recin, 'nofile') %if the only input to oset is 'nofile', will do everything but skip searching for files (and skip setting globals)
    dofindfiles = 0;
else
    dofindfiles = 1;
end

%%%% user-defined recording specifiers (if no input to a2p) %%%%

o.spec.pthparent_local = '~/stacks';
o.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(recin) %if you're running a2p without input arguments (ie if recin is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not recin is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    o.spec.recdate = {'2024*'}; %cell array of char (or scalar char), can use wildcards
    o.spec.fly = {'*'}; %cell array of char (or scalar char), can use wildcards
    o.spec.trial = {'*'}; %cell array of char (or scalar char), can use wildcards
    o.spec.suffix = {'*'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in validsuffix
    o.spec.match = 'each'; %'any' or 'each'; 'any' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
    o.spec.pth = '';
elseif iscell(recin) || ischar(recin) %if input to a2p is not empty, and is not struct 
    if strcmp(recin, 'nofile') %if input to oset is just 'nofile', skip file search part (but set all options otherwise); 'nofile' is not a valid input to a2p, but is a valid input to oset (so the user can query all options from anywhere in a2p without having to redefine found files, which can be slow and also confounding
        o.spec.pth = '';
    else % if input to a2p is char or cell of file paths with optional wildcards, find files matching those paths
        o.spec.pth = recin;
    end
end

%%%% dos %%%%

o.mn.dodaq = 1; %process daq timeseries?
o.mn.doftv = 1; %process fictrac video?
o.mn.dopop = 0; %compute bump?
o.mn.dofit = 0; %fit model?
o.mn.dopltx = 1; %enter pltx for summary interactive plots?

%%%% some simple option specification %%%%

o.daq.useinds = 'none'; %how to resample daq timeseries

o.sld.chanuse = 1;
o.sld.suffixplt = {'raw', 'cmrg', 'cmrg_dcdn'}; %which stacks to plot in gif for comparison; empty to skip plot

o.sld.sp.dr = {[0,1], [0,1], [0,1]}; %display range for stacks listed in o.sld.suffixplt; one vector for all, or can do one for each o.sld.suffixplt
o.sld.sp.it = [50.3]; % t indices for gif showing o.sld.suffixplt

o.ftv.smsdspace = 2;
o.ftv.doplt = 1;

%%%% compute bump %%%%

o.pop.bump.domain_method = 'functional';
o.pop.bump.mfit.tg.v1{1} = {['resp.fb*.mo*.*rsc000100_*chn1']}; %extract bump using all variables matching this string as dependent variable
o.pop.bump.mfit.tg.v2{1} = {['vis.yaw']}; %extract bump using all variables matching this string as independent variable

%%%% fit model %%%%

o.mfit(1).tg.v1{1} = {['resp.fb*.mo*.*_chn1']}; %fit model using all variables matching this string as dependent variable
o.mfit(1).tg.v2{1} = {['ball.forvel']}; %fit model using all variables matching this string as inddependent variable
o.mfit(1).mdlname = 'fnet_A01_s'; %see notes_mdlname for how to use 

%%%% pltx (interactive plots) %%%%

o.pltx.tg.v1{1} = {['ball.forvel']};  %interactive plots using all variables matching this string as timeseries one
o.pltx.tg.v5{1} = {['resp.fb256.mo*.*chn1.ind1']};  %interactive plots using all variables matching this string as timeseries two
o.pltx.lagsxy_sec = {0, 1, 'all'}; %lags for interactive scatterplot; vector, or if you want all within range, put in cell like this {min, max, 'all'}
o.pltx.lagsz_sec = {0, 1, 'all'}; %lags for interactive scatterplot; vector, or if you want all within range, put in cell like this {min, max, 'all'}

%%%% mroi (morphological rois) %%%%

o.mroi.dodraw = 1;
o.mroi.doimhsv = 0; %show hsvmap of rois?
o.mroi.wavp = []; %[0 50]; wavelet cwt periods to keep; seconds; carl uses [0 50] often to remove slow fluctuations; empty to skip
o.mroi.seg.chan = [1];
o.mroi.seg.numroi = 0; %nonzero to automate mroi extraction (after optional mask draw)
o.mroi.seg.maskseg = 'uniform';
o.mroi.seg.do3d = 1;
o.mroi.seg.doplt = 0;
o.mroi.nrm.post = {'f', 'dff010020'}; %how to normalize roi responses; 'f' is raw, 'dff010020' is dff with f as 10th percentile over 20-sec sliding window

%%%% froi (functional/caiman rois) %%%%

o.froi.roistr = {'2_1_*_graph_3dex'}; %which caiman roi extraction run to use (string lists extraction params)
o.mroi.nrm.post = {'f'}; %how to normalize roi responses; 'f' is raw, 'dff010020' is dff with f as 10th percentile over 20-sec sliding window

%%%% create o for the first time for the simple options specified thusfar %%%%

o = odf(o); %set all above options and find files (unless oset input recin is 'nofile')

%%%% create distinct options (or not) for different regionex %%%%

o.mn.regionex = {'fb1', 'fb2', 'pb'}; %empty to skip mroimake and froiproc; list any regionex you want to define for independent mroi or froi analysis, which will be associated with unique timeseries available for model fitting (mfit) or interactive plots (pltx); these do not have to be subregions of fov, or even unique regions of fov, although the user is prompted with that option; empty will use regionex named 'default'

if isempty(o.mn.regionex)
    o = odf(o, 'froi', glb('noregionex')); %put froi within copybin called 'noregionex', which will skip froi routine
else

    o = odf(o, 'froi', o.mn.regionex); %create froi options for each regionex

    for k = 1:numel(o.mn.regionex) %create different copybin within o.mroi for each regionex, to analyze them differently
        if startsWith(o.mn.regionex, 'fb')
            o.mroi.seg.numroi = 512; %use automated mroi for any regionex starting with 'fb' only
        else
            o.mroi.seg.numroi = 0; %skip automated mroi for all other regionex
        end
        o = odf(o, {'mroi'}, o.mn.regionex{k});
    end
end

%%%% create distinct options (or not) for different found recordings %%%%

o = odf(o, files=dofindfiles); %now find files (unless oset input recin is 'nofile'), otherwise changing nothing

allrecs = getfieldns([o.id], 'recdate');
recgroup1 = find(contains(allrecs, '202406')); %index of all found files in june of this year
recgroup2 = find(contains(allrecs, '202409')); %index of all found files in september of this year
for k = 1:numel(allrecs)
    if ismember(k, recgroup1)
        o(k).sld.chanuse = [2]; %use channel 2 in recgroup1, recordings from neither recgroup are unchanged from settings above (or from default, if none set above in oset)
    elseif ismember(k, recgroup2)
        o(k).sld.chanuse = [1 2]; %use both channels in recgroup2, recordings from neither recgroup are unchanged from above (or from default, if none set above in oset)
    end
end
%%%% options for carl's old project %%%%

oldcarlo %ignored if you're not carl

%%%% organize %%%%

o = fieldord(o); %recursively order alphabetically

[~, oflatfn] = structflat(o, 'prefix', 'o'); %get flattened fieldnames for user to see options struct organization more easily (does not get used); need prefix to make valid fieldnames in case nonscalar


end













