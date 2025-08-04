function id = idmake(pthstacks)

arguments
    pthstacks
end

if ~iscell(pthstacks)
    pthstacks = {pthstacks};
end

for k = 1:numel(pthstacks)

    pthstacktmp = pthstacks{k};

    [pthstackdir, fnin, ~] = fileparts(pthstacktmp);
    pthstackdir = [pthstackdir filesep];

    spl = strjoin(strsplit(fnin, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
    spl = strsplit(spl, '_'); %then separate by underscore

    recdate = spl{1};
    fly = spl{2};

    if contains(fnin, 'trial_') && contains(fnin, '-') %if it's a flyg-pattern raw file, trialnum and suffix need to be read differently
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
        pthstacktmp = ''; %since we don't know suffix, you must haver passed in pthrec, so make pthstack empty
        pthpre = '';
    else
        if strcmp(suffix(end), '_')
            suffix = suffix(1:end-1);
        end
        stackid = [recdate '_' fly '_' trial '_' suffix];
        pthpre = [pthstackdir stackid '_'];
    end

    id(k).recdate = recdate;
    id(k).fly = fly;
    id(k).trial = trial;
    id(k).suffix = suffix;

    id(k).recdatenum = recdatenum;
    id(k).flynum = flynum;
    id(k).trialnum = trialnum;
    id(k).recid = recid;
    id(k).stackid = stackid;

    id(k).pthstackdir = pthstackdir;
    id(k).pthstack = pthstacktmp;
    id(k).pthpre = pthpre;
    id(k).pthrec = [pthstackdir recid];


end
