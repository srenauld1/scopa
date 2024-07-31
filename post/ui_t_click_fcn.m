function ui_t_click_fcn(src, evnt)

if evnt.Button==1
    src.UserData = round([evnt.IntersectionPoint(1)]);
end
