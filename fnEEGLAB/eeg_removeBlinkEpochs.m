function [ EEG, EEG1,rejFile ] = eeg_removeBlinkEpochs( incfg, EEG)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'chans');  incfg.chans = {'Fp1' 'Fp2' 'AF3' 'AF4' 'EXG3' 'EXG4'}; end
if ~isfield(incfg,'times');  incfg.times = [-150, 150]; end %[-150, 150; 1600, 1900];
if ~isfield(incfg,'uVlimit');incfg.uVlimit = []; end
if ~isfield(incfg,'outputABS');  incfg.outputABS = []; end
wkdir = incfg.outputABS;
%% Remove Blinks

blinkCheckChans = incfg.chans;
blinkCheckIndx  = find(ismember({EEG.chanlocs.labels},blinkCheckChans));
saveCell = cell(1,size(incfg.times,1));

for iT = 1:size(incfg.times,1)
    timeUse  = incfg.times(iT,:);
    startInd = find(EEG.times <= timeUse(1),1,'last');
    endInd   = find(EEG.times <= timeUse(2),1,'last');
    disp('Checking for Onset Blinks');
    
cfg = [];
cfg.cutprctile = 95; 
cfg.winsize    = 100;
cfg.stepsize   = 25;
cfg.startIndx  = startInd;
cfg.endIndx    = endInd;

[ rejBlinkChans ] = eeg_rejExtremeStepwise(cfg, EEG.data, EEG.srate, blinkCheckIndx);
    saveCell{iT} = rejBlinkChans;
end
    

addval = zeros(EEG.nbchan,EEG.trials);
for iS = 1:length(saveCell)
    addval = addval + saveCell{iS};
end
EEG.reject.rejmanualE = addval;
EEG.reject.rejmanual = sum(EEG.reject.rejmanualE) > 2;

tCheck = EEG.reject.rejmanualE(:,EEG.reject.rejmanual);

trials2rej  = unique(find(EEG.reject.rejmanual > 0));
trials2keep = unique(find(EEG.reject.rejmanual == 0));

if ~isfield(EEG.etc,'rmCount'); EEG.etc.rmCount = {};end
addc = size(EEG.etc.rmCount,1)+1; 
EEG.etc.rmCount(addc,:) = {'autoBlink',length(trials2rej)};


EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Total Trials Rejected for onset blinks: ' num2str(length(trials2rej)) ]));
EEG1 = EEG;

EEG = pop_rejepoch( EEG, trials2rej ,0);
EEG.setname = [EEG.setname,'-aBlink'];
if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1; 
EEG.etc.tCount(addc,:) = {'autoBlink',EEG.trials};

%% save the Data
if ~isempty(wkdir) >= 1 && ~isempty(trials2rej)
    disp('***** Saving the pruned data *****')
    EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',wkdir);
    disp(['** New file created: ' wkdir '\' EEG.setname '.set **'])
end
rejFile =[];
if length(trials2keep) < EEG1.trials
    disp('***** Saving the rejected data *****')
    EEG1.reject.rejmanualE = tCheck;
    EEG1.reject.rejmanual = sum(tCheck) > 0;
    EEG1 = pop_rejepoch( EEG1, trials2keep ,0);
    EEG1.setname = [EEG1.setname '-rejBlinks'];
    if  ~isempty(wkdir) 
    EEG1 = pop_saveset( EEG1, 'filename',[EEG1.setname '.set'],'filepath',wkdir);
    disp(['** New file created: ' wkdir '\' EEG1.setname '.set **'])
    rejFile = fullfile(wkdir,[EEG1.setname '.set']);
    end
end
