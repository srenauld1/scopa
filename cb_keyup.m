function cb_keyup(src, event, opt)

%callback function to capture key release

arguments
    src
    event
    opt.releasekeys = []
end

if ismember(event.Key, opt.releasekeys) && ~isempty(src.UserData)
    src.UserData = ['released ' src.UserData];
end

end
