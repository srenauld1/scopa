% +---------------------------------------------------------+
% | Ordering and Ranking of Data by Frequency of Occurrence |
% |               with MATLAB Implementation                | 
% |                                                         |
% | Author: Ph.D. Eng. Hristo Zhivomirov           08/12/21 |  
% +---------------------------------------------------------+
% 
% function: [r, f, v] = ordernrank(x)
%
% Input:
% x - data vector; 
% 
% Output:
% r - vector with ranks of the ordered frequencies of occurrence;
% f - vector with ordered frequencies of occurrence of the unique data values;
% v - vector with the unique data values ordered by the frequency of occurrence.
function [r, f, v] = ordernrank(x)
% represent x as column vector
x = x(:);
% find the unique data values
x_unq = unique(x);
% find the frequency of occurance of every unuque data value
x_cnt = histc(x, x_unq);
% order the unuque data values by frequency of occurrence
X = sortrows([x_cnt(:) x_unq(:)], 1, 'descend');
% form the function output
r = transpose(1:length(x_unq));
f = X(:, 1);
v = X(:, 2);
end