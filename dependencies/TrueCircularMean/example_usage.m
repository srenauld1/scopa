%
% Documentation and example usage for circular_mean.m and associated routines
% https://www.mers.byu.edu/circularmean.html 
%
% This matlab script is intended to document and demonstrate the use of
% compute_mean and compute_std.  It also demonstrates the difference between
% conventional mean angles and the true circular mean.
%
% Circular Mean Theory: (see description.txt)
% 
% written by David Long at BYU 07 Jul 2023, revised 31 Jul 2013
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to illustrate the difference between the conventional mean and the true
% circular mean consider some example cases below
%
% note: all test cases use angles in [0..360); however, inputs can be 
% any angles in degrees, e.g., in [-180..180]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specify some test cases, each with 3 angles
%
for icase=1:3
  switch icase
  case 1
    angs=[-10 90 5];
    % in this case, the circular and conventional means differ somewhat
  case 2    
    angs=[30 90 200];
    % in this case, the circular and conventional means differ significantly
  case 3
    angs=[45 48 42];
    % Note: circular and conventional areidentical in this case
  end


  % circular and conventional angle means
  cm=circular_mean(angs);      % circular mean
  am=meanangledeg(angs);       % conventional angle mean

  % compute mean and standard deviation for both circular mean and 
  [cm,cs]=circular_std(angs);       % circular mean and std
  [am,am2,as]=stdangledeg(angs);    % conventional angle mean and std
  [medang,medind]=cmediandeg(angs); % compute circular median angle
  
  % write output values
  fprintf('\nSet of Angles:');
  fprintf(' %d',angs);
  fprintf(' (deg)\n');
  fprintf(' Circular mean and std:     %7.2f %7.2f\n',cm(1),cs);
  fprintf(' Conventional mean and std: %7.2f %7.2f   std mean err: %5.2f\n',am,as,am2);
  fprintf(' Circular median & index:   %7.2f %4d\n',medang,medind);

  % plot
  % standard matlab plotting conventions with angles CCW from X axis
  figure(icase)
  % draw polar axes and unit circle
  plot([-1.2 1.2],[0,0],'k');
  hold on;
  plot([0,0],[-1.2 1.2],'k');
  plot(cos(pi*(0:360)/180),sin(pi*(0:360)/(180)),'c');
  % show angles
  plot(cos(pi*angs/180),sin(pi*angs/(180)),'b*');
  % conventional mean
  plot([0,1.1*cos(am*pi/180)],[0,1.1*sin(am*pi/180)],'k');
  % circular mean
  plot([0,1.1*cos(cm*pi/180)],[0,1.1*sin(cm*pi/180)],'-r');
  hold off;
  title('Red=Circular mean; Black=Conv angle mean; Blue=input angles');
  xlabel('x');
  ylabel('y');
  axis square

  if icase==2
    % save example case
    print -dpng example.png
  end
end

