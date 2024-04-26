function [] = f1(rootDir, recurse, overwrite, scanimageVersion, maxData, singleFrame_reg, inp)

% Default settings
arguments
    rootDir char
    recurse double = 0 % number of levels to recurse, looking for experimental folders
    overwrite logical = false
    scanimageVersion double = 2019.1
    maxData logical = 0 % for z projection video
    singleFrame_reg logical = true
    inp struct = struct
end

[pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename);
currdir = split(pthenv, filesep);
currdir = currdir{end};
if ~isempty(regexp( getenv('HOSTNAME'), 'compute-', 'once' ))
    ono2 = 1;
else
    ono2 = 0;
end



if isempty(inp)

    sprintf("running flyg1 locally")
    flyg_preprocess(rootDir, recurse, overwrite, 1, 0, 0, 0, 0, 1, 0, scanimageVersion, maxData, true, singleFrame_reg)

else

    if ono2
        error("to run flyg1-scopa from O2, run cxp.sh from O2 command line (non-interactive), or pipeline_init.py from VSCode (interactive)")
    else
        if contains(inp.PTH_STORAGE_PREFIX, {'/n/files/Neurobio/wilsonlab/', '/n/scratch/users'})
            sprintf("running flyg1-scopa (cxp.sh) on remote machine via ssh")

            cmd = sprintf("ssh %s%s %s %s", inp.user, inp.remote, inp.shfile, 'inp');
            % system(cmd);
            fprintf(1, '### system: %s ###\n', cmd);
        else
            error(sprintf("to run flyg1-scopa on O2 from local machine, data must in one of the following directories: \n" + ...
                "    '/n/files/Neurobio/wilsonlab/' \n" + ...
                "    '/n/scratch/users', \n" + ...
                "set inp.dataroot to contain one of the above directories as prefix \n"))
        end
    end
end

end
