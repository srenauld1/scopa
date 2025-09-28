function s1 = structflat(s,varargin)

% adapted by carl wienecke from flattenStruct by Uhlending, Markus
% fnex (now commented out) has field for each index in first dimension of each field in fn (with .indN appended to end, where N is index); commented out because it is slow for large arrays 

% a struct with nothing but empty structs, even if they are nested within other structs, returns empty flat struct (similar to how {{{}}} is empty  

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
    
    % Get all Unmatched parameters for sub fuctions
    varargin = namedargs2cell(p.Unmatched);
    if isfield(p.Unmatched, 'delim')
        delim = p.Unmatched.delim;
    else
        varargin{end+1} = 'delim';
        varargin{end+1} = '__';
        delim = '__';
        % fprintf("RUNNING STRUCTFLAT USING DEFAULT DELIM, DOUBLE UNDERSCORE, BECAUSE USER DIDN'T PASS NAME-VALUE ARGUMENT 'delim'; " + newline + "DOUBLE UNDERSCORE IS DEFAULT BECAUSE SINGLE UNDERSCORE IS COMMON IN VARIABLE NAMES, SO DOUBLE UNDERSCORE WILL DISTINGUISH NESTED STRUCTS FROM VARIABLES WITH SINGLE UNDERSCORE" + newline)
    end
    
    if numel(s)>1 && isempty(Prefix)
        error("for nonscalar struct input to structflat, you must also pass in prefix argument to make flattened fieldnames valid (this is a temporary solution)")
    end

    
    %% Get all fieldnames
    
    [~,tab] = fieldnamesAll(s,varargin{:});
    
    
    %% Create flatten struct
    
    if isempty(tab)
        s1 = struct();
    else
        s1 = convertStruct(s,tab,Prefix,delim);
    end

catch ME

    ME = MException('MATLAB:flattenStruct','%s',ME.message);
    throw(ME)

end

end



function out = convertStruct(s,tab,prefix,delim) %#ok<*INUSL>

% convert struct to table

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
        prefix = replace(prefix,'.',delim);
        prefix = matlab.lang.makeValidName(prefix,'Prefix','x');
    end
end


%% Prepare data

fn = tab.Field;
% no longer use varnm
% varnm = convertStringsToChars(regexprep(tab.Field, '^s.', prefix));
% if ischar(varnm) %in case it's just one varnm, will be char; put in cell to prevent error below
%     varnm = {varnm};
% end
varnmval = regexprep(tab.ValidVarName, ['^s' delim], prefix);

%% Create struct

nn = numel(fn);
% fnex = {}; %was cell(nn,1), but no longer use this because don't need it and can be very slow;
for k = 1:nn
    Value = eval(fn(k));
    VarName = varnmval(k);
    out.(VarName) = Value;

    % commenting out computing fnex, no longer use this because don't need it and can be very slow;
    % if size(Value,1)>1
    %     for tmpi = 1:size(Value,1)
    %         vntmp = {[varnm{k} '.ind' num2str(tmpi)]}; %append index if there are multiple (ie rois)
    %         fnex{k} = cat(1, fnex{k}, vntmp);
    %     end
    % else
    %     vntmp = {varnm{k}};
    %     fnex{k} = cat(1, fnex{k}, vntmp);
    % end
end

end
