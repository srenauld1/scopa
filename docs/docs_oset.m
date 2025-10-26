%{

deprecated, don't read this, just read docs at top of ofill.m

----- o, oset, and ofill ----- 

oset uses function ofill to set options for all major functions in a2p
ofill defines defaults options for all major functions in a2p
oset is just a wrapper for calling ofill in various ways, so the user can set options however they'd like

oset below shows one approach for using ofill to set options, but the same options struct cold be created in different ways

first output o is a nested struct containing all options used in major functions in a2p
defaults for all available options are in struct d in function ofill
all option defaults are also set within each major function (so the user could skip passing optional arguments with the options struct created here)

oset is a wrapper for ofill; it is intended to be the only place the user might want to adjust options to a2p; 
if they don't want to adjust options, they could, in theory, just replace a call to oset with a call to ofill (with no arguments, since zero argument syntax returns all defaults and all stack files in the filesystem)

second output oflat is a flattened version of o, and is just for inspection, for the user's convenience; a2p uses o, not oflat  

reason for using o, oset, and ofill:
    modularity
    minimize number of defaults
    all options in one place (o output from oset, with defaults d defined in ofill)
    can access all default options anywhere in a2p by calling ofill without input arguments, or can access user defined o by calling oset from anywhere in a2p (which will just recreate the entire o)

for simplicity, this file shows only options the user is likely to want to change

----- fields of o -----

field can be 
    option (which can be struct of options)
    function (a struct with fields that are the function's options; name represents the function)
    output (a struct, name represents the output of a function in struct above; used when function can be called more than once)

besides o itself, all structs are scalar; there is no need for nonscalar struct within o
o is nonscalar for multiple recordings
we use a nonscalar struct when the input/output map can be named with info in the struct; and when all elements must contain the same fields
we use a field when the input/output map cannot be named with info in the struct (requires the fieldname); and when each substruct can have variable fields (this is possible since each obin can have a subset of its function's inputs, invoking defaults within the function)

ofill is just a wrapper for ofill_scalar; ofill_scalar operates on scalar struct argument oin; ofill just loops over elements of oin

----- cell array options and expansion -----

when options appear as cell, each cell element is applied to a unique options set (this is called 'expansion', and is performed by function oid)
any text option that can be nonscalar must be a string array (rather than a char cell array), so that it can be placed in a cell for expansion 
most 

----- options struct o, organization -----

o is the option struct for a2p
o is a struct containing obins
each obin is a container for options that can be passed as arguments to a major function in a2p
the fields of the obin are the options
some minor functions also have optional arguments, but they are not listed in ofill (or oset) because they are less likely to need adjusting 
options set here (ie options with defaults defined in ofill) are only used in the functions denoted by their enclosing obin; 
obin names are similar to, or abbreviated forms of, their associated functions
here is a complete list of obins and functions they hold options for (see also section headers in ofill)


    mn, a2p
    spec, stackfind   (called from ofill)
    dq, daqld   (called from a2p)
    spr, stackseries   (called from a2p)
    sld, stackld   (called from stackseries)
    ftv, ftvalign   (called from a2p)
    roi, roimake   (called from a2p)
    ma, roimauto   (called from roimake)
    roif, roifauto   (called from a2p)
    nrm, roits   (called from roimake and roifauto)
    pop, popcmp   (called from a2p)
    bmp, bmpmake   (called from popcmp)
    mdlmake, mdlmake   (called from a2p)
    vg, vget   (called from, bmpmake, mdlmake, and pltx)
    pltx, pltx   (called from a2p)
    tp, tsplt   (called from various functions for visualization) 
    sp, stackplt   (called from various functions for visualization) 
    imhsv, imhsvplt   (called from various functions for visualization)


obin fields are all optional arguments to their associated functions (the user could skip passing the substruct variables, which would just use default values)
each obin has default values listed in struct d of ofill

obin fields in ofill can themselves be structs (optbin) holding options
for example, 
    o.obin1.optbin1.option1 = 2 and o.obin1.optbin1.option2 = 3
    this means obin1 has a struct optbin1 which is a struct that holds option1 and option2
    optbins will be listed in defaults in ofill, although there are currently no optbins, for simplicity


----- obin nesting -----

obin fields can also be obins
obins can be nested within obins arbitrarily, although the nesting must reflect the organization of a2p (nesting of major functions)
if you reorganize a2p, you might need to reorganize how obins are nested in o
there is no obin nesting in default struct d (in ofill), since each obin refers to a function that is meant to be modular (can in theory be called by itself; this also reduces the number of defaults required in ofill)  

o.obin1 means the function obin1 refers to is called directly from a2p, 
o.obin1.obin2 means the function obin2 refers to is called from the function obin1 refers to, and the function obin1 refers to is called directly from a2p
it's done this way because because several functions get called multiple times in different locations, so this reduces the number of default options (ie this way you don't have to set different defaults for the samer function called from different locations

here are the current valid obin nestings within o (reflecting organization of major functions)
these nested obins will be set in o, by user or by default
for brevity, only the deepest nesting of each unique branch is shown

    o.spr.sp   (stackplt called from within stackseries called from a2p)
    o.spr.sld   (stackld called from within stackseries called from a2p)
    o.bmp   (bmpmake called from within popcmp called from a2p)
    o.mdl.vg   (vget called from within mdlmake called from a2p)
    o.mdl.sp   (stackplt called from within mdlmake called from a2p)
    o.mdl.tp   (tsplt called from within mdlmake called from a2p)
    o.pltx.vg   (vget called from within pltx called from a2p)
    o.roi.mm   (roidraw called from within roimake called from a2p)
    o.roi.ma   (roimauto called from within roimake called from a2p)
    o.roi.qc   (roifauto called from within roimake called from a2p)
    o.roi.nrm   (tsnorm called from within roimake called from a2p)
    o.roi.sp   (stackplt called from within roimake called from a2p)
    o.roi.imhsv   (hsvplt called from within roimake called from a2p)

----- nonscalar obin -----

a obin can be nonscalar struct; 
if at least one field specification for obin includes index p, all unspecified fields for all struct indices up to index p are filled with defaults 
(e.g see how options are set in 'mdl' section below); 
alternatively, struct index can be assigned in the output of ofill
nonscalar obins are used in for loops in the pipeline (if e.g o.roi.ma has 3 elements, it means o.roi.ma(1), o.roi.ma(2), and o.roi.ma(3) are passed to roimauto sequentially (roimauto is the function corresponding to obin ma

----- copybin -----

a obin can contain a copybin, which is a struct that holds options for an experiment-specific quantity 
for example, o.roi.fb and o.roi.eb might hold options for roimake that are different for regions fb and eb
currently, this is the only obin that will hold copybins by default

    o.roi

this is because the roi extraction part of the pipeline (functional extraction, and manual and automated morphological extraction) allows the user to identify subregions of the fov (rgname) to designate unique analysis
if the user doesn't use any rgname, o.roi is given one copybin, named 'none', which will correspond to the entire fov

in general, the user can apply this feature to generate more complex options structs, which might be useful for analyzing large batches of files, or multiple cell types

all the copybin used in creating o are stored in o.copybinprev; this information is not used in analysis (it is only used in creating o itself) 

----- files mode ----

ofill can take optional name-value argument 'files'
when files is set to 1, ofill will find stack files matching user input file specifiers (or defaults, if user doesn't specify anything)
found files and identifiers are stored in o.id 
o.id is the only field directly within o (besides copybinprev) that does not have defaults, and does not refer to a function (since it holds found files for each run of a2p)
the specifiers used to find those files are stored in o.spec (spec stands for file specifiers)

----- nonscalar o -----

o itself can be nonscalar when ofill is run with 'files' option set to true and multiple stack files are found 
in this case ofill will have length matching the number of files
the user can use this feature to set different options for different recordings

----- restrictions ----

any obin or option not in d in ofill will cause error, to prevent user setting invalid or unused options
default values in ofill currently do not enforce any restrictions, although in the future they should to prevent the user from setting invalid options 


----- examples -----

example 1 (zero-argument syntax):
    
        o = ofill

    o will contain all defaults (listed in options struct d in ofill)

-----
example 2 (one-argument syntax):
    
        o.obin1.obin2.optionA = 2
        o = ofill(o);
    
    output o will contain all default values for obin1 (listed in d.obin1), and all default values for obin2 (listed in d.obin2), except optionA, assuming its value here (2) doesn't match the value of d.obin2.optionA in ofill

-----
example 3 (two-argument syntax)
    
        o.obin1.optionA = 2
        o.obin2.optionA = 3
        o = ofill(o, {'obin2'});

    this will only update o with values in substruct obin2
    output o will contain all defaults for obin2, except o.obin2.optionA = 3, while everything else in o will be unchanged 
    if you need to set options for a subfield after it's already been set in o, you can use this syntax to update specific obin without affecting the others 

        o.obin1.optionA = 2
        o = ofill(o, {'obin2'});

    output o will contain all defaults for obin2 (since it is not in input o), and defaults will not be invoked for obin1 


-----
example 3 (three-argument syntax)

        o.obin1.obin2.optionA = 2
        o.obin3.obin3.optionA = 2
        o = ofill(o, {'obin3', 'obin4'}, {'copybin1', 'copybin2');

    output o will contain the same obin1 described in example 2
    output o will also contain obin3 and obin4, each of which will contain copybin1 and copybin2; fubbin3.copybin1.optionA and fubbin3.copybin2.optionA will equal 2, with all other options default, and fubbin4.copybin1 and fubbin4.copybin2 will contain defaults for all options
    if copybins are listed for obins that are not in o (but which are in d), all defaults are used for those obins in their copybins
    it is a convenient way to copy all the options in specified obin into multiple substructs (here, copybin1 and copybin2)
    which allows you to set different options for each substruct (for example, to concisely set different options for different regions of the fov, different neurons, or different recordings, etc)

-----
example 4 (nested obin, 2- or 3-argument syntax)
    
    obin arguments can be nested to update a nested obin  
    nested obin must start with the top level obin
   
        o.obin1.obin2.optionA = 2
        o = ofill(o, {'obin1.obin2'});
    
    this will set all defaults throughout the entire branch obin1.obin2, except obin1.obin2.optionA, which will be set to 2
    
    you can also use nested obin arguments with copybin arguments
        
        o.obin1.obin2.optionA = 2
        o = ofill(o, {'obin1.obin2'}, {'copybin1', 'copybin2'});
    
    this will create o.obin1.obin2.copybin1 and o.obin1.obin2.copybin2, with all defaults throughout both branches, except o.obin1.obin2.copybin1.optionA and o.obin1.obin2.copybin2.optionA will be 2

---- breaking things ----

ofill can fail if you have a cell array of structs in o (although there is currently no need for this)

%}