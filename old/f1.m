
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
        error("to run flyg1-scopa from O2, run pl.sh from O2 command line (non-interactive), or pl.py from VSCode (interactive)")
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
        if ~strcmp(o2_user, 'caw846') && any(strcmp(scopabranch, {scopabranch_original, 'main', 'origin', 'origin/main', 'master', 'origin/master'})) %the original branch name, and other possibilities that are pointless but just in case
            error("scopa branch should be your own, not '" + scopabranch_original + "'")
        end
        pthpre = [scopapath filesep 'pre' filesep 'bash' filesep];
        pthfile = [pthpre 'pl.sh'];
        if contains(regexp(fileread(pthfile), 'PTH_STORAGE_PREFIX=(\S*)', 'match'), {'/n/files/Neurobio/wilsonlab/', '/n/scratch/users'})
            sprintf("running flyg1-scopa (pl.sh) on O2 by sending command from this matlab script running on your local machine \n" + ...
                "MAKE SURE YOU HAVE YOUR OWN BRANCH OF SCOPA ON YOUR LOCAL MACHINE : \n" + ...
                "MAKE SURE YOU HAVE CLONED SCOPA INTO YOUR O2 HOME DIRECTORY (NAVIGATE THERE FROM O2 COMMAND LINE WITH 'cd ~') : \n" + ...
                "MAKE SURE YOU HAVE SET UP SSH KEY AS DESCRIBED HERE: https://harvardmed.atlassian.net/wiki/spaces/O2/pages/2051211265/VSCode+and+Code+Server+on+O2#SSH-Keys")
            prompt = 'do you want to add/commit/push all local scopa changes to remote, then pull to O2, then run pl.sh on O2? type 1 for yes, type 0 for no: ';
            commandwindow();
            proceed_o2 = input(sprintf(prompt));

            if proceed_o2
                pth_remote = '@o2.hms.harvard.edu';
                pth_pl_dir_on_o2 = ['/home/' o2_user '/scopa/pre/bash']; %assume they put in their home folder

                str = ['cd ' scopapath filesep 'pre' filesep 'bash' filesep '; '...
                    'git checkout ' scopabranch '; ' ...
                    'git add .; ' ...
                    'git commit -m "scopasend"; ' ...
                    'git push; ' ...
                    ];
                [statusout, strout] = system(str)


                str = ['ssh ' o2_user pth_remote '; cd /home/' o2_user '/scopa; git checkout ' scopabranch '; git pull; cd ' pth_pl_dir_on_o2 '; pl.sh'];
                [statusout, strout] = system(str)
            end
        else
            error("to run flyg1-scopa on O2 from local machine, data must in one of the following directories: " + newline + ...
                "    '/n/files/Neurobio/wilsonlab/'" + newline + ...
                "    '/n/scratch/users'" + newline +  ...
                "set inp.dataroot to contain one of the above directories as prefix" + newline)
        end
    end

else

    sprintf("running flyg1 locally")
    flyg_preprocess(rootDir, recurse, overwrite, 1, 0, 0, 0, 0, 1, 0, scanimageVersion, maxData, true, singleFrame_reg)

end

end
