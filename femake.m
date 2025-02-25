function fe = femake(fetype, pthstack, opt, stack, doplt)

% currently just a wrapper for feature extraction routines for all experimental domains (neurons, behavior, stimuli);
% this function will eventuallty operate on features to derive new features

arguments
    fetype
    pthstack
    opt = []
    stack = []
    doplt = []
end

if isempty(doplt)
    doplt = any(strcmp('fe', glb('fe')));
end

fe = [];

for k = 1:numel(fetype)

    switch fetype{k}

        case 'bmp'

            fn = fieldnames(o.bmp);
            for m = 1:numel(fn)
                optid = fn{m};
                indv = daq.vy; %hard coding this for now
                % o2.roi.regionex = 'eb';
                % depv = tsget(o2, chan=o.bmp.(optid).chan);
                depv = roi.a5.ts{1};
                fe.bmp.(optid) = bmpmake(indv, depv, md.volrate, daq.epochts, pthstack, o.bmp.(optid)); %fit bump
            end

        case 'fmf'

            [fe.fmf.(opt.fmf.id), fmfvid] = flymaxfe(pthstack, opt.fmf);


    end

end