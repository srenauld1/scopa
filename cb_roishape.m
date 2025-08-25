function [cbflag, roishape, ttl, success] = cb_roishape(currkey, roishape)

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

success = 0;
exit_sequence = 0;
init_sequence = 0;
invalid_key = 0;

if strcmp(currkey, nm) %reset if you press init key
    ttltmp = [nm ' (shape): '];
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
            roishape = roishape_tmp;
            exit_sequence = 1;
            cbflagtmp = flagset(0);
            success = 1;
        end
    elseif strcmp(currkey, 'c')
        roishape_tmp = 'circle';
        ttltmp = [nm ' (shape): c (circle)'];
    elseif strcmp(currkey, 'e')
        roishape_tmp = 'ellipse';
        ttltmp = [nm ' (shape): e (ellipse)'];
    elseif strcmp(currkey, 'f')
        roishape_tmp = 'freehand';
        ttltmp = [nm ' (shape): f (freehand)'];
    elseif strcmp(currkey, 'p')
        roishape_tmp = 'polygon';
        ttltmp = [nm ' (shape): p (polygon)'];
    elseif strcmp(currkey, 'r')
        roishape_tmp = 'rectangle';
        ttltmp = [nm ' (shape): r (rectangle)'];
    else
        invalid_key = 1;
        % ttltmp = [nm ' (shape): INVALID KEY'];
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