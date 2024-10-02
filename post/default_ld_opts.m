function parsout = default_ld_opts(parsin)

if ~exist('parsin', 'var') | isempty(parsin)
    parsin = struct;
end
crop_flyback = 1; %crop flyback frames from each volume
zero_stack = 1; %subtract min to make min zero
tcropfront = 0; %how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
tcropback = 0; % how many samples to remove from end of stack
do_plot_stack_stats = 0; %function this uses is old and needs to be updated

update_param_struct; %call this script to overwrite any default params above with fields in parsin, and organize into parsout 
