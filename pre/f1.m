
function [] = f1(rootDir, recurse, overwrite, scanimageVersion, maxData, singleFrame_reg)

% Default settings
arguments
    rootDir char = '' % 'SCOPAPATH, SCOPABRANCH' (two substrings separated by comma and whitespace) will run scopa, path to data will run flyg
    recurse double = 0 % number of levels to recurse, looking for experimental folders
    overwrite logical = false
    scanimageVersion double = 2019.1
    maxData logical = 0 % for z projection video
    singleFrame_reg logical = true
end

if ~isempty(regexp( getenv('HOSTNAME'), 'compute-', 'once' ))
    ono2 = 1;
else
    ono2 = 0;
end

[pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename);
currdir = split(pthenv, filesep);
currdir = currdir{end};


if contains(rootDir, 'scopa')

    if ono2
        error("to run flyg1-scopa from O2, run cxp.sh from O2 command line (non-interactive), or pipeline_init.py from VSCode (interactive)")
    else

        rootDir = strsplit(rootDir, ', ');
        if numel(rootDir)>3
            error("rootDir not formatted correctly for running scopa, must be 'SCOPAPATH, SCOPABRANCH'")
        end
        scopapath = rootDir{1};
        scopabranch = rootDir{2};
        o2_user = rootDir{3};
        [statusout, scopabranch_original] = system('git symbolic-ref refs/remotes/origin/HEAD');
        scopabranch_original = strsplit(scopabranch_original, '/');
        scopabranch_original = strtrim(scopabranch_original{end});
        % if any(strcmp(scopabranch, {scopabranch_original, 'main', 'origin', 'origin/main', 'master', 'origin/master'})) %the original branch name, and other possibilities that are pointless but just in case
        %     error(sprintf("scopa branch should be your own, not '" + scopabranch_original + "'"))
        % end
        pthpre = [scopapath filesep 'pre' filesep 'bash' filesep];
        pthfile = [pthpre 'cxp.sh'];
        if contains(regexp(fileread(pthfile), 'PTH_STORAGE_PREFIX=(\S*)', 'match'), {'/n/files/Neurobio/wilsonlab/', '/n/scratch/users'})
            sprintf("running flyg1-scopa (cxp.sh) on O2 from local machine \n MAKE SURE YOU ARE LOGGED IN IF OFF CAMPUS")
            pause(3) %to make sure sees above message

            pth_remote = '@o2.hms.harvard.edu';
            pth_cxp_on_o2 = ['/home/' o2_user '/scopa/pre/bash/cxp.sh']; %assume they put in their home folder

            statusout = system(['cd ' scopapath filesep 'pre' filesep 'bash' filesep]);
            statusout = system(['git checkout ' scopabranch]);
            if statusout==1
                error("system command failed")
            end
            system('git add . ');
            system('git commit -m "scopasend"');
            system('git push');

            cmdcd = ['cd /home/' o2_user '/scopa; git checkout ' scopabranch '; git pull;' pth_cxp_on_o2];
            statusout = system(sprintf("ssh %s%s %s", o2_user, pth_remote, cmdcd));


        else
            error(sprintf("to run flyg1-scopa on O2 from local machine, data must in one of the following directories: \n" + ...
                "    '/n/files/Neurobio/wilsonlab/' \n" + ...
                "    '/n/scratch/users', \n" + ...
                "set inp.dataroot to contain one of the above directories as prefix \n"))
        end
    end

else

    sprintf("running flyg1 locally")
    flyg_preprocess(rootDir, recurse, overwrite, 1, 0, 0, 0, 0, 1, 0, scanimageVersion, maxData, true, singleFrame_reg)

end

end
