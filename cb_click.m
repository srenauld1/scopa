function cb_click(src, event)

if event.Button==1
    srctype = get(src, 'type');
    if strcmp(srctype, 'axes')
        src.UserData = round([event.IntersectionPoint(1)]);
    elseif strcmp(srctype, 'image')
        src.UserData = round([event.IntersectionPoint(2), event.IntersectionPoint(1)]); %make it yx
    end
end

