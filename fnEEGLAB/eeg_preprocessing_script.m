function [EEG,outFileABS ] = eeg_preprocessing_script( incfg, EEG )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'reSamp');     incfg.reSamp     = 256; end
if ~isfield(incfg,'layout');     incfg.layout     = 'Biosemi_v3.ced'; end
if ~isfield(incfg,'lowFreq');    incfg.lowFreq    = []; end %remove frequencies below; frequency analysis: .5; ERPs: .01 | .05
if ~isfield(incfg,'highFreq');   incfg.highFreq   = []; end %remove frequencies above; frequency analysis: 125; ERPs: 40
if ~isfield(incfg,'refChans');   incfg.refChans   = {'EXG5' 'EXG6'}; end
if ~isfield(incfg,'blinkChans'); incfg.blinkChans = {'EXG3' 'EXG4'}; end
if ~isfield(incfg,'horzChans');  incfg.horzChans  = {'EXG1' 'EXG2'}; end
if ~isfield(incfg,'setname');    incfg.setname    = []; end
if ~isfield(incfg,'outputABS');  incfg.outputABS  = []; end
if ~isfield(incfg,'addfield');   incfg.addfield   = []; end
if ~isfield(incfg,'cNaN');       incfg.cNaN = []; end

%% Preprocessing of the Data
if isempty(incfg.setname)
    incfg.setname = [EEG.setname,'-preEpoch'];
end

%% update EEG datastructure with additional details (adds fields to main data structure)
if ~isempty(incfg.addfield)
    f_list = fieldnames(incfg.addfield);
    for i1 = 1:length(f_list)
        EEG.(f_list{i1}) = incfg.addfield.(f_list{i1});
    end
end

%% Resample the the data
if ~isempty(incfg.reSamp) && EEG.srate >= incfg.reSamp
    disp('*********Resampling the Data*********')
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Old Sample Rate: ' num2str(EEG.srate)]));
    EEG = pop_resample( EEG,incfg.reSamp);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['New Sample Rate: ' num2str(incfg.reSamp)]));
    EEG = eeg_checkset( EEG );
end

%% Adding Channel Location (Updated)
if ~isempty(incfg.layout)
    disp('*********Adding Channel Locations*********')
    electrodeLocations = incfg.layout;
    EEG = pop_chanedit(EEG, 'lookup',electrodeLocations);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Channel File: ' electrodeLocations]));
    EEG = eeg_checkset( EEG );
end

%% Filter the data

if ~isempty(incfg.lowFreq)
    disp(['****************** Filtering the Dataset: Removing Freq < ',num2str(incfg.lowFreq),' ********************'])
    EEG = pop_eegfiltnew(EEG, incfg.lowFreq);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Low Frequency Cutoff Filter: ' num2str(incfg.lowFreq) ' hz, All channels']));
    EEG = eeg_checkset( EEG );
end

if ~isempty(incfg.highFreq)
    disp(['****************** Filtering the Dataset: Removing Freq > ',num2str(incfg.highFreq),' ********************'])
    EEG = pop_eegfiltnew(EEG, [],incfg.highFreq);
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['High Frequency Cutoff  Filter: ' num2str(incfg.highFreq) ' hz, All channels']));
    EEG = eeg_checkset( EEG );
end

%% Rereference the Data (average of the mastiods normally)
if ~isempty(incfg.refChans)
    disp('****************** Rereferencing the Dataset ********************')
    refChans  = find(ismember({EEG.chanlocs.labels}, incfg.refChans) > 0);
    EEG = pop_reref( EEG, refChans ,'keepref','on');
    EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Referenced to: ' num2str(refChans)]));
    EEG.etc.Ref = refChans;
    EEG = eeg_checkset( EEG );
end

%% Create extra channels for blink and horizontal eye movements (bolar channels)
if ~isempty(incfg.horzChans)
    % requires ERPLAB
    disp('****************** Adding Bipolar Horzontal Eye Channel ********************')
    hIndx = find(ismember({EEG.chanlocs.labels}, incfg.horzChans) > 0);
    nCindx = size(EEG.data,1)+1;
    EEG = pop_eegchanoperator( EEG, {  ...
        ['ch',num2str(nCindx),' = (ch' num2str(hIndx(1)) ' - ch' num2str(hIndx(2)) ')*2 label Horz']} , ...
        'ErrorMsg', 'popup' );
end

if ~isempty(incfg.blinkChans)
    % requires ERPLAB
    disp('****************** Adding Bipolar Blink Eye Channel ********************')
    bIndx = find(ismember({EEG.chanlocs.labels}, incfg.blinkChans) > 0);
    nCindx = size(EEG.data,1)+1;
    EEG = pop_eegchanoperator( EEG, {  ...
        ['ch',num2str(nCindx),' = (ch' num2str(bIndx(1)) ' - ch' num2str(bIndx(2)) ') label Blink']} , ...
        'ErrorMsg', 'popup' );
end

%% Update the EEGLAB datastructure set name
EEG.setname = incfg.setname;
%% Save the Continuous Dataset
outFileABS = [];
if ~isempty(incfg.outputABS)
    disp('***** Saving the data *****')
    if ~exist(incfg.outputABS,'dir'); mkdir(incfg.outputABS); end
    EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',incfg.outputABS);
    disp(['** New file created: ' fullfile(incfg.outputABS,[EEG.setname '.set **'])])
    outFileABS = fullfile(incfg.outputABS,[EEG.setname,'.set']);
end

end


