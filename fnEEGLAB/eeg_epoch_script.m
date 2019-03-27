function [ EEG ] = eeg_epoch_script( incfg, EEG )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    %clear all;

    incfg = [];
    incfg.outputABS = [];
    incfg.setname = [];
    incfg.binFile = 'C:\eegtest\test-Bins.txt';
    incfg.cNaN = {'FC5'};
    incfg.epochRange = [-1000 3000];
else
    %% Check if there is any input
    if nargin < 1; incfg = [];end
    if nargin < 2; error('requires EEG');end
end

%% Define Defaults
if ~isfield(incfg,'outputABS');  incfg.outputABS = ''; end
if ~isfield(incfg,'setname');    incfg.setname = []; end
if ~isfield(incfg,'epochRange'); incfg.epochRange = []; end
if ~isfield(incfg,'cNaN');       incfg.cNaN = {}; end
if ~isfield(incfg,'binFile');    incfg.binFile = []; end


if isempty(incfg.setname); incfg.setname = EEG.setname; end
    
subFileLbl = incfg.setname;
outDirABS  = incfg.outputABS;

%% Epoch the dataset 
disp('******** Epoching the Dataset *******')
% If this is a ERPLAB bin file epoch process
if ~isempty(incfg.binFile)
    % If there is a bin file spesified, use the ERPLAB epoching procedure
    EEG = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString',{ 'boundary' } );
    EEG = pop_binlister( EEG , 'BDF', incfg.binFile, 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
    EEG = pop_epochbin( EEG , (incfg.epochRange),  'all');
end

%Need to add EEGLAB only epoching process

%% Save and setup default info for epoched dataset
disp('***** Saving the data *****')
subFileLbl = [subFileLbl,'-ep'];
EEG.setname= subFileLbl;

if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1;
EEG.etc.tCount(addc,:) = {'allepochs',EEG.trials};

EEG = pop_saveset( EEG, 'filename',[EEG.setname,'.set'],'filepath',outDirABS);
disp(['** New file created: ' outDirABS '\' EEG.setname '.set **'])


%% This would be a good place to put the cNaN script
if ~isempty(incfg.cNaN)
    disp('******** Removing Bad Channels *******')
    Chans2change = incfg.cNaN;
    dirABS  = outDirABS;
    [ EEG ] = eeg_convertChans2nan( EEG,Chans2change,dirABS );
    EEG.setname= [subFileLbl,'-cNaN']; 
end

%% Auto artifact rejection Raw data (broken out into another script)
% disp('******** Running Auto AR the Dataset *******')
% cfg =[];
% cfg.outputABS = outDirABS;
% cfg.iterations = {'A','B'};
% [ EEG, rejRawCell ] = eeg_autoRejRaw( cfg, EEG );
% %% Check for onset blinks
% disp('******** Running Auto Onset Blinks on the Dataset *******')
% cfg =[];
% cfg.outputABS = outDirABS;
% [ EEG, ~,rejBlinks] = eeg_removeBlinkEpochs( cfg, EEG);
% 
% %% Auto artifact rejection ICA data
% cfg =[];
% cfg.outputABS = outDirABS;
% [ EEG, rejICACell ] = eeg_autoRejICA( cfg, EEG );
% 
% %% Merge reject datasets
% newFileName   = [subFileLbl,'-allrej'];
% pause(15);
% mergeSetFiles = vertcat(rejRawCell,{rejBlinks, 'Blink'},rejICACell);
% eeg_mergeSETFiles( mergeSetFiles, newFileName, outDirABS )


end

