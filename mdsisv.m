function md = mdsisv(pthraw)

%matlab form of mdsisv.py; does the same thing

arguments
    pthraw
end

md = [];

id = idmake(pthraw); %just in case id info gets used below
pthmd = [id.pthstackdir id.recid '_mdsi_.txt'];

[~, mdtif] = tifreadfast(pthraw, []);

trywrite = 1;
try
    if isfield(mdtif.tifinfo, 'Software') && contains(mdtif.tifinfo.Software, 'hChannels.channelSave')
        sistr = mdtif.tifinfo.Software;
    elseif isfield(mdtif, 'ImageDescription') && contains(mdtif.tifinfo.ImageDescription, 'hChannels.channelSave')
        sistr = mdtif.tifinfo.ImageDescription;
    end
    if exist('sistr', 'var') %hack to not put a try catch block within the larer more important try catch (and not repeat several lines of code)
        md.channel_save = sistrparse(sistr, 'channelSave');
        md.channel_active = sistrparse(sistr, 'channelsActive');
        md.numslice = sistrparse(sistr, 'actualNumSlices');
        md.numslice_withflyback = sistrparse(sistr, 'numFramesPerVolumeWithFlyback');
        md.flyback = md.numslice_withflyback - md.numslice;

        if md.numslice==1 && md.numslice_withflyback==1
            if ~strcmp(sistrparse(sistr, 'hStackManager.enable'), 'false')
                error("if numslice is 1, hStackManager.enable should be false")
            end
            fprintf("hStackManager.enable is false, treating stack as planar yxt" + newline)
            md.numvol = sistrparse(sistr, 'framesPerSlice');
        else
            try
                md.numvol = sistrparse(sistr, 'actualNumVolumes');
            catch
                md.numvol = sistrparse(sistr, 'numVolumes');
            end
        end
        md.xpix = sistrparse(sistr, 'pixelsPerLine');
        md.ypix = sistrparse(sistr, 'linesPerFrame');
        md.dims = [md.numvol, md.numslice_withflyback - md.flyback, md.ypix, md.xpix];
        fovtmp = sistrparse(sistr, 'imagingFovUm');
        md.xfov = abs(fovtmp(1)) + abs(fovtmp(3));
        md.yfov = abs(fovtmp(2)) + abs(fovtmp(4));
        if isempty(sistrparse(sistr, 'actualStackZStepSize'))
            md.zwid = 0;
        else
            md.zwid = sistrparse(sistr, 'actualStackZStepSize');
        end
        md.zstartpos = sistrparse(sistr, 'zsRelative');
        if isscalar(md.zstartpos)
            md.zfov = md.zwid;
        else
            md.zfov = md.zstartpos(end) + md.zwid - md.zstartpos(1);
        end
        md.framerate = sistrparse(sistr, 'scanFrameRate');
        md.volrate = sistrparse(sistr, 'scanVolumeRate');
        md.channel_offsets = sistrparse(sistr, 'channelOffsets');
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
        structsv(md, pthmd)
    else
        fprintf("not writing metadata because cannot read metadata using tifreadfast and mdsisv.m" + newline)
    end
end