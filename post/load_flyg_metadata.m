function [md, expMetadata, trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_flyg_md, pth_fldr, md)

% optionally output the original flyg metadata division into expMetadata, trialMetadata, patternMetadata, fictracMetadata
% also add scopa md to consolidate metadata fields relevant to scopa pipeline

%% pattern metadata

try
    load(pth_flyg_md,'mD');

    if ~mD.trialSettings.usingPanels
        error("no panels data")
    end

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

try
    expMetadata = readtable(expMdFile, 'delimiter', ',');
    expMetadata.daqSampRate = expMetadata.daqSampRate(1);
catch
    disp("couldn't load expMd");
end

%% trial metadata

trialMdFile = fullfile(pth_fldr, [ids.datefly_hyphen, '_trialMetadata.mat']);
trialMetadata = [];
if exist(trialMdFile,'file')
    load(trialMdFile, 'trialMetadata');
    trialMetadata.daqSampRate = trialMetadata.daqSampRate(trialMetadata.trialNum == ids.trialnum);
    if ~ismember(fieldnames(trialMetadata), 'optoStimTiming')
        trialMetadata.optoStimTiming = repmat({[]}, size(trialMetadata, 1), 1);
    end
end

%% fictrac metaData

fictracMetadata = mD.fictrac;


%% defaults

if ~exist('patternMetadata', 'var')
    patternMetadata = struct;
end

if isfield(patternMetadata,'arenaExtent')
    patternMetadata.arenaExtent = patternMetadata.arenaExtent;
else
    patternMetadata.arenaExtent = 360;
    warning('experiment.arenaExtent missing in experiment CSV, using md.arenaExtent: 360 degrees')
end

if isfield(patternMetadata,'initialAngle')
    patternMetadata.initialAngle = patternMetadata.initialAngle;
else
    patternMetadata.initialAngle = -9.375;
    warning('experiment.initialAngle missing in experiment CSV, using md.initialAngle: 90 degrees')
end

if isfield(patternMetadata,'ball')
    patternMetadata.ball_diameter = patternMetadata.ball;
else
    patternMetadata.ball_diameter = 9;
    warning('fictrac.ball.diameter missing in experiment CSV, using ball diameter: 9 mm')
end

if isfield(patternMetadata,'patternLuminance')
    patternMetadata.luminance = patternMetadata.patternLuminance;
else
    patternMetadata.luminance = 1;
    warning('experiment.patternLuminance missing in experiment CSV, using G3 pattern md.luminance: 1')
end

if isfield(patternMetadata,'yDimxDimRelationship')
    patternMetadata.yDimxDim = patternMetadata.yDimxDimRelationship;
else
    patternMetadata.yDimxDim = 1;
    warning('experiment.yDimxDimRelationship missing in experiment CSV, using G3 yDimxDimRelationship: 1')
end

if isfield(patternMetadata,'cuePosAngleRelationship')
    patternMetadata.cuePosAngleRel = patternMetadata.cuePosAngleRelationship;
else
    patternMetadata.cuePosAngleRel = 1;
    warning('experiment.cuePosAngleRel missing in experiment CSV, using G3 md.cuePosAngleRel: 1')
end


%% assign some metadata to scopa metadata struct 'md'

md.rateft = fictracMetadata.fictracRate;
md.ratedaq = mD.sampRate;
md.ball_diameter = patternMetadata.ball_diameter;


