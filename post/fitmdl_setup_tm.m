function setup_model_tm(x)

used to do this outside fit looop, and then after fit loop, like this indv = indv.';

x = x.';


mdl = @nonadaptive_tm;
lbnd = [0, 0, -inf(1,14)];
ubnd = [45, 360, inf(1,14)];
x0 = [10, 10, ones(1,14)];

vert_load_path = [filesep 'Users' filesep 'wienecke' filesep 'Documents' filesep 'GitHub' filesep 'flyMax' filesep 'indvGeneration' filesep]; %%path to folder containing vertices
filename_vertices = 'vertices_8000_0.txt';
pth = rdir([vert_load_path filename_vertices]);
phimx = 0.769961614088224; %image max phi
vert = dlmread( pth.name );
vert = vert(max(vert(:, 3),-1) >= cos(phimx), :); %crop vertices to be within indv cap, do after find_arc_length
vert = vert./vecnorm(vert,2, 2);  %normalize it to lie on the sphere!!
disp("WARNING, HARD CODED CROP TO num_dim_indvpre VERTICES")
vert = vert(1:num_dim_indvpre,:);
supp.vert = vert;

