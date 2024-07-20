function roiclickcb(src, evnt, varargin)

pth_tmpfiles = varargin{1};

if evnt.Button==1
    ui_roi = round([evnt.IntersectionPoint(1), evnt.IntersectionPoint(2), src.UserData.imageindex]); %get(gca,'CurrentPoint')
    fid = fopen([pth_tmpfiles 'tmp_cbf_uiroi_.bin'], 'w');
    fwrite(fid, ui_roi, 'uint16')
end

end
