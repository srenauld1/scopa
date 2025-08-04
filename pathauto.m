function pthsv = pathauto(opt)

arguments
    opt.pthstackdir = []
    opt.suffix = '' %includes extension
    opt.usetime = 1
    opt.usefun = 1
end

opt = glboropt(opt);

fndefault = '00000000';

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnnm = callstack(2).file;
else
    fcnnm = 'unknownfunction';
end

if isempty(opt.pthstackdir)
    error(sprintf("glb('pthstackdir') has not been set, and name-value argument pthstackdir has not been set; you must do one or the other"))
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

pthsv = [opt.pthstackdir infix opt.suffix];

end