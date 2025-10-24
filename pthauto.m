function pthsv = pthauto(opt)

arguments
    opt.pthdir char {mustBeTextScalar} = ''
    opt.suffix char {mustBeTextScalar} = '' %includes extension
    opt.usetime (1,1) {mustBeMember(opt.usetime,[0,1]), mustBeNonempty} = 1
    opt.usefun (1,1) {mustBeMember(opt.usefun,[0,1]), mustBeNonempty} = 1
end
pthdir = opt.pthdir;
suffix = opt.suffix;
usetime = opt.usetime;
usefun = opt.usefun;

fn_prefix = '00000000'; %filename prefix

if isempty(pthdir)
    pthdir = glb('pthsvdir');
    if isempty(pthdir)
        error("you must pass in name-value argument 'pthdir' or set glb('pthsvdir')")
    end
end
pthdir = pthfldformat(pthdir);
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
infix = [fn_prefix infix];

if ~isempty(suffix) && ~contains(suffix, '.')
    error("name-value argument must include file type extension")
end
if ~startsWith(suffix, '_')
    suffix = ['_' suffix];
end

pthsv = [pthdir infix suffix];

end