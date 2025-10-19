function opt = optidchk(mos, opt)

%make sure optid is correct 

arguments
    mos % short name for calling function, also name of field holding options in options struct (eg 'roi', 'daq', etc)
    opt % options for calling function
end

optiddf = glb('optiddf'); %get default optid from glb
if isempty(optiddf)
    optiddf = 'z0'; %if glb('optiddf') is not set, use default optid defined here
end

if isempty(opt.optid)
    opt.optid = optiddf;
else
    if ~strcmp(opt.optid, optiddf)
        usegit = glb('usegit', err=1);
        scopausername = userdatfile('scopausername');
        pthopt = [pthscopaget() 'opt_' mos '_' scopausername '_.txt'];
        [opt_file, optid_file, ~] = structfile(pthopt, s=[], nm=opt.optid, getonly=1, dosort=1);
        opt_file.optid = optid_file;
        if ~isequal(opt, opt_file)
            error("name-value argument optid and the optid associated with the opt input to module '" + mos + "' do not match")
        end
    end
end
