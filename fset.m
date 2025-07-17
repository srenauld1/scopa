function [opt, pthdat, doplt] = fset(vbin, opt, pthdat, doplt)


if isempty(opt)
    fprintf("user did not pass options as argument, using all defaults")
    opt = odf(vbin, fill=1, unpack=1);
end

vnm = inputname(3);
if isempty(pthdat)
    pthdat = glb(vnm);
    if isempty(pthdat)
        error("you must either pass argument " + vnm + " or set glb('" + vnm + "')")
    end
end

if isfield(opt, 'optid') && ~isempty(opt.optid)
    optidtmp = opt.optid; %set it aside in case it's the only field, and you have to load opt (which will remove optid)
    if all(strcmp(fieldnames(opt), 'optid')) %if optid is the only option, create the corresponding options
        pthscopa = getpathscopa();
        scopausername = glb('scopausername');
        if isempty(scopausername)
            error("you have not set glb('scopausername')")
        end
        pthopt = [pthscopa 'opt_' vbin '_' scopausername '_.txt'];
        optid_noprefix = optidtmp(2:end);
        opt = structfile(pthopt, s=[], nm=optid_noprefix, usegit=0, dupe=0, dosort=1);
        opt.optid = optidtmp; %put it back in
    end
else
    opt.optid = glb('optiddf');
    if isempty(opt.optid)
        opt.optid = 'z0';
    end
end

if isempty(doplt)
    doplt = any(strcmp(vbin, glb('plt')));
end
