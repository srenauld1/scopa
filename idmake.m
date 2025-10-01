function id = idmake(pthstacks)

% derive some identifiers using expected stack filename patterns for scopa and flyg; output in struct

arguments
    pthstacks %full path to stacks will fill all fields; if you just input stack filename, path fields will be empty; if you just input recdate_fly_trial, only those fields will be derived
end

if ~isempty(pthstacks) && ~iscell(pthstacks)
    pthstacks = {pthstacks};
end

id = [];

for k = 1:numel(pthstacks)

    pthstack = pthstacks{k};

    [pthstackdir, fn, ext] = fileparts(pthstack);
    if ~isempty(pthstackdir)
        pthstackdir = [pthstackdir filesep];
    end

    spl = strjoin(strsplit(fn, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
    spl = strsplit(spl, '_'); %then separate by underscore

    if numel(spl)<3
        error("not enough of the filename was specified to derive id data")
    end
    recdate = spl{1};
    fly = spl{2};

    if contains(fn, 'trial_') && contains(fn, '-') %if it's a flyg-pattern raw file, trialnum and suffix need to be read differently
        trial = num2str(str2double(spl{find(strcmp(spl, 'trial'))+1}));
        suffix = 'o';
    else
        trial = spl{3};
        if numel(spl)>3
            suffix = strjoin(spl(4:end), '_');
        else
            suffix = '';
        end
    end

    recdatenum = str2double(recdate);
    flynum = str2double(fly);
    trialnum = str2double(trial);

    recid = [recdate '_' fly '_' trial];
    if isempty(suffix)
        stackid = '';
        pthstack = ''; %since we don't know suffix, you must have passed in pthrec, so make pthstack empty
        pthpre = '';
        pthrec = '';
    else
        if strcmp(suffix(end), '_')
            suffix = suffix(1:end-1);
        end
        stackid = [recdate '_' fly '_' trial '_' suffix];
        pthpre = [pthstackdir stackid '_'];
        pthrec = [pthstackdir recid];
    end

    id(k).recdate = recdate;
    id(k).fly = fly;
    id(k).trial = trial;
    id(k).suffix = suffix;
    id(k).ext = ext;

    id(k).recdatenum = recdatenum;
    id(k).flynum = flynum;
    id(k).trialnum = trialnum;
    id(k).recid = recid;
    id(k).stackid = stackid;

    id(k).pthstackdir = pthstackdir;
    id(k).pthstack = pthstack;
    id(k).pthpre = pthpre;
    id(k).pthrec = pthrec;

end
