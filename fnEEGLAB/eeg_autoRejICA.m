function [ EEG, rejCell ] = eeg_autoRejICA( incfg, EEG )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'useChans');  incfg.useChans   = []; end
if ~isfield(incfg,'outputABS'); incfg.outputABS  = []; end
if ~isfield(incfg,'setname');   incfg.setname    = []; end
if ~isfield(incfg,'icaSTD');    incfg.icaSTD    = 15; end
if ~isfield(incfg,'numPCA');    incfg.numPCA    = 20; end

electrodes = incfg.useChans;
wkdir      = incfg.outputABS;
rootName   = incfg.setname;
valstd     = incfg.icaSTD;
numPCA     = incfg.numPCA;

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




disp('ICA run:  1, PCA = None')
cfg = [];
cfg.icaChans  = useElectrodes;
cfg.outputABS = wkdir;
cfg.setname   = [rootName,'-ica1'];
cfg.numPCA    = [];
[ EEG ]       = eeg_runICA( cfg, EEG);

disp('ICA reject 1')
EEG.setname = [rootName,'-ica1ar'];
[ EEG, rejFile ] = eeg_autoRejICAcomps_inline( EEG,valstd, 2,wkdir);
rejCell = {rejFile, 'ica1'};

disp('ICA run 2 (with PCA)')
cfg = [];
cfg.icaChans  = useElectrodes;
cfg.outputABS = wkdir;
cfg.setname   = [rootName,'-ica2'];
cfg.numPCA    = numPCA;
[ EEG ]       = eeg_runICA( cfg, EEG);




end

function [ EEG,rejFile ] = eeg_autoRejICAcomps_inline( EEG, stdcutOff, saveEEG,wkdir )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


if ~isfield(EEG.reject,'icarejauto')
    EEG.reject.icarejauto = [];
    EEG.reject.icarejautoE = [];
end
disp(size(EEG.icaact,1))
if isempty(EEG.reject.icarejauto);EEG.reject.icarejauto = zeros(1,EEG.trials);end
if isempty(EEG.reject.icarejautoE);EEG.reject.icarejautoE = zeros(EEG.nbchan,EEG.trials);end

%% Extreme Values
if isempty(EEG.icaact)
    EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
    EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), EEG.pnts, EEG.trials);
end
disp(size(EEG.icaact,1))
disp('Checking Extreme values')
cfg = [];
cfg.threshold  = 75;
cfg.cutprctile = 99; 
cfg.winsize    = 400;
cfg.stepsize   = 100;
electrodeIndx  = 1:size(EEG.icaact,1);
[ rejExtemeChans ] = eeg_rejExtremeStepwise(cfg, EEG.icaact, EEG.srate, electrodeIndx);

EEG.reject.icarejmanualE = rejExtemeChans > 0;
EEG.reject.icarejmanual  = sum(EEG.reject.icarejmanualE) > 0;
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['ICA rej by Moving threshold: ' datestr(now)]));
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['percentile cut off: ' num2str(cfg.cutprctile) '| num Trials: ' num2str(length(find(EEG.reject.icarejmanualE > 0))) ]));

%% reject by kurtosis
if isempty(EEG.icaact)
    EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
    EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), EEG.pnts, EEG.trials);
end
disp(size(EEG.icaact,1))
EEG = pop_rejkurt(EEG,0,1:size(EEG.icaact,1) ,stdcutOff,stdcutOff*1.5,1,0);
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['ICA rej by Kurtosis: ' datestr(now)]));
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['std dev Cut Off: ' num2str(stdcutOff) '| num Trials: ' num2str(length(find(EEG.reject.icarejkurt > 0))) ]));

%% Reject by probibility
if isempty(EEG.icaact)
    EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
    EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), EEG.pnts, EEG.trials);
end
disp(size(EEG.icaact,1))
EEG = pop_jointprob(EEG,0,1:size(EEG.icaact,1) ,stdcutOff,stdcutOff*1.5,1,0);
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['ICA rej by Probibility: ' datestr(now)]));
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['std dev All: ' num2str(stdcutOff) '| num Trials: ' num2str(length(find(EEG.reject.icarejjp > 0))) ]));

EEG.reject.icarejauto  = EEG.reject.icarejkurt + EEG.reject.icarejjp  + EEG.reject.icarejmanual;
EEG.reject.icarejautoE = EEG.reject.icarejkurtE+ EEG.reject.icarejjpE + EEG.reject.icarejmanualE;

if isempty(EEG.icaact)
    EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
    EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), EEG.pnts, EEG.trials);
end

%% Reject trials and create a new dataset
trials2rej  = unique(find(EEG.reject.icarejauto > 0));
trials2keep = unique(find(EEG.reject.icarejauto == 0));

if ~isfield(EEG.etc,'rmCount'); EEG.etc.rmCount = {};end
addc = size(EEG.etc.rmCount,1)+1; 
EEG.etc.rmCount(addc,:) = {'autoArICA',length(trials2rej)};

EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Total Trials Rejected: ' num2str(length(trials2rej)) ]));
EEG1 = EEG;

EEG = pop_rejepoch( EEG, trials2rej ,0);
if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1; 
EEG.etc.tCount(addc,:) = {'autoArICA',EEG.trials};
% If there is a bufferzone on each trial, remove corrosponding buffer zones
if isfield(EEG,'buff')
    disp('Adjusting buffer Zones')
    EEG.buff.preData  = EEG.buff.preData(:,:,~ismember((1:size(EEG.buff.preData,3)), trials2rej)) ; %Remove prebuffer data
    EEG.buff.postData = EEG.buff.postData(:,:,~ismember((1:size(EEG.buff.postData,3)), trials2rej));  %Remove postbuffer data
    
    if mean([size(EEG.buff.preData,3) size(EEG.buff.postData,3) ]) == size(EEG.data,3) ~= 1
        error('EEG.buff and EEG.data not in sync');
    end
end

%% save the Data
if saveEEG >= 1
    disp('***** Saving the pruned data *****')
    EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',wkdir);
    disp(['** New file created: ' wkdir '\' EEG.setname '.set **'])
end
rejFile = [];
if saveEEG == 2 && length(trials2keep) < EEG1.trials
    disp('***** Saving the rejected data *****')
    EEG1 = pop_rejepoch( EEG1, trials2keep ,0);
    
    % If there is a bufferzone on each trial, remove corrosponding buffer zones
    if isfield(EEG,'buff')
        disp('Adjusting buffer Zones')
        EEG.buff.preData  = EEG.buff.preData(:,:,~ismember((1:size(EEG.buff.preData,3)), trials2rej)) ; %Remove prebuffer data
        EEG.buff.postData = EEG.buff.postData(:,:,~ismember((1:size(EEG.buff.postData,3)), trials2rej));  %Remove postbuffer data
        
        if mean([size(EEG.buff.preData,3) size(EEG.buff.postData,3) ]) == size(EEG.data,3) ~= 1
            error('EEG.buff and EEG.data not in sync');
        end
    end
    
    EEG1.setname = [EEG1.setname '-rej'];
    EEG1 = pop_saveset( EEG1, 'filename',[EEG1.setname '.set'],'filepath',wkdir);
    disp(['** New file created: ' wkdir '\' EEG1.setname '.set **'])
    rejFile = [wkdir '\' EEG1.setname '.set'];
end
end