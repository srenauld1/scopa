function [opt, pthdat, doplt] = fset(vbin, opt, pthdat, doplt)

% set some required arguments for high level functions in a2p 

if isempty(opt)
    fprintf("user did not pass in options as argument, using all defaults for vbin '" + vbin + "'")
    opt = odf(vbin, fill=1, unpack=1);
end

vnm = inputname(3);
pthdat_glb = glb(vnm);
if isempty(pthdat)
    if isempty(pthdat_glb)
        error("you must either pass in argument " + vnm + " or set glb('" + vnm + "')")
    else
        pthdat = pthdat_glb;
    end
else
    if ~isempty(pthdat_glb)
        if ~isequal(pthdat, pthdat_glb)
            error("cannot pass in name-value argument " + vnm + " if you have already set glb('" + vnm  + "') to a different value; do one or the other, or make them equal; if you want to remove glb('" + vnm  + "'), do this: glb(-1, '" + vnm + "')")
        end
    end
end

if isfield(opt, 'optid') && ~isempty(opt.optid)
    optidtmp = opt.optid; %set it aside in case it's the only field, and you have to load opt (which will remove optid)
    if all(strcmp(fieldnames(opt), 'optid')) %if optid is the only option, create the corresponding options
        pthscopa = pathscopafind();
        scopausername = glb('scopausername');
        if isempty(scopausername)
            scopausername = userdatfile('scopausername');
        end
        usegit = glb('usegit');
        if isempty(usegit)
            usegit = 0;
        end
        pthopt = [pthscopa 'opt_' vbin '_' scopausername '_.txt'];
        optid_noprefix = optidtmp(2:end);
        opt = structfile(pthopt, s=[], nm=optid_noprefix, usegit=usegit, dupe=0, dosort=1);
        opt.optid = optidtmp; %put it back in
    end
else
    opt.optid = glb('optiddf');
    if isempty(opt.optid)
        opt.optid = 'z0';
    end
end

if isempty(doplt)
    doplt = any(strcmp(vbin, glb('plt'))); %false if glb('plt') has not been set
end
