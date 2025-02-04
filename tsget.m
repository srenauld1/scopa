%{

ts holds timeseries, column vectors, same length, aligned
format is:
    ts.domain.optid.name
    examples from different domains:
        ts.roi.optid.name (name=roi index ie ind1, ind2, . . . indN)
        ts.daq.optid.name (name=daq variable name, eg fv for forward velocity or g4pos for g4 bar position or t for timestamp)
        ts.bmp.optid.name (name=extracted feature name, eg bumpang for bump mean angular position)
    when options are not variable (e.g. daq variables are currently extracted with a hard-coded options set), optid is 'none'
tsget recovers timeseries from ts (since ts can be complex)
mdlmake, feat, and pltx use tsget to simplify timeseries recovery, variable names, and file names

tsget first argument is ts, and remaining arguments are all name-value: domain, optused, name, group

    domain
        domain is char array, must exist in ts
        empty returns all
        
    optused 
        optused is a struct containing a subset of the options used to create timeseries, or just the optid assigned to an options set
        since all unique options sets have an optid, optused.optid is sufficient to recover timeseries 
        optused.optid is a char array, which can contain asterisk as wildcard
        for more control, or if you don't know the optid, pass individual options in optused (in this case you cannot pass optid)
        optused must be valid given the domain argument
        if any optused are cell arrays, they are expanded and all results are found 
        empty returns all for the given domain

    name
        name is a numeric scalar or vector, or empty vector
        name must be valid given the domain and optused arguments
        empty vector returns all for the given domain and optused

    group
        group determines how output timeseries are arrayed in the 3rd dimension 
        the 3rd dimenion is the looping dimension in all functions that use tsget (eg mdlmake loops over 3rd dim to fit seperate models with the same options but different timeseries, pltx loops over the 3rd dimension to present groups of variables, feat loops over 3rd dim to extract features from different sets of timeseries)
        group can take the following values: 'all', 'domain', 'optused', 'name', 
        these refer to tsget input arguments, which can each be expanded to return multiple timeseries; 
        group determines whether output should be group according to that expansion; 
            all: like the inverse of 'name'; output 1st dimension length matches number of found timeseries and 3rd dimension is singleton; 
            domain: array domain groups along 3rd dimension 
            optused: array optused groups along 3rd dimension 
            name: like the invserse of 'all'; output 3rd dimension length matches number of found timeseries, and 1st dimension is singleton; 

% setting mdlmake indv (independent variable) using tsget input struct
    tgtmp.domain = {'daq', 'roi'} %daq domain
    tgtmp.optused = {'none' %daq variables extracted with default set of daq options 
    tgtmp.name = [] %all indices (all rois)
    tgtmp.group = 'name' %fit model to each output timeries 
    o.mdl.indv.tg = tgtmp %make depv a struct, which will flag it to find timeseries for depv using tg; depv struct is itself a struct for options input to tg; 

% setting mdlmake depv (dependent variable) using tsget input struct
    tgtmp.domain = 'roi' %roi domain
    roitmp.ma.numroi = 256
    roitmp.mm.drawchan = 2
    tgtmp.optused = roitmp %struct of roi options
    tgtmp.name = [] %all indices (all rois)
    tgtmp.group = 'name' %fit model to each 
    o.mdl.depv.tg = tgtmp %make depv a struct, which will flag it to find timeseries for depv using tg; depv struct is itself a struct for options input to tg; 

mdlmake and feat will also get optid

% setting pltx v1 using tsget input struct
    tgtmp.domain = 'roi' %roi domain
    roitmp.ma.numroi = 256
    roitmp.mm.drawchan = 2
    tgtmp.optused = roitmp %struct of roi options
    tgtmp.name = [] %all indices (all rois)
    tgtmp.group = 'name' %plot each
    o.mdl.v1.tg = tgtmp %make v1 a struct, which will flag it to find timeseries for v1 using tg; v1 struct is itself a struct for options input to tg; 

%}
