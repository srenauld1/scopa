function [expMetadata, trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_fldr)



%% pattern metadata

try
    mdFiles = dir(fullfile(pth_fldr,['*',ids.datefly_hyphen,'_metadata_*_trial_'  sprintf( '%03d', ids.trialnum ) '.mat']));
    load(fullfile(pth_fldr,mdFiles.name),'mD');
    if isfield(mD.trialSettings,'pattern')
        patternMetadata = mD.trialSettings.pattern;
        patternMetadata.x_num = mD.trialSettings.pattern.x_num;
        patternMetadata.initialPos = mD.experiment.panels.initialPosition;
    end
    if isfield(mD,'experiment')
        if isfield(mD,'panels')
            for fn = fieldnames(mD.experiment.panels)'
                fieldData = mD.experiment.panels.(fn{1});
                if isempty(fieldData)
                    fieldData = NaN;
                end
                patternMetadata.(fn{1}) = fieldData;
            end
        end
    end
catch
    disp("couldn't load pattern metadata");
end


%% experiment metadata

expMdFile = fullfile(pth_fldr,'csv', 'expMd.csv');

if exist(expMdFile, 'file')
    expMetadata = readtable(expMdFile, 'delimiter', ',');
    expMetadata.daqSampRate = expMetadata.daqSampRate(1);
else
    disp(['using mD.sampRate because this file not found: ', expMdFile]);
    expMetadata.daqSampRate = mD.sampRate;
end

%% trial metadata

trialMetadata.usingPanels = mD.trialSettings.usingPanels;

trialMdFile = fullfile(pth_fldr, [ids.datefly_hyphen, '_trialMetadata.mat']);
if exist(trialMdFile,'file')
    load(trialMdFile, 'trialMetadata');
    trialMetadata.daqSampRate = trialMetadata.daqSampRate(trialMetadata.trialNum == ids.trialnum);
    if ~ismember(fieldnames(trialMetadata), 'optoStimTiming')
        trialMetadata.optoStimTiming = repmat({[]}, size(trialMetadata, 1), 1);
    end
else
    disp(['using mD.sampRate because this file not found: ', trialMdFile]);
    trialMetadata.daqSampRate = mD.sampRate;
end

%% fictrac metaData

fictracMetadata = mD.fictrac;
