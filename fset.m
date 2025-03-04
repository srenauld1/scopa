function [opt, optid, pthstack, doplt] = fset(vbin, opt, pthstack, doplt)

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
    optid = opt.optid;
    if all(strcmp(fieldnames(opt), 'optid')) %if optid is the only option, create the corresponding options
        pthscopa = getpathscopa();
        user = glb('user');
        if isempty(user)
            error("you have not set glb('user')")
        end
        pthopt = [pthscopa 'opt_' vbin '_' user '_*_.txt'];
        optid_noprefix = optid(2:end);
        opt = structfile(pthopt, s=[], nm=optid_noprefix, useprefix=1);
    end
else
    optid = glb('optiddf');
    if isempty(optid)
        optid = 'z0';
    end
end

if isempty(doplt)
    doplt = any(strcmp(vbin, glb('plt')));
end