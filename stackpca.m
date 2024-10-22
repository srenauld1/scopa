sz = size(stack);
blocks = [4 4 1 1];
szblk = sz./blocks;
maxpool=sepblockfun(stack,blocks,'max');
maxpool_r = reshape(mat2gray(maxpool), [], sz(4));
[coeff,score,latent] = pca(maxpool_r');
comp1 = score(:,2)*coeff(:,2)';
frind = size(comp1,1);
comp1_img = reshape(comp1(frind,:),szblk(1:3));
clim = [min(comp1_img(:)) max(comp1_img(:))];
figure;
hax = cell(sz(3),1);
for k = 1:sz(3)
    hax{k} = subplot(3,4,k);
    image(hax{k}, comp1_img(:,:,k), CDataMapping = 'scaled');
    hax{k}.CLim = clim;
end
