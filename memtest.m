

clear all; 
close all; 
clc
profile off
profile -memory on
fool2 = rand(20,30,40);
fool = rand(400,900,2000,1,2);
roidat = roidatmake(fool, fool2);
profview
