function ui_t_click_fcn(src, evnt, varargin)

fnuip = varargin{1};

if evnt.Button==1
    ui_t = round([evnt.IntersectionPoint(1)]); 
    fid = fopen(fnuip, 'w');
    fwrite(fid, ui_t, 'uint16');
    fclose('all');
end
