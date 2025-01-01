pyruntest


    system("/Users/wienecke/miniforge3/bin/python3 /Users/wienecke/scopa/mdsisv.py --pthstack '/Users/wienecke/stacks/20230627-2_D05_syt7f_018_syt7f/20230627_2_2_cmrg_dcdn_.mat' --pthmd ''/Users/wienecke/stacks/20230627-2_D05_syt7f_018_syt7f/20230627_2_2_mdsi_.txt''")

    petmp = pyenv;
    if ~strcmp(petmp.Executable, "/Users/wienecke/miniforge3/bin/python3") && contains(petmp.Home, "wienecke")
        pyenv(Version="/Users/wienecke/miniforge3/bin/python3")
        pyenv(Version="/Users/wienecke/miniforge3/envs/caiman/bin/python3")
    end
    insert(py.sys.path, int64(0), '/Users/wienecke/scopa/')
    insert(py.sys.path, int64(0), '/Users/wienecke/miniforge3/envs/caiman')
    insert(py.sys.path, int64(0), '/Users/wienecke/miniforge3/envs/si')

    % pyExec = 'C:\software\miniconda3\envs\mlpy\python.exe';
    pyExec = '/Users/wienecke/miniforge3/envs/caiman/bin/python3';
    pyRoot = fileparts(pyExec);
    p = getenv('PATH');
    p = strsplit(p, ';');
    addToPath = {
        pyRoot
        fullfile(pyRoot, 'Library', 'mingw-w64', 'bin')
        fullfile(pyRoot, 'Library', 'usr', 'bin')
        fullfile(pyRoot, 'Library', 'bin')
        fullfile(pyRoot, 'Scripts')
        fullfile(pyRoot, 'bin')
        };
    p = [addToPath(:); p(:)];
    p = unique(p, 'stable');
    p = strjoin(p, ';');
    setenv('PATH', p);

    clear classes
    module_to_load = 'ScanImageTiffReader';
    python_module_to_use = py.importlib.import_module(module_to_load);


    mefff = pyrunfile("/Users/wienecke/scopa/fool.py", "z",x=2, y=4);

    mefff = pyrunfile("/Users/wienecke/scopa/mdsisv_mat.py",pthstack=pthstack,pthmd=pthmd);