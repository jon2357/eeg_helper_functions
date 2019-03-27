function [ EEG, outFileABS ] = eeg_convertChans2nan( EEG,Chans2change,wkdir )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
% Change channel to all NaNs

% Channels to mark for interpolation (case shouldn't matter)
%Chans2change = {'F8' 'CP5' 'PO3' 'Fp2'};
if nargin < 1; EEG = []; end
if nargin < 2; Chans2change = []; end
if nargin < 3; wkdir = []; end

if isempty(EEG)
    [FileName,PathName,~] = uigetfile('.set','Select an EEG set to NaN');
    file2use = [PathName FileName]; disp(file2use);
    eeglab;
    EEG = pop_loadset('filename',FileName,'filepath',PathName);
    EEG = eeg_checkset( EEG );
    wkdir = PathName;
end

if isempty(Chans2change)
    error('No channels to NaN selected');
end


addLabel = '-cNaN';
EEG = eeg_checkset( EEG );

%Find channel indecies
index4intpol = find(ismember(lower({EEG.chanlocs.labels}), lower(Chans2change)) > 0);
chans4intpol = {EEG.chanlocs(index4intpol).labels};
disp(chans4intpol);
% Record channel label and index in EEG file
EEG.etc.index4intpol = index4intpol;
EEG.etc.chans4intpol = chans4intpol;
disp('***** Converting *****')
% Change data from indecies to NaNs
if length(size(EEG.data)) == 3; EEG.data(index4intpol,:,:) = NaN; end
if length(size(EEG.data)) == 2; EEG.data(index4intpol,:) = NaN; end
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Channels for interpolation(NaN convert): ' num2str(index4intpol)]));

EEG.setname = [EEG.setname addLabel];
outFileABS = [];
EEG = eeg_checkset( EEG );
if ~isempty(wkdir)
    disp('***** Saving the data *****')
    EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',wkdir);
    disp(['** New file created: ' wkdir '\' EEG.setname '.set **'])
    outFileABS = fullfile(wkdir,[EEG.setname '.set']);
else
    disp('Not saving data')
end
end

