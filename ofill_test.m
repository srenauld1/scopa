

% compare all test cases rec=0 and rec=1

% no mos, no optin
clearvars
clear ofill
out = ofill();
outrec = ofill(rec=1);

%unnested mos, no optin
clearvars
clear ofill
mos = 'bmp';
out = ofill(mos);
outrec = ofill(mos, rec=1);

%nested mos, no optin
clearvars
clear ofill
mos = 'bmp.mdl';
out = ofill(mos, unpack=1);
outrec = ofill(mos, rec=1, unpack=1);

%no mos, nested optin
clearvars
clear ofill
optin.bmp.domtype = 'test1';
optin.bmp.mdl.epochnum = 'test2';
optin.bmp.mdl.opg.MaxTime = 'test3';
out = ofill(optin);
outrec = ofill(optin, rec=1);

%nested mos in optin and mos not in optin
clearvars
clear ofill
optin.bmp.domtype = 'test1';
optin.bmp.mdl.epochnum = 'test2';
optin.bmp.mdl.opg.MaxTime = 'test3';
optin.bmp.roi.mm.mmname = 'fuk';
mos = {'bmp.mdl', 'mdl'};
out = ofill(optin, mos);
outrec = ofill(optin, mos, rec=1);