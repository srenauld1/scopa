function [cbflag, roishape, ttl] = cb_roishape(currkey)

persistent roishape_tmp
persistent ttltmp
persistent prevkey
persistent nm
persistent cbflagtmp

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
end

exit_sequence = 0;
init_sequence = 0;
invalid_key = 0;
roishape = []; %always empty unless successful exit

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

if ~invalid_key
    prevkey = currkey;
end
ttl = ttltmp;
cbflag = cbflagtmp;

if exit_sequence || init_sequence
    roishape_tmp = [];
    if exit_sequence
        ttltmp = []; %we clear this on exit, not init, unlike cb_idx, since ttltmp is just assigned, not concatenated with each keypress
        prevkey = [];
        nm = [];
        cbflagtmp = [];
    end
end

end