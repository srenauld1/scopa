
clearvars; close all; clc

pth_gluno = '~/stacks/deblur/dad3ng.mat';
pth_glusi = '~/stacks/deblur/dad3g.mat';
load(pth_gluno, 'stack');
gluno = stack;
load(pth_glusi, 'stack');
glusi = stack;
stack = [];

stackplt({gluno, glusi}, it = 100:4:400, pthdir=pthparget)

v = sliceStack( gluno, ':,:,10', glusi, pthparget );
v = sliceStack( gluno, ':,64,:', glusi, pthparget );
v = sliceStack( gluno, '15,:,:', glusi, pthparget );