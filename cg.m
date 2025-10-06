


fn = 'REC_002008_100_00';
% fn = 'REC_003011_100_00';
% fn = 'REC_000504_100_00';
% fn = 'REC_004517_100_00';
%fn = 'REC_000004_100_00';
% fn='REC_001507_100_00';
%fn='REC_005020_100_00';
fn = 'REC_004517_100_00';
pth = '/Volumes/Elements/random/old_linear_fits/global_contrast/2107310/00';
[y, fs] = audioread([pth filesep fn '.mp4']);
smp = [170*fs,210*fs]; %51-72 245-270
smp = [110*fs,160*fs]; %51-72 245-270
% smp = [51*fs,72*fs]; %51-72 245-270
smp = [1,300*fs]; %51-72 245-270
% smp = [130*fs,150*fs]; %51-72 245-270
% smp = [240*fs,300*fs]; %51-72 245-270
% smp = [56.7*fs,57.2*fs]; %51 72 245-270
% smp = [1,270*fs];
[y, fs] = audioread([pth filesep fn '.mp4'], smp, 'native');
% figure; plot(y(:,1))
y = double(y);
% y = sgolayfilt(y, 3, 1201);
% y = smoothdata(y, 'sgolay', 501);
% y = rescale(y, -1, 1);
audiowrite([pth filesep fn '.mp3'],y,fs)
% sound(y, fs)

%{
205 left
220 read and roam
225 roam and out
235 out far


004
    2:42-2:47 start
    153 seesoon
    306 yeah
504
    45 rustle
    225-300 rf
    316 return
    415 tap
    454 tap
    458 2 sec vid?
1007
    208 tap
    242 tap
    402 vid
    422 spec
    440 spec
1507
    full taps utters throughout
    318 honey
2008
    13 mtv
    50 upgrade
    51-112 initial incident
    159 moo
    346 ooh
    455 cry
2511
    152 spech
    306-315 and 344-350 mon
    417 rustle
3011
    segs, esp 310, 331
3514
    329 rustle
    450 rustle
4015
    7-20 same rustle
    2-3 min check distant also around 410 and earlier (everywhere)
4517
    rustles until 145 vid
    209 beep
    335 ring
5020 
    31 beep
    314 beep
    450 rf higher
    

2:43 (2:42-2:47) start
indcident at 2120 in, so 304 (3:03-3:09), 51-111
indcident at 3428 in, so 317 (3:16-3:22), 403-422
me @ 4853 in, so 332 

try 2511 145-350
    306-315 and 344-350 mon
    
%}