function pthsv = pathauto(opt)

arguments
    opt.pthdir = []
    opt.suffix = '' %includes extension
    opt.usetime = 1
    opt.usefun = 1
end
pthdir = opt.pthdir;
suffix = opt.suffix;
usetime = opt.usetime;
usefun = opt.usefun;

fndefault = '00000000';

if isempty(pthdir)
    pthdir = glb('pthstackdir');
    if isempty(pthdir)
        error("you must pass in name-value argument 'pthdir' or set glb('pthstackdir')")
    end
end
if startsWith(pthdir, ['~' filesep])
    hm = [getenv('HOME') filesep];
    pthdir = regexprep(pthdir, ['^~' filesep], hm);
end
if ~endsWith(pthdir, filesep)
    error("pthdir (which is coped from from glb('pthstackdir') if you did not pass in name-value argument pthdir) must end with file separator")
end
if ~isfolder(pthdir)
    error("pthdir '" + pthdir + "' DOES NOT EXIST (OR AT LEAST IS NOT A FOLDER)")
end

callstack = dbstack('-completenames');
if numel(callstack) >= 2
    fcnnm = callstack(2).file;
else
    fcnnm = 'unknownfunction';
end

infix = '';
if usefun
    [~, tmp, ~] = fileparts(fcnnm);
    infix = [infix '_' tmp];
end
if usetime
    tmp = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
    infix = [infix '_' tmp];
end
infix = [fndefault infix];

if ~startsWith(suffix, '_')
    suffix = ['_' suffix];
end

pthsv = [pthdir infix suffix];

end