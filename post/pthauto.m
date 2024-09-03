function pthsv = pthauto(vnm, opt)

arguments
    vnm
    opt.glob = 'pthfldr'
    opt.suffix = ''
    opt.usetime = 1
end

vnm = inputname(1);

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnnm = callstack(2).file;
else
    fcnnm = 'unknown function';
end
pthfldr = globals_a2p(opt.glob);
if isempty(pthfldr)
    error(sprintf("global variable " + opt.glob + " has not been set" + newline + "and " + vnm + " was not passed as argument into function " + fcnnm + newline + "do one or the other"))
end
if opt.usetime
    infix = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
else
    infix = '';
end
infix = ['00000_NO_FILENAME_' infix];

pthsv = [pthfldr infix opt.suffix];

end