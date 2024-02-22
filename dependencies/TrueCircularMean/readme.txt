Documentation and example usage for circular_mean.m and associated routines
https://www.mers.byu.edu/circularmean.html

David Long 08 Jul 2023

When computing the mean of angles the conventional approach is to take
the arctangent of the mean sine and cosine of the angles. However, this
is not true circular mean.  Consider:

The mean M of a discrete set a={a_i} is formally defined as 

 M = argmin Sum distance_function(a_i,m)                 (1)
       m     i

where the distance_function(a_i,m) is some metric appropriate to the set.

For a linear mean, the one we are used to for linear values, the distance
function is given by distance_function(a_i,m)=abs(a_i-m). However, for the
conventional method commonly used for computing an average angle, i.e.,
the arctangent of the mean of the sine and cosine of the angles, it can
be shown that the distance function is actually given by

   (conventional) distance_function(a_i,m)=1-cos(a_i-m),

which is quite different than a linear mean.

To solve for the mean using Eq. (1), we take the derivative and set it to zero.
The conventional method has the advantage of being easily differentiable.
The average angle distance metric (1-cos(a_i-m)) yields the conventional
formula for an "average angle" Ma given by:

 Ma = atan2(sum(sin(a*pi/180)), sum(cos(a*pi/180))) -equivalent to-
 Ma = atan2(mean(sin(a*pi/180)), mean(cos(a*pi/180))) -or-
 Ma = angle(exp(j*a*pi/180)) (in Matlab)

This works where the arctangent of its input arguments are defined. Note
that it involves transcendential functions and that the distance function is 
related to the cosine of the angle difference. Further, when using circular
sets such day of year, the value (which might be an integer) has to be
converted to the range [0..2*pi), which involves the irrational number pi.

However, when considering the difference between two angles, the distance
function can be better defined as what might called the minimum arc distance,
i.e., the minimum of the two possible angles or arcs between the two angles.
That is, the minimum angle moving clockwise or counterclockwise from
one angle to the other.  This minimum arc distance is between 0 and 180 deg.
This is the linear distance as defined on a circular set. Computationally,
this is the minimum of abs(a_i-m), abs(a_i-m-360), and abs(a_i-m+360), which
can be written succintly as

  distance_function(a_i,m)=180-abs(180-abs(mod(a_i-m,360))). (2)

where mod(x,y) is defined as in Matlab. Note: the signed (+CCW vs -CW)
distance_function for two angles a_i and m can be written as

   distance_function(a_i,m)=mod(m-a_i+180,360)-180       (3)

Eq. (2) appears hard to differentiate. However, by dividing the modulo and
absolute value functions into sets, the derivative of the distance function
can be determined [1], which can be used to solve Eq. (1) for the true circular
mean. This is computationally a little complicated since it requires sorting
parts of the data, but it involves no transcendential functions.  Further,
Kogan's implementation [1] avoids the angle sampling limitations required by
Matsuti's method [2]. Computation in degrees avoids irrational numbers such as
pi and so is well-suited for other circular data sets. Note that Kogan's
method is not a "single-pass" algorithm [2,3], i.e., it requires the entire
list of input angles at start.

The weighted circular mean Mw is defined as 

  Mw = argmin Sum w_i*distance_function(a_i,m)           (4)
         m     i

where {w_i} is the set weights associated with {a_i}.

The true circular standard deviation S is given by

  S=sqrt( Sum distance_function(a_i,Mt)^2 / N)           (5)
           i

where Mt is the true circular mean and N is the number of angles in the
set {a_i}. Note that this differs from common approximations for the angle
standard deviation used by others [2],[3]. In computing both the conventional
and circular standard deviation, this code uses the definition in Eq. (5).
This expression can be used for the true circular mean since the mean error
is zero. The weighted true circular standard deviation is given by 

  S=sqrt( Sum w_i*distance_function(a_i,Mt)^2 / Sum w_i). (6)
           i                                     i

Also of interest is the circular median, which has several potential
definitions and so is not unique. Here, the circular median is defined
as the input angle which has the smallest summed absolute angular distance
between it and all other input angles. The circular median D as used here is

  D = argmin Sum |distance_function(a_i,a_d)|.
        d   i~=d

This package includes code for computing the true circular mean, standard
deviation, and median as defined. Also provided is code to compute the
conventional angle mean.

References:

[1] Lior Kogan, 2013, "Circular Values Math and Statistics with C++11", 
    https://www.codeproject.com/Articles/190833/Circular-Values-Math-and-Statistics-with-Cplusplus
    downloaded 1 Jul 2023.
[2] Mori, Y., 1986. Evaluation of Several Single-Pass Estimators of the 
    Mean and the Standard Deviation of Wind Direction. J Climate Appl. 
    Metro., Vol. 25, pp. 1387-1397.
[3] Yamartino, R.J., 1984. A Comparison of Several "Single-Pass" Estimators
    of the Standard Deviation of Wind Direction". Journal of Climate and 
    Applied Meteorology. Vol. 23(9), pp. 1362-1366. 
    doi:10.1175/1520-0450(1984)023<1362:ACOSPE>2.0.CO;2.
 

Matlab Routines:

circular_mean.m : function result = circular_mean(ang, sens)
                   return circular_mean
circular_std.m  : function [mean_out std_out] = circular_std(ang)
                   return circular_mean and standard deviation
weighted_circular_mean.m : function result = weighted_circular_mean(ang, weights, sens)
weighted_circular_std.m : function result = weighted_circular_std(ang, weights, sens)
                   return weighted circular_mean and standard deviation
cmediandeg.m    : function out=cmediandeg(in)
                   return circular median (input angle with smallest total 
                   absolute angular difference)
diffangledeg.m  : function out = diffangledeg(in1,in2);
                   return signed angular difference between two angles
example_usage.m : this file
meanangledeg.m  : function out = meanangledeg(in,dim,sens);
                   return conventional angle mean computed using sin/cos/atan2
stdangledeg.m   : function [mean_out mean_out2 std] = stdangledeg(in,dim,sens);
                    return conventional trigonometric angle mean estimate and
                    the mean and standard deviation of the angular difference
                    between the trig angle mean and the input angles


Example cases: (from example_usage.m)

Set of Angles: -10 90 5 (deg)
 Circular mean and std:       28.33   44.03
 Conventional mean and std:   24.76   44.03   std mean err:  3.58
 Circular median & index:      5.00    3

Set of Angles: 30 90 200 (deg)
 Circular mean and std:      106.67   70.40
 Conventional mean and std:   93.64   70.40   std mean err: 13.03
 Circular median & index:     90.00    2

Set of Angles: 45 48 42 (deg)
 Circular mean and std:       45.00    2.45
 Conventional mean and std:   45.00    2.45   std mean err:  0.00
 Circular median & index:     45.00    1
