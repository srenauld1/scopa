function ui_roi_click_fcn(src, evnt)


if evnt.Button==1
    src.UserData.roicen = round([evnt.IntersectionPoint(1), evnt.IntersectionPoint(2), src.UserData.imageindex]);
end
