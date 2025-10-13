
clearvars; close all; clc

pth_gluno = '~/stacks/deblur/dad3ng.mat';
pth_glusi = '~/stacks/deblur/dad3g.mat';
load(pth_gluno, 'stack');
gluno = stack;
load(pth_glusi, 'stack');
glusi = stack;
stack = [];

v = sliceStack( gluno, ':,:,10', glusi );
% v = sliceStack( gluno, ':,64,:', glusi );
% v = sliceStack( gluno, '15,:,:', glusi );