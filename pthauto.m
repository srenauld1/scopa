function pthsv = pthauto(opt)

arguments
    opt.glbvar = 'dirstack'
    opt.suffix = ''
    opt.usetime = 1
    opt.usefun = 1
end

fndefault = '00000000';

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnnm = callstack(2).file;
else
    fcnnm = 'unknownfunction';
end
dirstack = glb(opt.glbvar);
if isempty(dirstack)
    vnm = inputname(1);
    error(sprintf("glbvaral variable " + opt.glbvar + " has not been set" + newline + "and a save path was not passed as argument into function " + fcnnm + newline + "do one or the other"))
end
infix = '';
if opt.usefun
    [~, tmp, ~] = fileparts(fcnnm);
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
pthsv = [dirstack infix opt.suffix];

end