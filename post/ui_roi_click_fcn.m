function ui_roi_click_fcn(src, evnt, varargin)

fnuip = varargin{1};

if evnt.Button==1
    ui_roi = round([evnt.IntersectionPoint(1), evnt.IntersectionPoint(2), src.UserData.imageindex]);
    fid = fopen(fnuip, 'w');
    fwrite(fid, ui_roi, 'uint16');
    fclose('all');
end
