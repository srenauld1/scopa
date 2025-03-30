
% gald.tg.roi.rgname = 'gal';
% gald.tg.roi.mm.maskname = 'dorsal';
% gald.tg.vnm = 'ts';
%
% galv.tg.roi.rgname = 'gal';
% galv.tg.roi.mm.maskname = 'ventral';
% galv.tg.vnm = 'ts';
%
% gard.tg.roi.rgname = 'gar';
% gard.tg.roi.mm.maskname = 'dorsal';
% gard.tg.vnm = 'ts';
%
% garv.tg.roi.rgname = 'gar';
% garv.tg.roi.mm.maskname = 'ventral';
% garv.tg.vnm = 'ts';
%
% gald = tsget(gald);
% galv = tsget(galv);
% gard = tsget(gard);
% garv = tsget(garv);
%
% gald = cell2mat(gald{1});
% galv = cell2mat(galv{1});
% gard = cell2mat(gard{1});
% garv = cell2mat(garv{1});
%
% galdiff = gald-galv;


%%

epochtmp = 3;
btind = 2;
blen = 122;
te2 = find(daq.a2.epochts==epochtmp);
bst = find(diff(te2)~=1);
te3 = te2(bst(btind)); %one bout
% te2 = te3:te3+blen*2;
te2 = te3-blen*2:te3;
te2 = te2(1):4:te2(end);
te2 = 29150:3:29450
% te2 = [te2(1)-numel(te2):te2(end)];
figure; plot(roi.a2.ts{1}(te2)); hold on; yyaxis right; hold on; plot(ballvel(te2), '-r'); plot(bmpvel(te2), '-m')
% figure; plot(roi.a2.ts{1}(te2)); hold on; plot(roi.a3.ts{1}(te2)); yyaxis right; hold on; plot(ballvel(te2), 'c'); plot(bmpvel(te2), 'g')
% ha = area([4 6], [10 10]);
figure; imagesc(bmp.a1.respcl(:, te2));