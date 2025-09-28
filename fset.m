function [opt, doplt, pth] = fset(obin, opt, doplt, pth)

% set some required arguments for high level functions in a2p

arguments
    obin %short name for calling function, also name of field holding options in options struct (eg 'roi', 'daq', etc)
    opt = [] %options for calling function
    doplt = [] %plot, or not
    pth = [] %path to data required for calling function (eg stack, daq file, etc)
end

optiddf = glb('optiddf'); %get default optid from glb
if isempty(optiddf)
    optiddf = 'z0'; %if glb('optiddf') is not set, use default optid defined here
end

if isempty(opt)
    fprintf("user did not pass in options as argument, using all defaults for obin '" + obin + "'")
    opt = ofill(obin, nest=1, unpack=1);
end

if nargin>=4
    vnm = inputname(4);
    pthglb = glb(vnm);
    if isempty(pth)
        if isempty(pthglb)
            error("you must either pass in argument " + vnm + " or set glb('" + vnm + "')")
        else
            pth = pthglb;
        end
    else
        if ~isempty(pthglb)
            if ~isequal(pth, pthglb)
                error("cannot pass in name-value argument " + vnm + " if you have already set glb('" + vnm  + "') to a different value; do one or the other, or make them equal; if you want to remove glb('" + vnm  + "'), do this: glb(-1, '" + vnm + "')")
            end
        end
    end
end

if isfield(opt, 'optid') && ~isempty(opt.optid)
    optid = opt.optid; %set it aside in case it's the only field, and you have to load opt (which will remove optid)
    if strcmp(optid, 'z0')

    else
        if all(strcmp(fieldnames(opt), 'optid')) %if optid is the only option, create the corresponding options
            pthscopa = pathscopaget();
            scopausername = glb('scopausername');
            if isempty(scopausername)
                scopausername = userdatfile('scopausername');
            end
            usegit = glb('usegit');
            if isempty(usegit)
                usegit = 0;
            end
            pthopt = [pthscopa 'opt_' obin '_' scopausername '_.txt'];
            opt = structfile(pthopt, s=[], nm=optid, usegit=usegit, dupe=0, dosort=1);
            opt.optid = optid; %put optid it back in opt struct
        end
    end
else
    opt.optid = glb('optiddf');
    if isempty(opt.optid)
        opt.optid = 'z0';
    end
end

if isempty(doplt)
    doplt = any(strcmp(obin, glb('plt'))); %false if glb('plt') has not been set
end
