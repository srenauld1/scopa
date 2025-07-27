
% glue window deblurring script 
% '20250713_2_1_rd_.mat' with glue window
% '20250713_2_2_rd_.mat' without glue window

pthstackdir = '/Users/wienecke/stacks/ganoeb/20250713-2_d05_s8m_018_s8m/'; %path to stack directory 
fn = '20250713_2_2_rd_.mat'; %filename of stack
it = 100:3:150; %frames to plot; -x will plot x equidistant frames across all t
rot = [-90,0,0]; %Euler angles in x,y,z-order in degrees, specified as a 3-element numeric vector of the form [rx ry rz]
widyxz = [1.5899 1.5899 2.8000]; %don't change this; voxel width in yxz

pthstack = [pthstackdir fn];
clear glb %clear globals in glb
glb(pthstackdir=pthstackdir)
load(pthstack, 'stack') %load yxzt stack
stackplt(stack, it=it) %plot stack, it specifies frames to plot
stackmnt = mean(stack,4); %average all frames
stackrot = stackwarp(stackmnt, rot=rot); %rotate stack (can also translate with name-value argument trans)
stackplt(stackrot) %plot rotated stack
stackdbed = stackdb(stackmnt, widyxz=widyxz, doplt=0); %deblur stackmnt; doplt=1 to plot within stackdb
stackplt(stackdbed) %plot rotated stack
