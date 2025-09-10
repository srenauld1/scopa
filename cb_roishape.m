function [cbflag, roishape, ttl, validkeysp] = cb_roishape(currkey)

persistent roishape_tmp
persistent ttltmp
persistent prevkey
persistent nm
persistent cbflagtmp
persistent validkeysp

if isempty(prevkey)
    cbflagtmp = flagset(currkey, 1);
    nmtrue = cellfun(@(x) isequal(x,1), struct2cell(cbflagtmp)); % find the one field of struct 'nm' that is true
    nm = fieldnames(cbflagtmp);
    nm = nm(nmtrue);
    if isscalar(nm)
        nm = cell2mat(nm);
    else
        error("only one field of struct nm can be true")
    end

    validkeysp = {nm, 'return', 'escape', 'c', 'e', 'f', 'p', 'r', 'v'};

    ttl_validkeysp = {[nm ' (init)'], '[0-9] (digits)', 'return (finish)', 'escape (exit)', 'comma (elements)', 'semicolon (vectors)', 'colon (range)', 'hyphen (equispace)', 'slash (mean)'};
    ttl_validkeysp = ttl_validkeysp(startsWith(ttl_validkeysp, strcat(validkeysp, ' (')));
    ttl_validkeysp = sprintf('%s, ', ttl_validkeysp{:});
    ttl_validkeysp = ttl_validkeysp(1:end-2); %remove 2 because of trailing comma and whitespace
    ttl_validkeysp = ['VALID KEYS: ' ttl_validkeysp];

end

exit_sequence = 0;
init_sequence = 0;
invalid_key = 0;
roishape = []; %always empty unless successful exit

if any(strcmp(currkey, validkeysp))

    if strcmp(currkey, nm) %reset if you press init key
        ttltmp = [nm ' (roishape): '];
        init_sequence = 1;
    elseif strcmp(currkey, 'escape')
        exit_sequence = 1;
        cbflagtmp = flagset(0);
    else
        if strcmp(currkey, 'return')
            if isempty(roishape_tmp)
                invalid_key = 1;
                ttltmp = 'YOU MUST SELECT ROISHAPE, OR PRESS ESCAPE';
            else
                exit_sequence = 1;
                cbflagtmp = flagset(0);
                roishape = roishape_tmp;
            end
        elseif strcmp(currkey, 'c')
            roishape_tmp = 'circle';
            ttltmp = [nm ' (roishape): c (circle)'];
        elseif strcmp(currkey, 'e')
            roishape_tmp = 'ellipse';
            ttltmp = [nm ' (roishape): e (ellipse)'];
        elseif strcmp(currkey, 'f')
            roishape_tmp = 'freehand';
            ttltmp = [nm ' (roishape): f (freehand)'];
        elseif strcmp(currkey, 'p')
            roishape_tmp = 'polygon';
            ttltmp = [nm ' (roishape): p (polygon)'];
        elseif strcmp(currkey, 'r')
            roishape_tmp = 'rectangle';
            ttltmp = [nm ' (roishape): r (rectangle)'];
        elseif strcmp(currkey, 'v')
            roishape_tmp = 'voxel';
            ttltmp = [nm ' (roishape): v (voxel)'];
        else
            invalid_key = 1;
            % ttltmp = [nm ' (roishape): INVALID KEY'];
        end
    end
end

if ~invalid_key
    prevkey = currkey;
end
ttl = ttltmp;
cbflag = cbflagtmp;

if exit_sequence || init_sequence
    roishape_tmp = [];
    if exit_sequence
        ttltmp = []; %we clear this on exit, not init, unlike cb_array, since ttltmp is just assigned, not concatenated with each keypress
        prevkey = [];
        nm = [];
        cbflagtmp = [];
    end
end

end