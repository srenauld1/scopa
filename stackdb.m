function [stack, psfe] = stackdb(stack, opt)

arguments
    stack
    opt.doiso = []
    opt.widyxz = []
    opt.domnt = []
    opt.doet = []
    opt.frac = []
    opt.itplt = []    
    opt.dmplt = []
    opt.doplt = []
end
doiso = opt.doiso;
domnt = opt.domnt;
doet = opt.doet;
widyxz = opt.widyxz;
frac = opt.frac;
itplt = opt.itplt;
dmplt = opt.dmplt;
doplt = opt.doplt;



if isempty(doiso)
    doiso = 0;
end
if isempty(domnt)
    domnt = 0;
end
if isempty(doet)
    doet = 0;
end
if isempty(frac)
    frac = 0.25;
end
if isempty(itplt)
    itplt = linspace(1,size(stack,4),20);
end
if isempty(dmplt)
    dmplt = 'yxz(t)';
end
if isempty(doplt)
    doplt = 0;
end

szpsf = round(size(stack, [1,2,3])*frac);
psfi = ones(szpsf);

stacktmp = stack(:,:,:,itplt);

if doiso
    if isempty(widyxz)
        error("widyxz cannot be empty if doiso is true")
    end
    stack = stackiso(stack,widyxz,dir='for');
end

if domnt
    [stackmntdb_init, psfe_init] = deconvblind(mean(stack,4),psfi);
    psfi = psfe_init;
end

if doet
    stack = edgetaper(stack,psfi);
end

for k = 1:size(stack,4)
    [stack(:,:,:,k), psfe] = deconvblind(stack(:,:,:,k),psfi);
end

stack = stackiso(stack,widyxz,dir='rev');


stacktmpdb = stack(:,:,:,itplt);


if doplt
    dmplt_no_t = erase(dmplt, {'(',')','t'});
    if ~isequal(dmplt,dmplt_no_t)
        stackplt({stacktmp;stacktmpdb}, dmplt=erase(dmplt_no_t, 't'))
    end
    stackplt({stacktmp;stacktmpdb}, dmplt=dmplt)
end

end
