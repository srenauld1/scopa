% VChooseKR - Combinations of K elements (repetitions) [MEX]
% VChooseKR(V, K) creates a matrix, which rows are all combinations of
% choosing K elements of the vector V without order and with repetitions.
%
% INPUT:
%   V: Array of class DOUBLE, SINGLE, (U)INT8/16/32/64, LOGICAL, CHAR.
%      V can have any shape.
%   K: Number of elements to choose. Scalar DOUBLE with integer value K >= 0.
%
% OUTPUT:
%   Y: Matrix of size (N+K-1 over K) with N is the number of elements of V.
%      Y has the same class as the input V.
%      A warning appears, if the output exceeds 500MB, and an error for 1GB.
%      Both limits can be adjusted according to the available RAM in the
%      C-Mex source.
%
% EXAMPLES:
%   Choose 2 elements from [1,2,3,4]:
%     VChooseKR(1:4, 2)
%     ==> [1,1; 1,2; 1,3; 1,4; 2,2; 2,3; 2,4; 3,3; 3,4; 4,4]
%   For speed cast the input to integer types if possible:
%     Y = double(VChooseKR(int16(1:1000), 2));
%   is faster than:
%     Y = VChooseKR(1:1000, 2);
%   To get the combinations of cell arrays, use the combinations of the index:
%     C  = {'a', 'b', 'c', 'd'};
%     C2 = C(VChooseKR(1:4, 2))
%     ==> C2 = {'a','a'; 'a','b'; 'a','c'; 'a','d'; 'b','b'; 'b','c'; ...
%               'b','d'; 'c','c'; 'c','d'; 'd','d'}
%
% MORE HELP:
%   See VChooseKR.c
%
% Tested: Matlab 6.5, 7.7, 7.8, WinXP, [UnitTest]
%         Compilers: BCC5.5, LCC2.4/3.8, Open Watcom 1.8
% Author: Jan Simon, Heidelberg, (C) 2009-2010 matlab.THISYEAR(a)nMINUSsimonDOTde
% License: BSD (use/copy/modify on own risk, but mention author)
%
% See also: NCHOOSEK, PERMS, PERMUTE.
% This is a dummy file to support the help command.
% The unit-test function TestVChooseK contains a Matlab implementation of the
% used algorithm.
