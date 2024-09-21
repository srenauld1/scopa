function pthsv = pthauto(vnm, opt)

arguments
    vnm
    opt.glob = 'pthfldr'
    opt.suffix = ''
    opt.usetime = 1
    opt.usefun = 1
end

vnm = inputname(1);
fndefault = '00000_NONAME';

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnnm = callstack(2).file;
else
    fcnnm = 'unknownfunction';
end
pthfldr = globals_a2p(opt.glob);
if isempty(pthfldr)
    error(sprintf("global variable " + opt.glob + " has not been set" + newline + "and " + vnm + " was not passed as argument into function " + fcnnm + newline + "do one or the other"))
end
infix = '';
if opt.usefun
    [~,tmp,~]=fileparts(fcnnm);
    infix = [infix '_' tmp];
end
if opt.usetime
    tmp = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
    infix = [infix '_' tmp];
end
infix = [fndefault infix];

if ~startsWith(opt.suffix, '_')
    opt.suffix = ['_' opt.suffix];
end
pthsv = [pthfldr infix opt.suffix];

end