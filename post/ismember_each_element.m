function out = ismember_each_element(A, B)

% ismember(A, B) will not search exclusively individual elements of B independently, so this function does that 
% there are a few cases in this pipeline where regular ismember(A, B) differs from the output of this function   

if ~isvector(A)
    error("A must be vector") %this is to make clear the "single element at a time functionality"
end
if ~isvector(B)
    error("B must be vector") %this is to make clear the "single element at a time functionality"
end

out = zeros(size(A));
for i = 1:numel(B) 
    out = logical(out + ismember(A, B(i)));
end