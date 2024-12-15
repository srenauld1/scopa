function uiclickim(src, evnt)

if evnt.Button==1
    % src.UserData = round([evnt.IntersectionPoint(1), evnt.IntersectionPoint(2)]);
    src.UserData = round([evnt.IntersectionPoint(2), evnt.IntersectionPoint(1)]); %make it yx
end
