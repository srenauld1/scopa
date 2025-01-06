function [medout,medind]=cmediandeg(in)
%
% function [medout<,medind>]=cmediandeg(in)
%
% compute circular median of a vector array of directions in 'in' given
% in deg (-180 to 180 or 0 to 360). The algorithms finds the input
% angle from in which has the smallest summed arc distance from the others. In
% the case of two identical angles computed as the median, first is returned.
% Optionally returns index of median angle in input array in as medind.
% 
% The circular median has several potential definitions and so is not unique.
% In this code the circular median is defined as the input angle which has
% the smallest summed absolute angular distance between it and all other input
% angles. The circular median D as used here is
%
% D = argmin Sum |distance_function(a_i,a_d)|.
%       d   i~=d
%

% written 22 Apr 2022 by D.Long at BYU

count=length(in);

if count<1
  medout=nan;
  return;
end
if count==1
  medout=input(1);
  return;
end

% brute force search for array with smallest sum of absolute value
% of angular arc distances
dif=zeros([1,count])+1e35;
for i=1:count
  if i>1
    ind=[1:(i-1),(i+1):count];   
  else
    ind=2:count;
  end
  dif(i)=sum((180-abs(180-abs(in(i)-in(ind)))));
end
[amin,index]=min(dif);
medout=in(index(1));

% set optional output index
if nargout>1
  medind=index(1);
end
return;

