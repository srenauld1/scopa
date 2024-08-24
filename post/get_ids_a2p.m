function [ids, recdate, fly, trial, suffix, recdatenum, flynum, trialnum, recid, datefly_hyphen] = get_ids_a2p(pthstack)

%for portability, also outputs ids, a struct collecting all other outputs

[~, fnin, ~] = fileparts(pthstack);

spl = strjoin(strsplit(fnin, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
spl = strsplit(spl, '_'); %then separate by underscore

recdate = spl{1};
fly = spl{2};

if contains(pthstack, 'trial_') && contains(pthstack, '-') %if it's a flyg-pattern raw file, trialnum and suffix need to be read differently
    trial = spl(find(strcmp(spl, 'trial'))+1);
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

ids.recdate = recdate;
ids.fly = fly;
ids.trial = trial;
ids.suffix = suffix;

ids.recdatenum = recdatenum;
ids.flynum = flynum;
ids.trialnum = trialnum;
ids.recid = recid;
ids.datefly_hyphen = datefly_hyphen; %for some flyg files

