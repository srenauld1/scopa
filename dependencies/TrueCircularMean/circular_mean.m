function result = circular_mean(ang, sens)
% 
% function result = circular_mean(ang <,sens>)
% 
% return the circular mean of a vector input angles ang (in deg) with the
% output in the range [0..360) using Kogan's algorithm [1] for computing the 
% true circular mean. This differs from the conventional angle vector mean
% method that uses the arctangent of the mean sine and cosine of the angles.
% https://www.mers.byu.edu/circularmean.html 
% 
% Note: result is usually a scalar, but under unusual circumstances when
% the mean is not well-defined, e.g., ang=[0,180] or ang=[0,90,180,270],
% the result can be a vector, see [1].
% 
% Theory:
% 
% 
% When computing the mean of angles the conventional approach is to take
% the arctangent of the mean sine and cosine of the angles. However, this
% is not true circular mean.  Consider:
% 
% The mean M of a discrete set a={a_i} is formally defined as 
% 
%  M = argmin Sum distance_function(a_i,m)                 (1)
%        m     i
% 
% where the distance_function(a_i,m) is some metric appropriate to the set.
% 
% For a linear mean, the one we are used to for linear values, the distance
% function is given by distance_function(a_i,m)=abs(a_i-m). However, for the
% conventional method commonly used for computing an average angle, i.e.,
% the arctangent of the mean of the sine and cosine of the angles, it can
% be shown that the distance function is actually given by
% 
%    (conventional) distance_function(a_i,m)=1-cos(a_i-m),
% 
% which is quite different than a linear mean.
% 
% To solve for the mean using Eq. (1), we take the derivative and set it to
% zero. The conventional method has the advantage of being easily 
% differentiable. The average angle distance metric (1-cos(a_i-m)) yields 
% the conventional formula for an "average angle" Ma given by:
% 
%  Ma = atan2(sum(sin(a*pi/180)), sum(cos(a*pi/180))) -equivalent to-
%  Ma = atan2(mean(sin(a*pi/180)), mean(cos(a*pi/180))) -or-
%  Ma = angle(exp(j*a*pi/180)) (in Matlab)
%
% This works where the arctangent of its input arguments are defined. Note
% that it involves transcendential functions and that the distance function is 
% related to the cosine of the angle difference. Further, when using circular
% sets such day of year, the value (which might be an integer) has to be
% converted to the range [0..2*pi), which involves the irrational number pi.
% 
% However, when considering the difference between two angles, the distance
% function can be better defined as what might called the minimum arc distance,
% i.e., the minimum of the two possible angles or arcs between the two angles.
% That is, the minimum angle moving clockwise or counterclockwise from
% one angle to the other.  This minimum arc distance is between 0 and 180 deg.
% This is the linear distance as defined on a circular set. Computationally,
% this is the minimum of abs(a_i-m), abs(a_i-m-360), and abs(a_i-m+360), which
% can be written succintly as
% 
%   distance_function(a_i,m)=180-abs(180-abs(mod(a_i-m,360))). (2)
% 
% where mod(x,y) is defined as in Matlab. Note: the signed (+CCW vs -CW)
% distance_function for two angles a_i and m can be written as
% 
%    distance_function(a_i,m)=mod(m-a_i+180,360)-180       (3)
% 
% Eq. (2) appears hard to differentiate. However, by dividing the modulo and
% absolute value functions into sets, the derivative of the distance function
% can be determined [1], which can be used to solve Eq. (1) for the true 
% circular mean. This is computationally a little complicated since it 
% requires sorting parts of the data, but it involves no transcendential 
% functions.  Further, Kogan's implementation [1] avoids the angle sampling 
% limitations required by Matsuti's method [2]. Computation in degrees avoids 
% irrational numbers such as pi and so is well-suited for other circular data
% sets. Note that Kogan's method is not a "single-pass" algorithm [2,3], i.e.,
% it requires the entire list of input angles at start.
%
% References:
%
%[1] Lior Kogan, 2013, "Circular Values Math and Statistics with C++11", 
%    https://www.codeproject.com/Articles/190833/Circular-Values-Math-and-Statistics-with-Cplusplus
%    downloaded 1 Jul 2023.
%[2] Mori, Y., 1986. Evaluation of Several Single-Pass Estimators of the 
%    Mean and the Standard Deviation of Wind Direction. J Climate Appl. 
%    Metro., Vol. 25, pp. 1387-1397.
%[3] Yamartino, R.J., 1984. A Comparison of Several "Single-Pass" Estimators
%    of the Standard Deviation of Wind Direction". Journal of Climate and 
%    Applied Meteorology. Vol. 23(9), pp. 1362-1366. 
%    doi:10.1175/1520-0450(1984)023<1362:ACOSPE>2.0.CO;2.
%
% Uses matlab's sort function

% Translated by D.Long 07 Jul 2023 from Kogan's elegant 2013 C++11 to 
% less elegant and efficient Matlab while retaining enough structure 
% to use Kogan's form and commentary 

%ExactOrAlmostEqual_sens=1.e-12; % default sensitivity for "almost equals"
ExactOrAlmostEqual_sens=0;       % used exact equals

if nargin < 1
  result=nan;
  return;
end

% check for optional input argument
if nargin > 1
  ExactOrAlmostEqual_sens=sens; % sensitivity input
end

% convert all input angles to the range [0..360) and make a column vector
ang=local_anglerange0to360(ang(:)');
Asize=length(ang); % number angles

% separate input list into lower and upper angle lists
fSum=0;
fSumSqr=0;
LowerAngles=[]; 
UpperAngles=[];
for v=ang
  fSum=fSum+v;
  fSumSqr=fSumSqr+v*v;
  if v<180
    LowerAngles=[LowerAngles v];
  else 
    UpperAngles=[UpperAngles v];
  end
end

% sort lists
LowerAngles=sort(LowerAngles,'ascend' ); % ascending order [0..180)
UpperAngles=sort(UpperAngles,'descend'); % descending order (360..180)

% see [1]. Computation is over upper and lower subsets and sectors
% set initial values and compute averages over sectors
MinAvrgVals=180;
fMinSumSqrDiff=32400*Asize-360*fSum+fSumSqr; % =SumSqr()

% average in (180..360) for set D: values in range [0,avrg-180)
fLowerBound=0;
fSumD=0;
iter=0;
for d=0:length(LowerAngles)-1
  fTestAvrg = (fSum+360*d)/Asize;
  if fTestAvrg > fLowerBound+180 & fTestAvrg <= LowerAngles(iter+1)+180
    SumSqrDval = SumSqrD(Asize,fSum,fSumSqr, fTestAvrg,d,fSumD);
    [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrDval,ExactOrAlmostEqual_sens);
  end
  fLowerBound = LowerAngles(iter+1);
  fSumD = fSumD + fLowerBound;
  iter = iter + 1;
end

fTestAvrg=(fSum+360*length(LowerAngles))/Asize;
if fTestAvrg < 360 & fTestAvrg > fLowerBound
  SumSqrDval = SumSqrD(Asize,fSum,fSumSqr, fTestAvrg,length(LowerAngles),fSumD);
  [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrDval,ExactOrAlmostEqual_sens);
end

% average in [0..180) for set C: values in range (avrg+180,360)
fUpperBound=360;
fSumC=0;
iter=0;
for c=0:length(UpperAngles)-1
  fTestAvrg=(fSum - 360*c)/Asize;
  if fTestAvrg >= UpperAngles(iter+1)-180 & fTestAvrg < fUpperBound-180
    SumSqrCval = SumSqrC(Asize,fSum,fSumSqr, fTestAvrg,c,fSumC);
    [MinAvrgVals,fMinSumSqrDiff]=TestCirSum(MinAvrgVals,fMinSumSqrDiff, fTestAvrg,SumSqrCval,ExactOrAlmostEqual_sens);
  end
  fUpperBound = UpperAngles(iter+1);
  fSumC = fSumC + fUpperBound;
  iter = iter + 1;
end

fTestAvrg=(fSum-360*length(UpperAngles))/Asize;
if fTestAvrg>=0 & fTestAvrg < fUpperBound
  SumSqrCval = SumSqrC(Asize,fSum,fSumSqr, fTestAvrg,length(UpperAngles),fSumC);
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

function out=SumSqr(Asize, fSum, fSumSqr)
%
% function out=SumSqr(Asize, fSum, fSumSqr)
% 
% returns Kogan's SumSqr function value
out=32400*Asize-fSum+fSumSqr;
end

function out=SumSqrC(Asize, fSum, fSumSqr, x, nCountC, fSumC)
%
% function out=SumSqrC(Asize, fSum, fSumSqr, x, nCountC, fSumC)
% 
% returns Kogan's SumSqrC function value with all args specified
out=x*(Asize*x-2*fSum)+fSumSqr-2*360*fSumC+nCountC*(2*360*x+360*360);
end

function out=SumSqrD(Asize, fSum, fSumSqr, x, nCountD, fSumD)
%
% function out=SumSqrD(Asize, fSum, fSumSqr, x, nCountD, fSumD)
% 
% returns Kogan's SumSqrD function value with all args specified
out=x*(Asize*x-2*fSum)+fSumSqr+2*360*fSumD+nCountD*(-2*360*x+360*360);
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