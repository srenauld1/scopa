function opt = optidcheck(mos, opt)

%make sure optid is correct 

arguments
    mos % short name for calling function, also name of field holding options in options struct (eg 'roi', 'daq', etc)
    opt % options for calling function
end

optiddf = glbfile('optiddf'); %get default optid from glb

if isempty(opt.optid)
    opt.optid = optiddf;
else
    if ~strcmp(opt.optid, optiddf)
        pthopt = [pthscopaget() 'opt_' mos '_' userdatfile('scopausername') '_.txt'];
        [opt_file, optid_file, ~] = structfile(pthopt, s=[], nm=opt.optid, justld=1, dosort=1);
        opt_file.optid = optid_file;
        opt_file_fn = fieldnames(opt_file);
        opt_file_ne = rmfield(opt_file, opt_file_fn(structfun(@isempty, opt_file))); 
        opt_fn = fieldnames(opt);
        opt_ne = rmfield(opt, opt_fn(structfun(@isempty, opt)));
        if ~isequal(opt_ne, opt_file_ne) %check equality after removing empty fields because they can be different after read/write to txt file, since struct([]) becomes [], but functionally are the same
            error("name-value argument optid and the optid associated with the opt input to module '" + mos + "' do not match; note the difference is nontrivial since struct([]) and [] are considered equal here")
        end
    end
end
