function fe = femake(stack, pthstack, optid, t, opt, doplt)

% generalized feature extraction for any experimental domain (neurons, behavior, stimuli); 
% contains subroutines specialized for different features (e.g., bump extracted from stack, visual features extracted from visual stimulus) 

arguments
    stack
    pthstack
    optid
    t = [] %only required nonempty if ~isempty(wavp) or channorm~=0 in roits
    opt = []
    doplt = []
end

pthpre = [erase(pthstack, '.mat') optid '_roi_'];
pthfe = [pthpre '.mat'];

if isempty(doplt)
    doplt = any(strcmp('fe', glb('plt')));
end

if ~isempty(opt)
    fetype = opt.fetype;
end

try

    fe = load(pthfe);
    % if any(~isfield(roi, {'ts', 'dat'})) || any(~isfield(roi, {'ts', 'dat'}))
    %     error("roi struct must contain fields 'ts' and 'dat'; you may have loaded an old roi struct")
    % end

catch ME

    fprintf("" + ME.message + newline + "creating fe struct now" + newline)

    switch fetype

        case 'bmp'

            indv = vis.yaw; %hard coding this for now
            % o2.roi.rgname = 'eb';
            % depv = tsget(o2, chan=o.bmp.(optid).chan);
            depv = roi.a28.ts{o.bmp.(optid).chan};
            bmp.(optid) = bmpmake(indv, depv, md.volrate, vis.epochts, pthstack, optid, o.bmp.(optid)); %fit bump

        case 'flymax'

            [vis.(o.feat.id), stimvid] = featld(pthstack, o.feat);

    end

end