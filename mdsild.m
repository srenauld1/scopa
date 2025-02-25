function md = mdsild(pthstack, pthpy)

arguments
    pthstack = []
    pthpy = []
end

if isempty(pthstack)
    pthstack = glb('pthstack');
    if isempty(pthstack)
        error("you must either pass argument pthstack or set glb('pthstack')")
    end
end

id = idmake(pthstack); %just in case id info gets used below
pthmd = [id.pthstackdir id.recid '_mdsi_.txt'];


if ~isfile(pthmd) %if metadata file doesn't exist, create it by calling mdsisv.py

    fprintf("cannot find this scanimage metadata file: " + newline + pthmd + newline + "if you successfully ran registration, it should have been created" + newline + "creating it now using tifreadfast (from within mdsisv_mat), and if that fils, using python function mdsisv, and if that fails, calling mdsisv_pymat" + newline)
    pthrawpt = [id.pthstackdir id.recid '_raw_.tif'];
    pthraw = rdir(pthrawpt);
    if isempty(pthraw)
        pthrawpt = [id.pthstackdir id.recdate '-' id.fly '_*_trial_' sprintf( '%03s', id.trialnum ) '_*.tif'];
        pthraw = rdir(pthrawpt);
    end
    if isempty(pthraw)
        error("cannot find raw scanimage file matching scopa or flyg pattern to read metadata")
    end
    pthraw = pthraw.name;

    try

        mdsisv_mat(pthraw)
    
    catch

        if isempty(pthpy)
            pthpy = glb('pthpy');
            if isempty(pthpy)
                error("metadata file doesn't exist, and parsing with tifreadfast failed, and you have not set glb('pthpy'), and you didn't pass in argument pthpy, so you cannot try mdsisv.py" + newline)
            end
        end

        pthscopa = getpathscopa();

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
            py.mdsisv.mdsisv(pthraw, pthmd)
        catch ME %alternative that uses system command
            fprintf(ME.message + newline)
            fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
            pyfn = [pthscopa 'mdsisv_pymat.py'];
            syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
            system(syscmd)
        end

    end

end

md = structtxtld(pthmd);

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
    fprintf("xwid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
    md.xwid = md.xfov / md.xpix;
end
if ~isfield(md,'ywid')%do this after conversion to double
    fprintf("ywid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
    md.ywid = md.yfov / md.ypix;
end
if ~isfield(md,'zwid')%do this after conversion to double
    fprintf("zwid NOT IN mdsi, COMPUTING/ADDING IT NOW" + newline)
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
md.sampper = 1/md.volrate;

md = structsort(md, vectype='row');

end



