function result = weighted_circular_mean(ang, W, sens)
%
% function result = weighted_circular_mean(ang, weights <,sens>)
%
% return the weighted circular mean of a vector input angles ang (in deg) with
% the output in the range [0..360) using Kogan's algorithm [1] for computing
% the true circular mean. This differs from the conventional angle vector mean
% method that uses the arctangent of the mean sine and cosine of the angles.
% https://www.mers.byu.edu/circularmean.html 
%
% Note: result is usually a scalar, but under unusual circumstances when
% the mean is not well-defined, e.g., ang=[0,180] or ang=[0,90,180,270],
% the result can be a vector, see [1].
%
% Theory and references: see circular_mean.m and description.txt

% Uses matlab's sort function

% Translated by D.Long 31 Jul 2023 from Kogan's elegant 2013 C++11 to 
% less elegant and efficient Matlab while retaining enough structure 
% to use Kogan's form and commentary 

%ExactOrAlmostEqual_sens=1.e-12; % default sensitivity for "almost equals"
ExactOrAlmostEqual_sens=0;       % used exact equals

if nargin < 1
  result=nan;
  return;
end

% check for input weight array
if nargin < 2
  W=ones(size(ang(:)'));
end

% check for optional input argument
if nargin > 2
  ExactOrAlmostEqual_sens=sens; % sensitivity input
end

% convert all input angles to the range [0..360) and make a column vector
ang=local_anglerange0to360(ang(:)');
Asize=length(ang); % number angles

% only single input
if Asize==1
  result=ang;
  return;
end


% separate input list into lower and upper angle lists
fASumW=0;
fASumWA=0;
fASumWA2=0;
LowerAngles=[]; LowerAnglesW=[]; 
UpperAngles=[]; UpperAnglesW=[];
for k=1:length(ang)
  v=ang(k);
  w=W(k);
  fASumW=fASumW+w;
  fASumWA=fASumWA+w*v;
  fASumWA2=fASumWA2+w*v*v;
  if v<180
    LowerAngles=[LowerAngles v];
    LowerAnglesW=[LowerAnglesW w];
  else 
    UpperAngles=[UpperAngles v];
    UpperAnglesW=[UpperAnglesW w];
  end
end

% sort lists
[LowerAngles,ind]=sort(LowerAngles,'ascend' ); % ascending order [0..180)
LowerAnglesW=LowerAnglesW(ind);
[UpperAngles,ind]=sort(UpperAngles,'descend'); % descending order (360..180)
UpperAnglesW=UpperAnglesW(ind);

% see [1]. Computation is over upper and lower subsets and sectors
% set initial values and compute averages over sectors
MinAvrgVals=180;
fMinSumSqrDiff=WSumSqr(fASumW, fASumWA, fASumWA2);

% average in (180..360) for set D: values in range [0,avrg-180)
fLowerBound=0;
fDSumW=0;
fDSumWD=0;

iter=0;
for d=0:length(LowerAngles)-1
  fTestAvrg = (fASumWA+360*fDSumW)/fASumW;
  if fTestAvrg > fLowerBound+180 & fTestAvrg <= LowerAngles(iter+1)+180
    SumSqrDval = WSumSqrD(fTestAvrg, fDSumW, fDSumWD, fASumW, fASumWA, fASumWA2);
    [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrDval,ExactOrAlmostEqual_sens);
  end
  fLowerBound = LowerAngles(iter+1);
  fDSumW = fDSumW + LowerAnglesW(iter+1);
  fDSumWD = fDSumWD + LowerAnglesW(iter+1) * LowerAngles(iter+1);
  iter = iter + 1;
end

fTestAvrg=(fASumWA+360*fDSumW)/fASumW;
if fTestAvrg < 360 & fTestAvrg > fLowerBound
  SumSqrDval = WSumSqrD(fTestAvrg, fDSumW, fDSumWD, fASumW, fASumWA, fASumWA2);
  [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrDval,ExactOrAlmostEqual_sens);
end

% average in [0..180) for set C: values in range (avrg+180,360)
fUpperBound=360;
fCSumW=0;
fCSumWC=0;

iter=0;
for c=0:length(UpperAngles)-1
  fTestAvrg=(fASumWA - 360*fCSumW)/fASumW;
  if fTestAvrg >= UpperAngles(iter+1)-180 & fTestAvrg < fUpperBound-180
    SumSqrCval = WSumSqrC(fTestAvrg, fCSumW, fCSumWC, fASumW, fASumWA, fASumWA2);
    [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrCval,ExactOrAlmostEqual_sens);
  end
  fUpperBound = UpperAngles(iter+1);
  fCSumW = fCSumW + UpperAnglesW(iter+1);
  fCSumWC = fCSumWC + UpperAnglesW(iter+1) * UpperAngles(iter+1);
  iter = iter + 1;
end

fTestAvrg=(fASumWA-360*fCSumW)/fASumW;
if fTestAvrg>=0 & fTestAvrg < fUpperBound
  SumSqrCval = WSumSqrC(fTestAvrg, fCSumW, fCSumWC, fASumW, fASumWA, fASumWA2);
  [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrCval,ExactOrAlmostEqual_sens);
end  

% return result (note: result is usually a scalar, but can be a set when
%                the mean angle is not well-defined)
result=MinAvrgVals;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kogan's lambda support functions converted to explicit functions
% with the full set of input/outputs included
%
function out=local_anglerange0to360(input)
%
% return angle values of input in deg within range [0..360)
%
out=input;
ind=find(out<0 | out>=360);
out(ind)=mod(out(ind),360);
end

function out=WSumSqr(fASumW, fASumWA, fASumWA2)
%
% function out=WSumSqr(fASumW, fASumWA, fASumWA2)
% 
% returns Kogan's weighted SumSqr function value
out=32400*fASumW-360*fASumWA+fASumWA2;
end

function out=WSumSqrC(x, fCSumW, fCSumWC, fASumW, fASumWA, fASumWA2)
%
% function out=WSumSqrC(x, fCSumW, fCSumWC, fASumW, fASumWA, fASumWA2)
% 
% returns Kogan's weighted SumSqrC function value with all args specified
out=fASumWA2+x^2*fASumW-2*x*fASumWA-720*fCSumWC+(129600+720*x)*fCSumW;
end

function out=WSumSqrD(x, fDSumW, fDSumWD, fASumW, fASumWA, fASumWA2)
%
% function out=WSumSqrD(x, fDSumW, fDSumWD, fASumW, fASumWA, fASumWA2)
% 
% returns Kogan's weighted SumSqrD function value with all args specified
out=fASumWA2 + x^2*fASumW - 2*x*fASumWA + 720*fDSumWD + (129600-720*x)*fDSumW;
end

function out=local_anglediffdeg(in1,in2)
%
% out=local_anglediffdeg(in1,in2)
%
% computes the absolute value of the minimum difference of two angles in deg
out=180-abs(180-abs(mod(in1-in2,360)));
end 

function out=local_AlmostEqualAngleDeg(in1,in2)
%
% out=local_AlmostEqualAngleDeg(in1,in2)
%
% returns 1 if scalar angles in1 and in2 (in deg) are "almost equal" (see [1])
% otherwise returns 0
sens=1.e-12; % default sensitivity value
if abs(local_anglediffdeg(in1,in2)) < sens
  out=1;
else
  out=0;
end 
end

function [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals_in,fMinSumSqrDiff_in,fTestAvrg,fTestSumDiffSqr,ExactOrAlmostEqual_sens);
%
% [MinArgVals,fTestSumSqrDiff]=TestCirSum(MinArgVals,fMinSumSqrDiff,...
%                                         fTestAvrg,fTestSumDiffSqr,...
%                                         ExactOrAlmostEqual_sens);
%
% implements Kogan's TestSum lambda function as explicit function with
% full set of input/output args. Optionally uses Kogan's "almost equal" idea 
% for the equality test if ExactOrAlmostEqual_sens>0

sens=1.e-12; % default sensitivity

if ExactOrAlmostEqual_sens==0  % use exact equal test
  teqflag = (fTestSumDiffSqr == fMinSumSqrDiff_in);
else % use "almost equal" test, see [1]
  teqflag = local_AlmostEqualAngleDeg(fTestSumDiffSqr,fMinSumSqrDiff_in)
end
if teqflag % equal case--produces multiple solutions
  MinAvrgVals = [MinAvrgVals_in local_anglerange0to360(fTestAvrg)];
  fMinSumSqrDiff = fMinSumSqrDiff_in;
else
  if fTestSumDiffSqr < fMinSumSqrDiff_in
    MinAvrgVals = local_anglerange0to360(fTestAvrg);
    fMinSumSqrDiff = fTestSumDiffSqr;
  else
    MinAvrgVals = MinAvrgVals_in;
    fMinSumSqrDiff = fMinSumSqrDiff_in;
  end
end
end