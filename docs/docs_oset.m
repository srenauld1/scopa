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

----- fields of o -----

field can be 
    option (which can be struct of options)
    function (a struct with fields that are the function's options; name represents the function)
    output (a struct, name represents the output of a function in struct above; used when function can be called more than once)

besides o itself, all structs are scalar; there is no need for nonscalar struct within o
o is nonscalar for multiple recordings
we use a nonscalar struct when the input/output map can be named with info in the struct; and when all elements must contain the same fields
we use a field when the input/output map cannot be named with info in the struct (requires the fieldname); and when each substruct can have variable fields (this is possible since each vbin can have a subset of its function's inputs, invoking defaults within the function)

odf is just a wrapper for odfscal; odfscal operates on scalar struct argument oin; odf just loops over elements of oin

----- cell array options and expansion -----

when options appear as cell, each cell element is applied to a unique options set (this is called 'expansion', and is performed by function opt2id)
any text option that can be nonscalar must be a string array (rather than a char cell array), so that it can be placed in a cell for expansion 
most 

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
    spec, stackfind   (called from odf)
    daq, daqld   (called from a2p)
    sld, stackld   (called from a2p)
    ftv, ftvproc   (called from a2p)
    roi, roimake   (called from a2p)
    ma, roimauto   (called from roimake)
    roif, roifmake   (called from a2p)
    nrm, roits   (called from roimake and roifmake)
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
    o.roi.mm   (drawrois called from within roimake called from a2p)
    o.roi.ma   (roimauto called from within roimake called from a2p)
    o.roi.fa   (roifmake called from within roimake called from a2p)
    o.roi.nrm   (respnorm called from within roimake called from a2p)
    o.roi.sp   (stackplt called from within roimake called from a2p)
    o.roi.imhsv   (hsvplt called from within roimake called from a2p)

----- nonscalar vbin -----

a vbin can be nonscalar struct; 
if at least one field specification for vbin includes index p, all unspecified fields for all struct indices up to index p are filled with defaults 
(e.g see how options are set in 'mfit' section below); 
alternatively, struct index can be assigned in the output of odf
nonscalar vbins are used in for loops in the pipeline (if e.g o.roi.ma has 3 elements, it means o.roi.ma(1), o.roi.ma(2), and o.roi.ma(3) are passed to roimauto sequentially (roimauto is the function corresponding to vbin ma

----- copybin -----

a vbin can contain a copybin, which is a struct that holds options for an experiment-specific quantity 
for example, o.roi.fb and o.roi.eb might hold options for roimake that are different for regions fb and eb
currently, this is the only vbin that will hold copybins by default

    o.roi

this is because the roi extraction part of the pipeline (functional extraction, and manual and automated morphological extraction) allows the user to identify subregions of the fov (regionex) to designate unique analysis
if the user doesn't use any regionex, o.roi is given one copybin, named 'dflt', which will correspond to the entire fov

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