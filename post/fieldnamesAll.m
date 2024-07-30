function [Fields,tab] = fieldnamesAll(s,varargin)
% FIELDNAMESALL returns all field names from a deeply nested array of "structs"
% This function is an improved version of MATLAB built-in function fieldnames
%
% SYNTAX:
%  [fields,tab] = fieldnamesAll(s)
%  [fields,tab] = fieldnamesAll(___,varargin)
%
% INPUT:
%   s = struct
%
% OPTIONS:
%   Class = Class filter, e.g. 'double' | 'char' | string | table | function_handle | '' default => no filter
%   Type  = Type filter, 'scalar' | 'nonscalar' | 'empty' | 'nonempty' | '' default => no filter
%   Depth = Max Depth filter, positve integer 0 = no filter (default)
%
% OUTPUT:
%   fields = String array of all field names
%   tab    = Additional information as table
%
% EXAMPLE:
%   [fields,tab] = fieldnamesAll(s)
%   [fields,tab] = fieldnamesAll(s,'Class',{'double'},'Type','scalar','Depth',2)
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
% See also getfield, extractAfter, replace, eval, whos, class
try
    %% Parse inputs
    try
        p = inputParser;
        addRequired(p,'s',@(x)validateattributes(x,{'struct'},{},mfilename,'s',1))
        addParameter(p,'Class',"",@(x)validateattributes(x,{'char','string','cell'},{},mfilename,'Class'))
        addParameter(p,'Type',"",@(x)validateattributes(x,{'char','string','cell'},{},mfilename,'Type'))
        addParameter(p,'Depth',0,@(x)validateattributes(x,{'numeric'},{'nonempty','nonnan','nonnegative','real','integer','finite','scalar'},mfilename,'Depth'))
        addParameter(p,'Prefix',"",@(x)validateattributes(x,{'char','string'},{},mfilename,'Prefix'));
        
        parse(p,s,varargin{:})
        s      = p.Results.s;
        Class  = p.Results.Class;
        Type   = p.Results.Type;
        Depth  = p.Results.Depth;
        
        %% Prepare inputs
        % --- Class -------------------------------------------------------
        Class = unique(convertCharsToStrings(strtrim(Class)));
        Class(Class=="") = [];
        Class = convertStringsToChars(Class);
        
        % --- Type --------------------------------------------------------
        Type = unique(convertCharsToStrings(strtrim(Type)));
        Type(Type=="") = [];
        for ii = 1:numel(Type)
            Type(ii) = validatestring(Type(ii),{'scalar','nonscalar','empty','nonempty'},mfilename,'Type');
        end
    catch ME
        error('MATLAB:fieldnamesAll:InvalidInput','Invalid input. %s',ME.getReport)
    end
    
    %% Set defaults
    root   = inputname(1);
    
    %% Get all fields for each struct
    [Fields0,Level] = getNames(s);
    if isempty(char(root))
        Fields = replace(Fields0,'s.','') ;
    else
        Fields = replace(Fields0,'s.',[char(root),'.']) ;
    end
    
    %% Create additional output (Additionally all "Locations" are tested if they exist in the input struct)
    % Create overiew table (Collect information about each variable)
    
    % Get names, class, size and dimension
    nn      = numel(Fields);
    Size    = nan(nn,2);
    Bytes   = nan(nn,1);
    Classes = strings(nn,1);
    Names   = strings(nn,1);
    
    for ii = 1:nn
        try
            % Evaluate variable
            tmp = eval(Fields0(ii)); % This command tests the expression "Location".
            
            % Get infos
            [Size(ii,1),Size(ii,2)] = size(tmp);
            Classes(ii) = class(tmp);
            info        = whos('tmp');
            Bytes(ii,1) = info.bytes;
            
            idx = strfind(Fields(ii),'.');
            if isempty(idx)
                Names(ii) = Fields(ii);
            else
                Names(ii) = extractAfter(Fields(ii),max(idx));
            end
        catch
            continue
        end
    end
    
    IsEmpty = Bytes==0;
    IsScalar = sum(Size,2)==2 | matches(Classes,'char');
    
    %% Create valid and unique VariableNames
    ValidVarName = replace(Fields0,'.','_');
    ValidVarName = replace(ValidVarName,{'(',')'},'_');
    ValidVarName = regexprep(ValidVarName,'_+','_');
    ValidVarName = matlab.lang.makeValidName(ValidVarName);
    ValidVarName = matlab.lang.makeUniqueStrings(ValidVarName);
    
    %% Filter fields
    nn = numel(Fields);
    
    % --- Class -----------------------------------------------------------
    if isempty(Class)
        idx1 = true(nn,1);
    else
        idx1 = contains(Classes,Class,'IgnoreCase',true);
    end
    
    % --- Type ------------------------------------------------------------
    if isempty(Type)
        idx2 = true(nn,1);
    else
        idx2 = false(nn,1);
        if any(matches(Type,'scalar'))
            idx2(IsScalar) = true;
        end
        
        if any(matches(Type,'nonscalar'))
            idx2(~IsScalar) = true;
        end
        
        if any(matches(Type,'empty'))
            idx2(IsEmpty) = true;
        end
        
        if any(matches(Type,'nonempty'))
            idx2(~IsEmpty) = true;
        end
    end
    
    % --- Depth -----------------------------------------------------------
    if Depth==0
        idx3 = true(nn,1);
    else
        idx3 = Level<=Depth;
    end
    
    %--- Create selection index -------------------------------------------
    idx = idx1 & idx2 & idx3;
    
    %% Define output
    if nargout<2
        Fields  = Fields(idx);
    else
        % Create table
        tab = table(Fields,ValidVarName,Names,Classes,Size,Bytes,Level,IsEmpty,IsScalar);
        
        % Apply selection filter
        Fields  = Fields(idx);
        tab = tab(idx,:);
        
        % Rename table VariableNames
        tab.Properties.VariableNames{'Fields'}  = 'Field';
        tab.Properties.VariableNames{'Classes'} = 'Class';
        tab.Properties.VariableNames{'Names'}   = 'Name';
        tab.Properties.VariableNames{'Level'}   = 'Depth';
        tab.Properties.RowNames = string(1:height(tab));
    end
catch ME
    if strcmpi(ME.identifier,'MATLAB:fieldnamesAll:InvalidInput')
        rethrow(ME)
    else
        ME = MException('MATLAB:fieldnamesAll','%s',ME.message);
        throw(ME)
    end
end
end
% --- getNames ------------------------------------------------------------
function [fnames,depth] = getNames(s,parName0,level)
%#ok<*GFLD>
%#ok<*AGROW>
% --- Check inputs --------------------------------------------------------
if nargin<2 || isempty(parName0)
    parName0 = inputname(1);
end
if nargin<3 ||  isempty(level)
    level = 1;
end
% --- Initialize values ---------------------------------------------------
fnames = {};
depth  = [];
% --- Get all fieldnames for this struct (array of structs possible) ------
ns    = numel(s);             	% Number of structs
for is = 1:ns                   % Loop over all structs
    si = s(is);                 % Current struct
    fi = string(fieldnames(s)); % Current fieldnames
    ni = numel(fi);             % Current number if fields (=> Number of variables)
    
    % ----------- Create parent name --------------------------------------
    if isempty(char(parName0))
        % Case inputname returns empty
        parName  = "";
    else
        if ns == 1
            % Case current struct is scalar struct
            parName = string(parName0);
        else
            % Case current struct is a array of struct
            parName = string(parName0) + "(" + num2str(is) + ")";
        end
    end
    
    % --- Sub loop over all fieldnames ------------------------------------
    for ii = 1:ni
        fn = fi(ii);            % Field Name
        fv = getfield(si,fn);   % Field Value
        fc = class(fv);        	% Field Class
        
        if matches(fc,'struct')
            % Field is a struct => Call this function again (recursive loop)
            
            % Get current field value
            fv  = getfield(si,fn);  % Field Value (sub-struct)
            
            % --- Get all fieldnames for this sub-struct  -----------------
            [tmpName,tmpDepth] = getNames(fv,fn,level+1);
            
            % Add Prefix to fieldnames
            if isempty(char(parName))
                % Case inputname returns empyt
                tmpName = string(fn);                               % Create fieldname
            else
                % Case input is a variable name
                tmpName = string(parName) + '.' +  string(tmpName); % Create fieldname
            end
            
            % Add all fieldnames to storage
            fnames = cat(1,fnames,tmpName);
            depth  = [depth;tmpDepth];
        else
            % Field is value => Final level is reached
            
            % Add Prefix
            if isempty(char(parName))
                % Case inputname returns empyt
                fn = string(fn);                                    % Create fieldname
            else
                % Case input is a variable name
                fn = string(parName) + '.' +  string(fn);           % Create fieldname
            end
            
            % Add all fieldnames to storage
            fnames = cat(1,fnames,fn);
            depth  = [depth;repelem(level,numel(fn),1)];
        end
    end
end
end