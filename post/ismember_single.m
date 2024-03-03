function out = ismember_single(A, B)

% need for this is frequent enough in this pipeline to justify a function
% ismember(A, B) will not search only individual elements of B, so this function does that 
% there are a few cases in this pipeline where regular ismember(A, B) differs from the output of this function   

if ~isvector(A)
    error("B must be vector") %this is to make clear the "single element at a time functionality"
end
if ~isvector(B)
    error("B must be vector") %this is to make clear the "single element at a time functionality"
end

out = zeros(size(A));
for i = 1:numel(B) 
    out = logical(out + ismember(A, B(i)));
end