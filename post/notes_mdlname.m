% notes on mdlname 

% mdlname syntax is [mdlclass][_details]
% where prefix mdlclass is general class of model, and suffix *_details are additional model details specific to the mdlclass 

% mdlclass 'svd' (mdlname has prefix 'svd') is for linear models fit to single-dimensional or multi-dimensional input (where dimensions can be features, or temporal offsets in a multi-timepoint model, or both)
%   for mdlclass svd, mdlname syntax is:
%       svd[_p], 
%       where suffix p denotes percentage of the data variance that linear fit should account for (pvar in objective_svd = p/100); 
%       for example 'svd_22' accounts for 22% of variance, i.e. in objective_svd pvar=0.22
%       note mdlname 'svd' is currently the only model that is not defined by mdl_fnet.m

% other than models in mdlclass 'svd', all models (structure, functions, parameters, constants, constraints) are defined by mdl_fnet.m
% see example section below for table output ('fnetspec') after parsing mdlname 
% mdl_fnet.m refers to a function network, similar to an ann, or cnn, but different in enough ways to deserve a different name 
% mdl_fnet.m creates a network of functions (or a single function), and a set of optional constraints for all free parameters; those parameters are optimized with matlab built-in global solver GlobalSearch (which repeatedly calls local solver fmincon)
% 
% the mdlname string provides a compact representation of the model, useful for saving data and making figures, and also avoids having conditional params defined here (ie only used for a given mdlname)
% the mdlname string syntax is designed to make model specification simple; the available characters were chosen so mdlname can appear in filenames on any platform without requiring escape characters
% mdlname string syntax is:
%   fnet_[ [position]_[unit]* ]*
    % position string syntax is:
    %   [layer][channel]
    % unit string syntax is:
    %   [combo syntax][unit multiplier][function]*
% 'position' refers to an incoming signal's position in the network, which matches the position of the upstream unit that output the signal; therefore, 'position' defines the signal operated on by function(s) specified by 'unit'
%   'position' string is comprised of substrings 'layer' and 'channel' (layer is vertical position, channel is horizontal position)
%   if the position string is omitted, and only the unit string appears, the model is a single position model (which can be a single unit character too)
%   'layer' is a capital letter; layers are in alphabetical order; input layer is 'A', first model functions (and their output signals), are in layer 'B', etc.
%       layers must appear in order across the mdlname string (for now, see note below about allowing recursion soon, for example))
%       position substring can only contain one layer (for now, see note below about allowing recursion soon, for example)
%       layer substring cannot be omitted
%   'channel' is a two-digit number (must use leading zero for 1-9); for layer 'A' (input layer), channel denotes input dimension; for layer 'B'-'Z', channel denotes previous layer's 'unit' index (corresponds to the index of that unit's output signal); e.g., number of units in layer B equals number of channels in layer C
%       channel can be omitted; omitting channel is equivalent to specifying all channels for the specified layer 
%       hyphen denotes a contiguous range of channels (increasing)
%       channels can appear in any order, but within a single position string, channels cannot be repeated (channels can be repeated in different position strings, e.g. to send the same channel to different channel sets, which in turn get sent to different units) 
%       all channels must be specified (i.e. channel set must match unit set from previous layer) 
%       channel refers to a signal, which can be multidimensional; channel does not refer to a dimension, except in layer A, where it refers to input dimension 
%           (for example, in layer B, if channel 1 is 3-dimensional, and channel 2 is 4-dimensional, a unit at position 'B1-2' (equivalent to writing 'B0102') operates on a 7 dimensional signal, created by concatenating channels 1 and 2, which are outputs of units 1 and 2 in layer A)
% 'unit' denotes a single function, or multiple functions operating in series 
    % 'unit' string can appear any number of times after the position string; each unit string separated by underscores (note: a single underscore-delimited unit substring can denote multiple units) 
    % 'unit' string is a set of function characters denoting functions that operate on incoming signal(s) specified by 'position';
    % for each position, units operate in parallel (within unit, functions operate in series)
    %   'combo syntax' is used if the unit string begins with the letter 'x'; 'combo syntax' means all 2-element combinations of specified linear and nonlinear functions are used at the specified position (one linear, followed by one nonlinear)
    %       in 'combo syntax', a function character cannot be repeated, but in regular syntax, function characters can be repeated (e.g. 'ggg' is a series of 3 gaussian functions)
    %       'combo syntax' lets a single unit string denote multiple units 
    %       'combo syntax' makes the order of function characters in the unit substring irrelevant; if not in 'combo syntax' the order corresponds to the function order in the unit 
    %       NOT YET AVAILABLE --> but in the future, hyphens in the 'unit' string will delimit char sets that get combined (allowing combinations of greater than 2 elements, and also removing the need for 'x' prefix, since the hyphen will denote the combination approach) <-- NOT YET AVAILABLE
    %   'unit multiplier' is used if the unit string begins with a number, q, after optional 'x'; with 'unit multiplier', the unit/units specified is/are repeated q times at the specified position; if the unit string is in 'combo-syntax' (leading 'x'), the 'unit multiplier', q, applies to the set of all combinations  
    %       'unit multiplier' lets a single unit string denote multiple units 
    %   after the optional leading 'x', and/or after the optional 'unit multiplier', q, the unit string is comprised of a sequence of function characters below
        % function characters denote linear and nonlinear functions:
            % linear functions (can be multiple timepoints):
                % s: is for 'sum', positive monophasic linear filter (summation/integration) (2 free params)
                % r: is for 'negative sum' (r precedes s), negative monophasic linear filter (summation/integration) (2 free params) 
                % d: is for 'difference', biphasic linear filter with positive lobe first (positive differentiation) (2 free params)
                % c: is for 'negative difference' (c precedes d), biphasic linear filter with negative lobe first (negative differentiation) (2 free params) 
                % f: is for 'free', unconstrained linear filter (param number matches number of incoming signal dimensions)
                % NOT YET AVAILABLE --> l: is for 'linear omit', no linear function; only useful when using 'combo syntax', and you want a missing linear function to be an element in one of the possible combinations (need to change this 'l', or 'l' for logistic, can't have duplicates) <-- NOT YET AVAILABLE
            % nonlinear functions (for now, all are instantaneous):
                % e: is for 'excitation', generalized logistic function (can be sigmoid) with positive slope (5 free params, 2 constants)
                % i: is for 'inhibition', generalized logistic function (can be sigmoid) with negative slope (5 free params, 2 constants)
                % l: is for 'logistic', generalized logistic function (can be sigmoid) with no slope constraint (5 free params, 2 constants)
                % v: is for 'vonmises'
                % g: is for 'gaussian'
                % h: is for 'one hot-encoding', a non-parametric nonlinearity
                %   h requires an additional integer suffix denoting number of bins (must be power of 2, for now); binning applies to the joint distribution of all dimensions of incoming signal (including time)
                % NOT YET AVAILABLE --> n: is for 'nonlinear omit', no nonlinear function; only useful when using 'combo syntax', and you want a missing nonlinear function to be an element in one of the possible combinations <-- NOT YET AVAILABLE
% in the entire fnet mdlname string, all numbers must be 2-digit (leading zero for 1-9) 
% see struct 'chopt' in default_fit_params for current list of characters and regex expressions for parsing the mdlname string;
% for simplicity, position substring can be omitted for single-unit, single-position models
%   for example, mdlname = 'fnet_g' fits a gaussian to the entire input signal
%   for example, mdlname = 'fnet_si' fits a linear filter followed by static nonlinearity to the entire input signal (in this case, the linear filter is a positive monophasic filter, and the nonlinearity is "inhibitory", ie a generalized logistic function with negative slope)
%   but even in these single-position, single-unit cases, the model is still defined as a "function network" using mdl_fnet.m 

% NOT YET AVAILABLE --> suffixes on function characters will denote timespan of domain in seconds, with 'p' denoting decimal <-- NOT YET AVAILABLE
% NOT YET AVAILABLE --> in future, mdlname string will not require layers to appear in order, which will allow more complex networks (recursion, skipping layers, etc.) <-- NOT YET AVAILABLE


%%%%EXAMPLE%%%%%

% you can run fitmdl_parse_mdlname_string (with arbitrary values below for num_dim_input and num_samples_model) 
% and inspect output table 'fnetspec' to see how single string modetype is transformed into a table representing a function network 
% chopt.fnet holds the charcters and expressions for parsing the string, and is copied from default_fit_params.m to run the example below  

% the example mdlname below is: 'fnet_A_x02sieh16g_B01-02_i_e_B03-08_svg' 
%   applies 1 unit substring ('x2sieh16g') to all channels of input (all channels since there is no channel substring for layer A); 
%   'x2sieh16g' begins with 'x', so uses 'combo syntax', and also has a 'unit multiplier' of 2 
%   since this unit substring uses combo syntax, 'sieh16g' is equivalent to : 'si_se_sh16_sg'; thus, it uses 4 units, each with 2 functions (one linear, one nonlinear), for all channels in layer A (input layer)
%   since there are 4 units in layer A, there are 4 channels in layer B 
%   B01-02_i_e means the following unit substrings 'i' and 'e' will be applied to channels 1 and 2 (output of units 1 and 2 in layer A); thus, two functions (inhibitory sigmoid, and excitatory sigmoid) are applied in parallel
%   B03-08_v means unit substring 'svg' is applied to channels 3-8 (output of units 3,4,5,6,7,8 in layer A); thus, a single series of 3 functions is applied (positive monophasic linear filter, then von mises, then gaussian)

clear all; close all; clc;

mdlname = 'fnet_A_x02sieh16g_B01-02_i_e_B03-08_svg';
num_dim_input = 2;
num_samples_model = 0;
multi_time_in_layer_one_only = 1;

%chopt holds the expressions for mdlname parsing with regexp  
chopt.fnet.lay = {'[A-Z]{1}'}; %layer is any single capital letter 
chopt.fnet.chan = {'^(0*\d{1,2})*(0*\d{1,2}-\d+)*$'}; %channel is zero or more two-digit numbers, with optional hyphens denoting ranges; no channel means all channels 
chopt.fnet.comb = {'x'}; %a single x
chopt.fnet.prefix = {'^x*0*\d*(?=\D)'}; %optional x followed by optional 2-digit number
chopt.fnet.unit = {'^x*\d*((\D)*(h\d+)*(\D)*)+$'}; %optional x followed by optional 2-digit number, followed by one or more non-numeric character or one-hot encoding substring; 
chopt.fnet.lin = {'s','r','d','c','f'}; %linear functions;
chopt.fnet.non = {'e','i','l','g','v'}; %nonlinear functions; 
chopt.fnet.hot = {'h\d+'}; %one-hot encoding function; h followed by one or more numeric characters

fnetspec = fitmdl_parse_mdlname_string(mdlname, chopt.fnet, num_dim_input, num_samples_model, multi_time_in_layer_one_only);

