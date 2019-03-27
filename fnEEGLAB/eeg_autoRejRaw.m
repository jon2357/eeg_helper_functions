function [ EEG, rejCell ] = eeg_autoRejRaw( incfg, EEG )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'useChans');  incfg.useChans   = []; end
if ~isfield(incfg,'outputABS'); incfg.outputABS  = []; end
if ~isfield(incfg,'setname');   incfg.setname    = []; end
if ~isfield(incfg,'iterations');incfg.iterations = {'A','B'}; end

electrodes = incfg.useChans;
wkdir      = incfg.outputABS;
rootName   = incfg.setname;
runLabels  = incfg.iterations;

if isempty(rootName); rootName = EEG.setname; end
chanLabels = {EEG.chanlocs.labels};

if isempty(electrodes)
    %select head channels to processes
    ExChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8', 'Blink', 'Horz'};
    intpolC = [];
    if isfield(EEG.etc,'chans4intpol'); intpolC = EEG.etc.chans4intpol; end
    useElectrodes = chanLabels(~ismember(chanLabels, [ExChans,intpolC]) > 0);
else
    useElectrodes = electrodes;
end
electrodeIndx  = find(ismember(chanLabels,useElectrodes));

rejCell = cell(length(runLabels),2);
for ii = 1:length(runLabels)
    disp(['Raw reject: ', runLabels{ii}])
    EEG.setname = [rootName,'-ar',runLabels{ii}];
    [EEG, rejFile ] = eeg_autoRejRaw_inline( EEG, electrodeIndx, 2,wkdir  );
    rejCell{ii,1} = rejFile;
    rejCell{ii,2} = runLabels{ii};
end

end

function [EEG,rejFile ] = eeg_autoRejRaw_inline( EEG, electrodeIndx, saveEEG,wkdir  )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if isempty(EEG.reject.rejmanual);EEG.reject.rejmanual = zeros(1,EEG.trials);end
if isempty(EEG.reject.rejmanualE);EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);end

%% Extreme Values
disp('Checking Extreme values')
cfg = [];
cfg.cutprctile = 99; 
cfg.winsize    = 400;
cfg.stepsize   = 100;
[ rejExtemeChans ] = eeg_rejExtremeStepwise(cfg, EEG.data, EEG.srate, electrodeIndx);

%% reject trends
disp('Checking Trends')
cfg = [];
[ rejTrendChans ] = eeg_rejTrends(cfg, EEG, electrodeIndx);

%% average bad trials
allregect = rejExtemeChans + rejTrendChans;
EEG.reject.rejmanualE = allregect > 0;
EEG.reject.rejmanual = sum(EEG.reject.rejmanualE) > 1;

trials2rej  = unique(find(EEG.reject.rejmanual > 0));
trials2keep = unique(find(EEG.reject.rejmanual == 0));


if ~isfield(EEG.etc,'rmCount'); EEG.etc.rmCount = {};end
addc = size(EEG.etc.rmCount,1)+1; 
EEG.etc.rmCount(addc,:) = {'autoArRaw',length(trials2rej)};

EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Total Trials Rejected: ' num2str(length(trials2rej)) ]));
EEG1 = EEG;

%% Create dataset
EEG = pop_rejepoch( EEG, trials2rej ,0);
if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1; 
EEG.etc.tCount(addc,:) = {'autoArRaw',EEG.trials};
%% save the Data
if saveEEG >= 1 && ~isempty(trials2rej)
    disp('***** Saving the pruned data *****')
    disp(['** New file created: ' wkdir '\' EEG.setname '.set **'])
    EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',wkdir);
end
rejFile = [];
if saveEEG == 2 && length(trials2keep) < EEG1.trials
    disp('***** Saving the rejected data *****')
    EEG1 = pop_rejepoch( EEG1, trials2keep ,0);
    EEG1.setname = [EEG1.setname '-rej'];
    disp(['** New file created: ' wkdir '\' EEG1.setname '.set **'])
    EEG1 = pop_saveset( EEG1, 'filename',[EEG1.setname '.set'],'filepath',wkdir);
    rejFile = [wkdir '\' EEG1.setname '.set'];
end
end

