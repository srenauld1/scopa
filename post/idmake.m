function ids = idmake(pthstacks)

arguments
    pthstacks
end

if ~iscell(pthstacks)
    pthstacks = {pthstacks};
end

for k = 1:numel(pthstacks)

    pthstacktmp = pthstacks{k};

    [fldr, fnin, ~] = fileparts(pthstacktmp);
    fldr = [fldr filesep];

    spl = strjoin(strsplit(fnin, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
    spl = strsplit(spl, '_'); %then separate by underscore

    recdate = spl{1};
    fly = spl{2};

    if contains(pthstacktmp, 'trial_') && contains(pthstacktmp, '-') %if it's a flyg-pattern raw file, trialnum and suffix need to be read differently
        trial = num2str(str2double(spl{find(strcmp(spl, 'trial'))+1}));
        suffix = 'raw';
    else
        trial = spl{3};
        suffix = strjoin(spl(4:end), '_');
    end

    recdatenum = str2double(recdate);
    flynum = str2double(fly);
    trialnum = str2double(trial);

    if strcmp(suffix(end), '_')
        suffix = suffix(1:end-1);
    end

    datefly_hyphen = [recdate '-' fly];
    recid = [recdate '_' fly '_' trial];

    ids(k).recdate = recdate;
    ids(k).fly = fly;
    ids(k).trial = trial;
    ids(k).suffix = suffix;

    ids(k).recdatenum = recdatenum;
    ids(k).flynum = flynum;
    ids(k).trialnum = trialnum;
    ids(k).recid = recid;
    ids(k).datefly_hyphen = datefly_hyphen; %for some flyg files

    ids(k).fldr = fldr;
    ids(k).pth = pthstacktmp;

end
