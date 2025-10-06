



% clearvars
% clear ofill
% out = ofill();
% outrec = ofill(rec=1);

% clearvars
% clear ofill
% mos = 'bmp';
% out = ofill(mos);
% outrec = ofill(mos, rec=1);
% 
% clearvars
% clear ofill
% mos = 'bmp.mdl';
% out = ofill(mos);
% outrec = ofill(mos, rec=1);

% clearvars
% clear ofill
% optin.bmp.domtype = 'test1';
% optin.bmp.mdl.epochnum = 'test2';
% optin.bmp.mdl.opg.MaxTime = 'test3';
% out = ofill(optin);
% outrec = ofill(optin, rec=1);

clearvars
clear ofill
optin.bmp.domtype = 'test1';
optin.bmp.mdl.epochnum = 'test2';
optin.bmp.mdl.opg.MaxTime = 'test3';
optin.bmp.roi.mm.mmname = 'fuk';
mos = 'bmp.mdl';
out = ofill(optin, mos);
outrec = ofill(optin, mos, rec=1);