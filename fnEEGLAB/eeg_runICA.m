function [ EEG ] = eeg_runICA( incfg, EEG)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'icaChans');  incfg.icaChans = []; end
if ~isfield(incfg,'numPCA');    incfg.numPCA = []; end
if ~isfield(incfg,'outputABS'); incfg.outputABS = []; end
if ~isfield(incfg,'setname');   incfg.setname = []; end
%% Run ICA
if ~isempty(incfg.setname);
    EEG.setname = incfg.setname;
else
    EEG.setname = [EEG.setname,'-ica'];
end

chanLabels = {EEG.chanlocs.labels};
if isempty(incfg.icaChans); incfg.icaChans = chanLabels; end
icaIndx = find(ismember(chanLabels, [incfg.icaChans]) > 0);

%Save number of trials before ICA
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Pre ICA trial Count: ' num2str(EEG.trials)]));
if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1; 
EEG.etc.tCount(addc,:) = {'preICA',EEG.trials};


disp('***** Running ICA *****')
t1 = tic;
if isempty(incfg.numPCA)
    EEG = pop_runica(EEG, 'extended',1,'interupt','off', 'chanind', icaIndx);
else
    EEG = pop_runica(EEG, 'extended',1,'interupt','off', 'chanind', icaIndx,'pca',incfg.numPCA);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Ran ICA using a PCA first: ' num2str(incfg.numPCA) ' components']));
end
EEG = eeg_checkset( EEG );
    t2 =  toc(t1);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Ran ICA: ' datestr(now) '; time: ' num2str(t2/60) ' mins']));

EEG = eeg_checkset( EEG );

    % Save the ICA Dataset
if ~isempty(incfg.outputABS);
        disp('***** Saving the data *****')       
        EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',incfg.outputABS);
        disp(['** New file created: ' incfg.outputABS '\' EEG.setname '.set **'])   
end
    
end

