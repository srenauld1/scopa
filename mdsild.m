function md = mdsild(pth, opt)

%{

read scanimage metadata from raw scanimage file
matlab form of mdsild.py; does the same thing; if this fails, runs msdisv.py

%}

arguments
    pth {mustBeTextScalar} = '' %path to metadata file ('*mdsi_.txt'), or path to stack, or path to daq file
    opt.doflyg {mustBeBinary} = 0 % 1 to also load flyg metadata and include in output md
end
doflyg = opt.doflyg;

id = idmake(pth); %this will for idmake fields needed here if pth is mdsi file, stack file, or daq file
pthmd = [id.pthrec '_mdsi_.txt'];

if ~isfile(pthmd) %if metadata file doesn't exist, create it by calling mdsild.py

    fprintf("cannot find this scanimage metadata file: " + newline + pthmd + newline + "if you successfully ran registration, it should have been created" + newline + "creating it now using tifreadfast (from within mdsild.m), and if that fils, using python function mdsild, and if that fails, calling mdsild.py" + newline)
    pthrawpt = [id.pthrec '_o_.tif'];
    pthraw = rdir(pthrawpt);
    if isempty(pthraw)
        pthrawpt = [id.pthstackfld id.recdate '-' id.fly '_*_trial_' sprintf( '%03s', id.trial) '_*.tif'];
        pthraw = rdir(pthrawpt);
    end
    if isempty(pthraw)
        error("cannot find raw scanimage file matching scopa or flyg pattern to read metadata")
    end
    pthraw = pthraw.name;

    try

        md = [];

        id = idmake(pthraw); %just in case id info gets used below
        pthmd = [id.pthstackfld id.recid '_mdsi_.txt'];

        [~, mdtif] = tifreadfast(pthraw, []);

        trywrite = 1;
        try
            if isfield(mdtif.tifinfo, 'Software') && contains(mdtif.tifinfo.Software, 'hChannels.channelSave')
                sistr = mdtif.tifinfo.Software;
            elseif isfield(mdtif, 'ImageDescription') && contains(mdtif.tifinfo.ImageDescription, 'hChannels.channelSave')
                sistr = mdtif.tifinfo.ImageDescription;
            end
            if exist('sistr', 'var') %hack to not put a try catch block within the larer more important try catch (and not repeat several lines of code)
                md.channel_save = strparse(sistr, 'channelSave');
                md.channel_active = strparse(sistr, 'channelsActive');
                md.numslice = strparse(sistr, 'actualNumSlices');
                md.numslice_withflyback = strparse(sistr, 'numFramesPerVolumeWithFlyback');
                if md.numslice < 1 %actualNumSlices can be 0 in some scanimage acquisitions (eg aborted, or certain fastZ configs); fall back to the configured hStackManager.numSlices so numslice/flyback/dims are not left at 0
                    numslice_cfg = strparse(sistr, 'hStackManager.numSlices');
                    fprintf("actualNumSlices is %d (invalid); falling back to hStackManager.numSlices = %d" + newline, md.numslice, numslice_cfg)
                    md.numslice = numslice_cfg;
                end
                md.flyback = md.numslice_withflyback - md.numslice;

                if md.numslice==1 && md.numslice_withflyback==1 && strcmp(strparse(sistr, 'hStackManager.enable'), 'false')
                    fprintf("treating stack as planar yxt because numslice=1, numslice_withflyback=1, and hStackManager.enable is false" + newline)
                    md.numvol = strparse(sistr, 'framesPerSlice');
                else
                    try
                        md.numvol = strparse(sistr, 'actualNumVolumes');
                    catch
                        md.numvol = strparse(sistr, 'numVolumes');
                    end
                end

                md.xpix = strparse(sistr, 'pixelsPerLine');
                md.ypix = strparse(sistr, 'linesPerFrame');
                md.dims = [md.numvol, md.numslice_withflyback - md.flyback, md.ypix, md.xpix];
                fovtmp = strparse(sistr, 'imagingFovUm');
                md.xfov = abs(fovtmp(1)) + abs(fovtmp(3));
                md.yfov = abs(fovtmp(2)) + abs(fovtmp(4));
                if isempty(strparse(sistr, 'actualStackZStepSize'))
                    md.zwid = 0;
                else
                    md.zwid = strparse(sistr, 'actualStackZStepSize');
                end
                md.zstartpos = strparse(sistr, 'zsRelative');
                if isscalar(md.zstartpos)
                    md.zfov = md.zwid;
                else
                    md.zfov = md.zstartpos(end) + md.zwid - md.zstartpos(1);
                end
                md.framerate = strparse(sistr, 'scanFrameRate');
                md.volrate = strparse(sistr, 'scanVolumeRate');
                md.channel_offsets = strparse(sistr, 'channelOffsets');
            else
                error("cannot read metadata using tifreadfast and mdsild.m" + newline)
            end
        catch
            md = [];
            trywrite = 0;
            fprintf("cannot read metadata using tifreadfast and mdsild.m (your stack may have been acquired with an older version of scanimage, or with software other than scanimage; run scopa registration on the raw tif and the metadata file will be created, although in this case possibily with some, but not all, dummy values)" + newline)
        end

        if ~isempty(mdtif)
            try
                fclose(mdtif.fid);
            catch
                fprintf("file apready closed, doing nothing" + newline)
            end
        end

        if isfile(pthmd)
            fprintf("not writing metadata derived from tifreadfast and mdsild.m because metadata file already exists" + newline)
        else
            if trywrite
                fprintf("writing metadata derived from tifreadfast and mdsild.m because there is no metadata file yet" + newline)
                structsv(md, pthmd, dosort=1)
            else
                fprintf("not writing metadata because cannot read metadata using tifreadfast and mdsild.m" + newline)
            end
        end


    catch

        pthscopa = pthscopaget();
        pthpy = userdatfile('pthpy', err=1); %path to python executable; only required to run caiman from matlab (if opt.cm is nonempty)

        try %run python directly from matlab (ie not using system command to control a shell)
            petmp = pyenv;
            if ~strcmp(petmp.Executable, pthpy) && ~strcmp(petmp.ExecutionMode, 'OutOfProcess')
                try
                    pyenv(ExecutionMode="OutOfProcess")
                    pyenv(Version='/Library/Frameworks/Python.framework/Versions/3.10/bin/python3')
                    pyenv(Version=pthpy)
                catch ME
                    fprintf(ME.message + newline)
                    fprintf("do not use pyenv in the current matlab session with a different Version or ExecutionMode than those specified here" + newline)
                end
            end
            if count(py.sys.path,pthscopa) == 0
                insert(py.sys.path,int32(0),pthscopa);
            end
            py.mdsild.mdsild(pthraw, pthmd)
        catch ME %alternative that uses system command
            fprintf(ME.message + newline)
            fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
            pyfn = [pthscopa 'mdsild.py'];
            syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
            system(syscmd)
        end

    end

end

md = structld(pthmd, dosort=0);

md.sz = [md.ypix md.xpix md.numslice md.numvol];


if ~isfield(md,'channel_save')
    md.channel_save = 1;
end
if ~isfield(md,'channel_active')
    md.channel_active = 1;
end
if isfield(md,'md_hires')
    md = rmfield(md, 'md_hires');
end


md = cell2struct(cellfun(@double,struct2cell(md),'uni',false),fieldnames(md),1); %make everything double bc python made uint64

if ~isfield(md,'xwid')%do this after conversion to double
    md.xwid = md.xfov / md.xpix;
end
if ~isfield(md,'ywid')%do this after conversion to double
    md.ywid = md.yfov / md.ypix;
end
if ~isfield(md,'zwid')%do this after conversion to double
    md.zwid = md.zfov / md.numslice;
end
if ~isfield(md,'zstartpos')%do this after conversion to double
    tmp = 0:md.zwid:md.zfov;
    md.zstartpos = tmp(1:end-1);
    if isempty(md.zstartpos)
        md.zstartpos = 0;
    end
end

md.widyxz = [md.ywid, md.xwid, md.zwid];
md.sper = 1/md.volrate;


if doflyg
    pthmd_flyg_pat = [pthstackfld id.recdate '-' id.fly '_metadata_*_trial_' sprintf( '%03d', id.trialnum ) '.mat'];
    pthmd_flyg = rdir(pthmd_flyg_pat);
    if isempty(pthmd_flyg)
        pthmd_flyg = [];
    else
        pthmd_flyg = pthmd_flyg.name;
    end
    [md.expMetadata, md.trialMetadata, md.patternMetadata, md.fictracMetadata, md.fmd] = mdflygld(pthmd_flyg, pth);
end


md = structsort(md, vectype='row');

end



function val = strparse( str, key )

%parse scanimage metadata string
%output val will be number if it's a digit, otherwise char

str = transpose(strsplit(str, '\n')); %transpose bc it's easier to read as a column
idx = find(contains(str, key));
if isscalar(idx)
    tmp = str{idx};
elseif isempty(idx)
    error("no match found in SI string")
else
    error("multiple matches found in SI string")
end
tok = regexp(tmp, '= (.*)$', 'tokens'); %match whatever comes after equals sign
if isempty(tok)
    error("cannot parse SI string")
else
    val = str2double(regexp(tok{1}{1}, '(\-\d*|\d*)\.\d*|(\-\d*|\d*)', 'match')); %try to convert to number (matrix will be vector)
    if ~isempty(val)
        if isnan(val) %if it's not a number, just output char
            val = strrep(tok{1}{1},  '''', ''); %make sure char output does not have extra quotes
        else
            if numel(val)>1 && contains(tok{1}{1}, ';')
                fprintf("WARNING, CHAR CONTAINS SEMICOLON, BUT OUTPUT IS VECTOR; " + newline)
            end
        end
    end
end

end



