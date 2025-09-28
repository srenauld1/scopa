function roifauto(pthpy, optcm, opt)

arguments
    pthpy = []
    optcm = []
    opt.rgname = 'none'
    opt.mmname = 'none'
end
error("need to insert glboropt")


if isempty(pthpy)
    pthpy = glb('pthpy');
    if isempty(pthpy)
        error("you have not set glb('pthpy'), and you didn't pass in argument pthpy; you must do one or the other" + newline)
    end
end
if isempty(optcm)
    fprintf("user did not pass in options as argument, using all defaults")
    tmp = ofill('roi.cm', nest=1, unpack=1);
    optcm = tmp.cm;
end

pthscopa = pathscopaget();

try %run python directly from matlab (ie not using system command to control a shell)
    petmp = pyenv;
    if ~strcmp(petmp.Executable, pthpy) && ~strcmp(petmp.ExecutionMode, 'OutOfProcess')
        try
            pyenv(ExecutionMode="OutOfProcess")
            pyenv(Version=pthpy)
        catch ME
            fprintf(ME.message + newline)
            fprintf("do not use pyenv in the current matlab session with a different Version or ExecutionMode than those specified here" + newline)
        end
    end
    if count(py.sys.path,pthscopa) == 0
        insert(py.sys.path,int32(0),pthscopa);
    end
    py.extract.extract( ...
        pth_prefix='', ...
        pth_tif_read='', ...
        pth_optdf='', ...
        pth_optroi='', ...
        md=2, ...
        extract_in_2d=0, ...
        methodex='1', ...
        rgname=rgname, ...
        mmname=mmname, ...
        optall=optcm ...
        );
catch ME %alternative that uses system command
    fprintf(ME.message + newline)
    fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
    pyfn = [pthscopa 'extract_mat.py'];
    syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
    system(syscmd)
end
