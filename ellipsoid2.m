function [xe,ye,ze] = ellipsoid2(r1,r2,r3,Cx,Cy,Cz,theta,gamma,phi,opt)

%Input
%pars: (nface*9) array. each column represents:
%(:,1): radius of ellipsoids at direction 1
%(:,2): radius of ellipsoids at direction 2
%(:,3): radius of ellipsoids at direction 3
%(:,4): x-cooridante of centroid
%(:,5): y-coordinate of centroid
%(:,6): z-coordinate of centroid
%(:,7): Inclination angle 1, degrees
%(:,8): Inclination angle 2, degrees
%(:,9): Inclination angle 3, degrees
%Output: x-, y-, and z-coordinates of an ellipsoid

arguments
    r1
    r2
    r3
    Cx
    Cy
    Cz
    theta = []
    gamma = []
    phi = []
    opt.evecs = []
    opt.nface = 20
    opt.plt = 0
end
evecs = opt.evecs;
nface = opt.nface;
plt = opt.plt;


if isempty(evecs)
    if isempty(theta)
        theta = 0;
    end
    if isempty(gamma)
        gamma = 0;
    end
    if isempty(phi)
        phi = 0;
    end
    theta = deg2rad(theta);
    gamma = deg2rad(gamma);
    phi = deg2rad(phi);
    evecs=[ cos(gamma)*cos(phi)-cos(theta)*sin(gamma)*sin(phi),   sin(gamma)*cos(phi)+cos(theta)*cos(gamma)*sin(phi),   sin(theta)*sin(phi);  ...
        -cos(gamma)*sin(phi)-cos(theta)*sin(gamma)*cos(phi),  -sin(gamma)*sin(phi)+cos(theta)*cos(gamma)*cos(phi),  sin(theta)*cos(phi);  ...
        sin(theta)*sin(gamma),                                -sin(theta)*cos(gamma),                               cos(theta)     ];
else
    if ~isempty(theta) || ~isempty(gamma) || ~isempty(phi)
        error("cannot pass in evecs and also any of theta gamma phi")
    end
end


[xe, ye, ze] = ellipsoid(0, 0, 0, r1, r2, r3, nface);


for j=1:1:(nface+1)
    for k=1:1:(nface+1)

        V=evecs'*[xe(j,k) ; ye(j,k) ; ze(j,k)];
        xe(j,k)=V(1);
        ye(j,k)=V(2);
        ze(j,k)=V(3);

    end
end

xe=xe+Cx;
ye=ye+Cy;
ze=ze+Cz;

if plt
    figure;
    h=surface(xe, ye, ze);
    set(h,'FaceColor',[255 153 153]/255,'EdgeColor','none','AmbientStrength',.5);
    hold on
    daspect([1 1 1]);
    camlight left;
    lighting gouraud;
    hold off
    view(60,30)
end

end