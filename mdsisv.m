function md = mdsisv(pthstackraw)

%matlab form of mdsisv.py; does the same thing

arguments
    pthstackraw {mustBeTextScalar} %path to raw scanimage file
end

md = [];

id = idmake(pthstackraw); %just in case id info gets used below
pthmd = [id.pthstackfld id.recid '_mdsi_.txt'];

[~, mdtif] = tifreadfast(pthstackraw, []);

trywrite = 1;
try
    if isfield(mdtif.tifinfo, 'Software') && contains(mdtif.tifinfo.Software, 'hChannels.channelSave')
        sistr = mdtif.tifinfo.Software;
    elseif isfield(mdtif, 'ImageDescription') && contains(mdtif.tifinfo.ImageDescription, 'hChannels.channelSave')
        sistr = mdtif.tifinfo.ImageDescription;
    end
    if exist('sistr', 'var') %hack to not put a try catch block within the larer more important try catch (and not repeat several lines of code)
        md.channel_save = mdsistrparse(sistr, 'channelSave');
        md.channel_active = mdsistrparse(sistr, 'channelsActive');
        md.numslice = mdsistrparse(sistr, 'actualNumSlices');
        md.numslice_withflyback = mdsistrparse(sistr, 'numFramesPerVolumeWithFlyback');
        md.flyback = md.numslice_withflyback - md.numslice;

        if md.numslice==1 && md.numslice_withflyback==1 && strcmp(mdsistrparse(sistr, 'hStackManager.enable'), 'false')
            fprintf("treating stack as planar yxt because numslice=1, numslice_withflyback=1, and hStackManager.enable is false" + newline)
            md.numvol = mdsistrparse(sistr, 'framesPerSlice');
        else
            try
                md.numvol = mdsistrparse(sistr, 'actualNumVolumes');
            catch
                md.numvol = mdsistrparse(sistr, 'numVolumes');
            end
        end

        md.xpix = mdsistrparse(sistr, 'pixelsPerLine');
        md.ypix = mdsistrparse(sistr, 'linesPerFrame');
        md.dims = [md.numvol, md.numslice_withflyback - md.flyback, md.ypix, md.xpix];
        fovtmp = mdsistrparse(sistr, 'imagingFovUm');
        md.xfov = abs(fovtmp(1)) + abs(fovtmp(3));
        md.yfov = abs(fovtmp(2)) + abs(fovtmp(4));
        if isempty(mdsistrparse(sistr, 'actualStackZStepSize'))
            md.zwid = 0;
        else
            md.zwid = mdsistrparse(sistr, 'actualStackZStepSize');
        end
        md.zstartpos = mdsistrparse(sistr, 'zsRelative');
        if isscalar(md.zstartpos)
            md.zfov = md.zwid;
        else
            md.zfov = md.zstartpos(end) + md.zwid - md.zstartpos(1);
        end
        md.framerate = mdsistrparse(sistr, 'scanFrameRate');
        md.volrate = mdsistrparse(sistr, 'scanVolumeRate');
        md.channel_offsets = mdsistrparse(sistr, 'channelOffsets');
    else
        error("cannot read metadata using tifreadfast and mdsisv.m" + newline)
    end
catch
    md = [];
    trywrite = 0;
    fprintf("cannot read metadata using tifreadfast and mdsisv.m (your stack may have been acquired with an older version of scanimage, or with software other than scanimage; run scopa registration on the raw tif and the metadata file will be created, although in this case possibily with some, but not all, dummy values)" + newline)
end

if ~isempty(mdtif)
    try
        fclose(mdtif.fid);
    catch
        fprintf("file apready closed, doing nothing" + newline)
    end
end

if isfile(pthmd)
    fprintf("not writing metadata derived from tifreadfast and mdsisv.m because metadata file already exists" + newline)
else
    if trywrite
        fprintf("writing metadata derived from tifreadfast and mdsisv.m because there is no metadata file yet" + newline)
        structsv(md, pthmd, dosort=1)
    else
        fprintf("not writing metadata because cannot read metadata using tifreadfast and mdsisv.m" + newline)
    end
end