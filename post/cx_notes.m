notes 

 It sounds to me as if your objective function is time-consuming to evaluate. 
 If so, then you can probably get better control over the amount of time the 
 solver takes by using MultiStart. You see, GlobalSearch evalueates the objective 
function quite a large number of times without calling fmincon. In contrast, 
MultiStart calls fmincon repeatedly. So perhaps, in your case, you would get a good 
solution in less time, and in a more controlled amount of time, by using MultiStart, 
and having all computations be directed at finding a minimum, rather than at determining 
whether or not it is worthwhile to run fmincon.
https://www.mathworks.com/matlabcentral/answers/127754-misunderstanding-about-the-number-of-trial-points-in-globalsearch