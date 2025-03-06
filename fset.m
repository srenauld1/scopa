function [opt, pthstack, doplt] = fset(vbin, opt, pthstack, doplt)

if isempty(opt)
    fprintf("user did not pass options as argument, using all defaults")
    opt = odf(vbin, fill=1, unpack=1);
end
if isempty(pthstack)
    pthstack = glb('pthstack');
    if isempty(pthstack)
        error("you must either pass argument pthstack or set glb('pthstack')")
    end
end

if isfield(opt, 'optid') && ~isempty(opt.optid)
    optidtmp = opt.optid; %set it aside in case it's the only field, and you have to load opt (which will remove optid)
    if all(strcmp(fieldnames(opt), 'optid')) %if optid is the only option, create the corresponding options
        pthscopa = getpathscopa();
        user = glb('user');
        if isempty(user)
            error("you have not set glb('user')")
        end
        pthopt = [pthscopa 'opt_' vbin '_' user '_*_.txt'];
        optid_noprefix = optidtmp(2:end);
        opt = structfile(pthopt, s=[], nm=optid_noprefix, useprefix=1);
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