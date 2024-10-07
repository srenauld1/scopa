function [s1, fn, fnex] = structflat(s,varargin)

% adapted from flattenStruct by Uhlending, Markus

% FLATTENSTRUCT Convert nested struct to flatten struct
% The function also works with array of structs and deeply nested structs.
%
% SYNTAX:
%   s1 = flattenStruct(s)
%   s1 = flattenStruct(___,varargin)
%
% INPUT:
%   s      = struct or array of structs
%
% OPTIONS:
%   Class  = Class filter, e.g. 'double' | 'char' | string | table | function_handle | '' default => no filter
%   Type   = Type filter, 'scalar' | 'nonscalar' | 'empty' | 'nonempty' | '' default => no filter
%   Depth  = Max Depth filter, positve integer 0 = no filter (default)
%   Prefix = Fieldname prefix ('' = default)
%
% OUTPUT:
%   s1 = Flatten struct
%
% EXAMPLE:
%   s1 = flattenStruct(s)
%   s1 = flattenStruct(s,'Prefix','myStruct')
%   s1 = flattenStruct(s,'Class',{'double','char'},'Type','scalar','Depth',0)
%
% CHANGELOG:
%   V1.00: First version
%
% INFO:
%   Copyright 06-2020, Uhlending, Markus
%   Matlab version   : Matlab 2020a
%   Function version : 1.00, 2020-06-08
%   Released under the BSD license.
%
% See also fieldnamesAll, matlab.lang.makeValidName, matlab.lang.makeUniqueStrings
try
    
    %% Check input
    p = inputParser;
    p.KeepUnmatched = 1;
    addRequired(p,'s',@(x)validateattributes(x,{'struct'},{},mfilename,'s',1))
    addParameter(p,'Prefix',"",@(x)validateattributes(x,{'char','string'},{},mfilename,'Prefix'));
    
    parse(p,s,varargin{:})
    s      = p.Results.s;
    Prefix = p.Results.Prefix;
    
    % --- Prepare Prefix --------------------------------------------------
    Prefix = unique(convertCharsToStrings(strtrim(Prefix)));
    Prefix(Prefix=="") = [];
    Prefix = convertStringsToChars(Prefix);
    
    % Get all Unmatched parameters fro sub fuctions
    varargin = namedargs2cell(p.Unmatched);
    
    %% Get all fieldnames
    [~,tab] = fieldnamesAll(s,varargin{:});
    
    %% Create flatten struct
    if isempty(tab)
        s1 = struct();
    else
        [s1,fn,fnex] = convertStruct(s,tab,Prefix);
    end
catch ME
    ME = MException('MATLAB:flattenStruct','%s',ME.message);
    throw(ME)
end
end
% --- convertStruct -------------------------------------------------------
function [out,varnm,fnex] = convertStruct(s,tab,prefix) %#ok<*INUSL>
% Function convert struct to table
%% Check inputs
if nargin<3 || isempty(prefix)
    prefix = '';
else
    prefix = char(prefix);
    prefix = strtrim(prefix);
    if isempty(prefix)
        prefix = '';
    else
        if ~endsWith(prefix,'.')
            prefix = [prefix,'.'];
        end
        
        prefix = strtrim(prefix);
        prefix = replace(prefix,'.','_');
        prefix = matlab.lang.makeValidName(prefix,'Prefix','x');
    end
end
%% Prepare data

fn = tab.Field;
varnm = convertStringsToChars(regexprep(tab.Field, '^s.', prefix)); 
varnmval = replace(tab.ValidVarName,'s_',prefix);

%% Create struct
nn = numel(fn);
fnex = cell(nn,1);
for ii = 1:nn
    Value = eval(fn(ii));
    if size(Value,1)>1
        for tmpi = 1:size(Value,1)
            vntmp = {[varnm{ii} '.ind' num2str(tmpi)]}; %append index if there are multiple (ie rois)
            fnex{ii} = cat(1, fnex{ii}, vntmp);
        end
    else
        vntmp = {varnm{ii}};
        fnex{ii} = cat(1, fnex{ii}, vntmp);
    end

    VarName = varnmval(ii);
    out.(VarName) = Value;
end
end
