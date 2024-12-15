function eqFlag = isequaltol(A, B, tol, eqNaN, onlyNum, chkInput)
% isequaltol(A, B, tol, eqnan, onlynum)
%
% Like the MATLAB built-in functions "isequal" and "isequaln" this function is
% used to determine if two variables A and B are equal. But here two floating
% point numbers are considered equal if the difference is less than a set
% tolerance.
%
% INPUT:
% A, B    - any type of MATLAB arrays.
% tol     - an optional tolerance used to determine if two floating point
%           numbers are considered equal. Can be scalar with the tolerance for
%           double precision numbers (default 1e-6 used for single precision) or
%           a two-element vector with tolerances for single and double precision
%           numbers. If not supplied set to [1e-6, 1e-12].
% eqnan   - an optional logical flag indicating if NaN are considered equal. If
%           not supplied set to true.
% onlynum - an optional logical flag indicating if non-numerical data, such as
%           strings, can be different. If not supplied set to false. 
%
% OUTPUT:
% Returns a logical that is set to true if A and B are equal within the given
% tolerances and false otherwise.
%
% NOTE:
% The program recursively checks cell and structure arrays and might be slow if
% they are very large.
%
% EXAMPLES:
% clear
% isequal(1, 1+eps)
% isequaltol(1, 1+eps)
% A = rand(100, 100);
% B = log10(10.^A);
% isequal(A, B)
% isequaltol(A, B)
% C.data = {sparse(A(A < 0.5) + 1i*A(A < 0.5))};
% D.data = {sparse(B(B < 0.5) + 1i*B(B < 0.5))};
% isequal(C, D)
% isequaltol(C, D)
%
% Author      : Patrik Forssén, Karlstad University
% Release     : 1.2
% Release date: Feb 2023
%
% See also isequal, isequaln, ismembertol.
% VERSION HISTORY
% 1.0.0 First release
% 1.0.1 Fixed skip non-numeric test
% 1.1.0 Fixed numeric test and added support for tables
% 1.1.1 Corrected for column and row vectors with same number of elements
% 1.2   Fixed numeric test
 
% Default input
if (nargin < 3 || isempty(tol))     , tol      = [1e-6, 1e-12]; end
if (nargin < 4 || isempty(eqNaN))   , eqNaN    = true         ; end
if (nargin < 5 || isempty(onlyNum)) , onlyNum  = false        ; end
% For internal use!
if (nargin < 6 || isempty(chkInput)), chkInput = true         ; end
 
% Check inputs (only has to be done once!)
if (chkInput)
  % tol
  if (~isvector(tol)  || ~isnumeric(tol) || ~isreal(tol) || ...
      length(tol) < 1 || length(tol) > 2 || min(tol) <= 0)
    error('isequaltol:ToleranceIncorrect', ['The input tolerance must be ', ...
      'a real scalar or a two-element vector > 0']) 
  end
  % Use default for single precision?
  if (length(tol) == 1), tol = [1e-6, tol]; end
  
  % eqNaN
  if (~isscalar(eqNaN) || (~isequal(eqNaN, false) && ~isequal(eqNaN, true)))
    error('isequaltol:EqualNaNIncorrect', ['The input equal NaN flag ', ...
      'must be a scalar logical or 0/1'])
  end
  
  % onlyNum
  if (~isscalar(onlyNum) || (~isequal(onlyNum, false) && ...
      ~isequal(onlyNum, true)))
    error('isequaltol:OnlyNumericIncorrect', ['The input only numeric ', ...
      'data flag must be a scalar logical or 0/1'])
  end
end
  
% Both numeric/logical arrays?
if ((isnumeric(A) || islogical(A)) && (isnumeric(B) || islogical(B)))
  if (isfloat(A) || isfloat(B))
    % Make sure both are floating point arrays
    if (~isfloat(A)), A = cast(A, class(B)); end
    if (~isfloat(B)), B = cast(B, class(A)); end
    % Check if they are equal with tolerance
    eqFlag = eqFloatTol(A, B, tol, eqNaN);
  else
    % Let "isequal" or "isequaln" handle it
    if (~eqNaN)
      eqFlag = isequal( A, B);
    else
      eqFlag = isequaln(A, B);
    end
  end
  return
end
% Convert tables to cell arrays
if (istable(A)), A = table2cell(A); end
if (istable(B)), B = table2cell(B); end
 
% Both cell arrays?
if (iscell(A) && iscell(B))
  % Check if dimensions match
  if (~isequal(size(A), size(B)))
    % Row and column vectors with the same number of elements should be checked
    if (~(isvector(A) && isvector(B) && numel(A) == numel(B)))
      eqFlag = false;
      return
    end
  end
  % Must check elements recursively
  eqFlag = true;
  for elemNo = 1 : numel(A)
    eqFlag = isequaltol(A{elemNo}, B{elemNo}, tol, eqNaN, onlyNum, false);
    if (~eqFlag), return, end
  end
  return
end
 
% Both struct arrays?
if (isstruct(A) && isstruct(B))
  % Check if dimensions match
  if (~isequal(size(A), size(B)))
    eqFlag = false;
    return
  end
  % Check if fieldnames match
  AFields = fieldnames(A);
  BFields = fieldnames(B);
  if (~isempty(setxor(AFields, BFields)))
    eqFlag = false;
    return
  end
  % Must check fields recursively
  eqFlag = true;
  for elemNo = 1 : numel(A)
    for fieldNo = 1 : length(AFields)
      ATmp   = A(elemNo).(AFields{fieldNo});
      BTmp   = B(elemNo).(AFields{fieldNo});
      eqFlag = isequaltol(ATmp, BTmp, tol, eqNaN, onlyNum, false);
      if (~eqFlag), return, end
    end
  end
  return
end
 
% Check also non-numeric data?
if (~onlyNum)
  % Let "isequal" or "isequaln" handle it!
  if (~eqNaN)
    eqFlag = isequal( A, B);
  else
    eqFlag = isequaln(A, B);
  end
else
  if (iscell(A) || isstruct(A) || isnumeric(A) || islogical(A) || ...
      iscell(B) || isstruct(B) || isnumeric(B) || islogical(B))
    % Not both are non-numeric data items
    eqFlag = false;
  else
    eqFlag = true;
  end
end
 
end
 
 
 
function eqFlag = eqFloatTol(A, B, tol, eqNaN)
 
% Check if dimensions match
if (~isequal(size(A), size(B)))
  % Row and column vectors with the same number of elements should be checked
  if (~(isvector(A) && isvector(B) && numel(A) == numel(B)))
    eqFlag = false;
    return
  end
end
 
% Sparse matrices?
if (issparse(A) && issparse(B))
  % Check if number of nonzero elements is the same
  if (~isequal(nnz(A), nnz(B)))
    eqFlag = false;
    return
  end
  % Check that the locations of nonzero elements are the same
  ALinInd = find(A);
  BLinInd = find(B);
  if (~isequal(ALinInd, BLinInd))
    eqFlag = false;
    return
  end
  % Convert to full vectors
  A = full(A(ALinInd));
  B = full(A(ALinInd));
elseif (issparse(A))
  A = full(A);
elseif (issparse(B))
  B = full(B);
end
 
% Convert to vectors
A = A(:);
B = B(:);
 
% NaN equal?
A(isnan(A))   = 0;
if (eqNaN)
  B(isnan(B)) = 0;
else
  B(isnan(B)) = 1;
end
 
% Single or double precision?
currTol = tol(2);
if (isa(A, 'single') || isa(B, 'single')), currTol = tol(1); end
 
% Check
if (~isreal(A) || ~isreal(B))
  % Check real and imaginary parts
  eqFlag = all(abs(real(A) - real(B)) <= currTol);
  if (~eqFlag), return, end
  eqFlag = all(abs(imag(A) - imag(B)) <= currTol);
else
  eqFlag = all(abs(A - B) <= currTol);
end
 
end