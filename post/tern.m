% Code by David Ungarish.
function val = tern(cond, varargin)
% Ternary operation: An inline if/else and switch/case.
%
% If/else behavior (3 arguments):
%   tern(cond,a,b) returns: a if cond is true, else returns b.
%
% Switch/case behavior (>3 arguments):
%   tern(s,case1,value1,..,caseN,valueN,<defaultValue>), same as:
%
%   switch s
%       case case1
%           return value1
%           ..
%       case caseN:
%           return valueN
%       otherwise:
%           return defaultValue (default = NaN)
%
%
% EXAMPLES:
%
%   tern(v,'one',1,'two',2,'not 1 or 2!');
%       returns 1 if v is 'one', 2 if v is 'two', 'not 1 or 2!' otherwise.
%
%   tern(v,'True!','False!');
%       returns 'True!' if v is true, else 'False!'
% ----------------------------------------
% if/else behavior:
if length(varargin)==2
    val = varargin{int8(~cond)+1};
    return;
end
% ----------------------------------------
% switch/case behavior:
for i = 1 : 2 : length(varargin)
    if isequal(cond, varargin{i})
        val = varargin{i+1};
        return;
    end
end
% no match found -
if mod(length(varargin),2)==0
    % no default value given - return NaN
    val = NaN;
else
    % return default value
    val = varargin{end};
end
