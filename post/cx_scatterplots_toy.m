

bumpballcorr = 2.6;
bumpcontribution = 2.6;
nodulusnoise = 0.2;

fuk1 = rand(10000,1);
fuk2 = bumpballcorr*fuk1 + rand(10000,1);
fuk2 = fuk2 / max(fuk2);
fuk3 = fuk1 + 0*fuk2 + nodulusnoise*rand(10000,1);
fuk3 = fuk3 / max(fuk3);

hfg1 = figure; sgtitle({'NO AS LINEAR FUNCTION OF BALL ONLY (TOP) OR BALL AND BUMP (BOTTOM)'; 'WITH BALL AND BUMP WEAKLY CORRELATED'})
subplot(2,4,1); scatter(fuk1, fuk2, 2, 'filled'); axis square; xlabel('ball'); ylabel('bump'); %title('bump vs ball');
subplot(2,4,2); scatter(fuk1, fuk3, 2, 'filled'); axis square; xlabel('ball'); ylabel('NO'); %title('bump vs NO');
subplot(2,4,3); scatter(fuk2, fuk3, 2, 'filled'); axis square; xlabel('bump'); ylabel('NO'); %title('ball vs NO');

[~, idx4] = sort(fuk3);
fuk1 = fuk1(idx4);
fuk2 = fuk2(idx4);
cmp = jet(length(idx4));
subplot(2,4,4); scatter(fuk1, fuk2, 2, cmp, 'filled'); axis square; xlabel('ball'); ylabel('bump'); title('NO is color')

%hfg2 = figure; scatter3(fuk1, fuk2, fuk3, 2, 'filled'); axis square
% xlabel('ball'); ylabel('bump'); zlabel('NO')

fuk1 = rand(10000,1);
fuk2 = bumpballcorr*fuk1 + rand(10000,1);%.*rand(10000,1);
fuk2 = fuk2 / max(fuk2);
fuk3 = fuk1 + bumpcontribution*fuk2 + nodulusnoise*rand(10000,1);
fuk3 = fuk3 / max(fuk3);

subplot(2,4,5); scatter(fuk1, fuk2, 2, 'filled'); axis square; xlabel('ball'); ylabel('bump'); %title('bump vs ball');
subplot(2,4,6); scatter(fuk1, fuk3, 2, 'filled'); axis square; xlabel('ball'); ylabel('NO'); %title('bump vs NO');
subplot(2,4,7); scatter(fuk2, fuk3, 2, 'filled'); axis square; xlabel('bump'); ylabel('NO'); %title('ball vs NO');

[~, idx4] = sort(fuk3);
fuk1 = fuk1(idx4);
fuk2 = fuk2(idx4);
cmp = jet(length(idx4));
subplot(2,4,8); scatter(fuk1, fuk2, 2, cmp, 'filled'); axis square; xlabel('ball'); ylabel('bump'); title('NO is color')


% figure; scatter3(fuk1, fuk2, fuk3, 2, 'filled'); axis square
% xlabel('ball'); ylabel('bump'); zlabel('NO')