function roifauto(pthpy, opt, opt2)

arguments
    pthpy = []
    opt = []
    opt2.rgname = 'none'
    opt2.mmname = 'none'
end
rgname = opt2.rgname;
mmname = opt2.mmname;



if isempty(pthpy)
    pthpy = glb('pthpy');
    if isempty(pthpy)
        error("you have not set glb('pthpy'), and you didn't pass in argument pthpy; you must do one or the other" + newline)
    end
end
if isempty(opt)
    fprintf("user did not pass in options as argument, using all defaults")
    tmp = ofill('roi.cm', rec=1, unpack=1);
    opt = tmp.cm;
end

pthscopa = pthscopaget();

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
        optall=opt ...
        );
catch ME %alternative that uses system command
    fprintf(ME.message + newline)
    fprintf("RUNNING PYTHON DIRECTLY FAILED, USING system TO RUN PYTHON INSTEAD")
    pyfn = [pthscopa 'extract_mat.py'];
    syscmd = [pthpy ' ' pyfn ' ' pthraw ' ' pthmd];
    system(syscmd)
end
