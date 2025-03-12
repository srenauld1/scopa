
%%

hackdim = 1;
vindtmp = 16;
pattmp = ['~/stacks/t5/22*/a' num2str(vindtmp) 'a17_mdl_.mat'];
pthtmp = rdir(pattmp);
load(pthtmp.name)
optidtmp = 'a8';
optidtmpmdl = 'a17';
ft = mdl.(optidtmpmdl).ft.v_0.ft;
fttmp = ft(hackdim,:);
stackmnt = roi.(optidtmp).dat{1}.stackmnt;
roipx = roi.(optidtmp).dat{1}.roipx;
fttmp = reshape(fttmp, numel(roipx), []);
ftim = zeros([size(stackmnt), size(fttmp,2)]);
for k = 1:size(ftim,3)
    tmpim = zeros(size(stackmnt));
    for m = 1:numel(roipx)
        tmpim(roipx{m}) = fttmp(m,k);
    end
    ftim(:, :, k) = tmpim;
end
stackplt(ftim, dmstack='yxt')
%%