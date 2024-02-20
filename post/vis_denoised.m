

close all
clear all
clc

indies = 1:50;
indies = 100:150%2000:2200;

gif_visibility = 'on';

filepath_super = '~/Documents/ambrose/';

fnall = rdir([filepath_super 'denoise_testing/*e*.tif']);
%fnall = rdir([filepath_super 'denoise_testing/221120_0_1_1_5869_128_256_uint16__E_01_Iter_13140_output.tif']);
fnall = natsortfiles(fnall);

%databig = zeros(140, 256, 15, 3047, 'uint16');
zindie = 1;
for ri = 1:length(fnall)

    fntmp = fnall(ri).name
    sz = [140 256 15 3047];
    sz = [50 256 8 5760];
    sz = [50 256 1 300];
    %sz = [128 256 1 5869];
    out_datatype = "uint16"%"uint16";
    size_z_read_from = sz(3);
    size_t_read_from = sz(4);
    inds_z_read_from = zindie%1:size_z_read_from;
    inds_t_read_from = 1:size_t_read_from;
    size_read_to = [length(inds_t_read_from), length(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed
    data = read_tif_tzyx(fntmp, ...
        out_datatype, size_read_to, ...
        size_z_read_from, size_t_read_from, ...
        inds_z_read_from, inds_t_read_from);

    mindat = min(data(:));
    maxdat = max(data(:));
        
    %databig(:,:,ri,:) = uint16(data);

    data = data - mindat;
    %data = rescale(data, 0, 1);

    % data = rescale(data, 0, 6);
    % plot_gif(data(:,:,1,indies), [fntmp(1:end-4) num2str(round(mindat)) '_' num2str(round(maxdat)) '_rescale_.gif'], 256)
    %

    plot_gif(rescale(data(:,:,1,indies)), [fntmp(1:end-4) '_' num2str(round(mindat)) '_' num2str(round(maxdat)) '_' num2str(zindie) '_.gif'], 256 )
    %plot_gif(rescale(data(:,:,1,indies), 0, 6), [fntmp(1:end-4) '_' num2str(round(mindat)) '_' num2str(round(maxdat)) '_' num2str(zindie)  'rescale_.gif'], 256)
    % 
    % 
    % plot_gif(rescale(data(:,:,4,indies)), [fntmp(1:end-4) num2str(round(mindat)) '_' num2str(round(maxdat)) '4_.gif'], 256)
    % plot_gif(rescale(data(:,:,4,indies), 0, 6), [fntmp(1:end-4) num2str(round(mindat)) '_' num2str(round(maxdat)) '4rescale_.gif'], 256)
    % 
    % plot_gif(rescale(data(:,:,14,indies)), [fntmp(1:end-4) num2str(round(mindat)) '_' num2str(round(maxdat)) '14_.gif'], 256)
    % plot_gif(rescale(data(:,:,14,indies), 0, 6), [fntmp(1:end-4) num2str(round(mindat)) '_' num2str(round(maxdat)) '14rescale_.gif'], 256)
    % 

end

% databig = databig - min(databig(:));
% databig = rescale(databig);
% datameanz = squeeze(mean(databig, 3));
% plot_gif(datameanz(:,:,indies), [fntmp(1:end-4) 'meanz_.gif'], 256)
% plot_gif(rescale(datameanz(:,:,indies), 0, 4), [fntmp(1:end-4) 'meanz_rescale_.gif'], 256)
% datameant = mean(databig, 4);
% plot_gif(datameant, [fntmp(1:end-4) 'meant_.gif'], 256)
% plot_gif(rescale(datameant, 0, 4), [fntmp(1:end-4) 'meant_rescale_.gif'], 256)

