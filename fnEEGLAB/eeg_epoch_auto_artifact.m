function [ EEG ] = eeg_epoch_auto_artifact( incfg, EEG )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    %clear all;
    
    incfg = [];
    incfg.outputABS = [];
    incfg.setname = [];
    incfg.cNaN = {'FC5'};
    incfg.ar_raw = 1;
    incfg.ar_ica = 1; 
    incfg.ar_blink = 1;
else
    %% Check if there is any input
    if nargin < 1; incfg = [];end
    if nargin < 2; error('requires EEG');end
end

%% Define Defaults
if ~isfield(incfg,'outputABS');  incfg.outputABS = ''; end
if ~isfield(incfg,'setname');    incfg.setname = []; end
if ~isfield(incfg,'cNaN');       incfg.cNaN = {}; end
if ~isfield(incfg,'ar_raw');     incfg.ar_raw = 1; end
if ~isfield(incfg,'ar_ica');     incfg.ar_ica = 1; end
if ~isfield(incfg,'ar_blink');   incfg.ar_blink = 1; end

if isempty(incfg.setname); incfg.setname = EEG.setname; end

subFileLbl = incfg.setname;
outDirABS  = incfg.outputABS;

%% This would be a good place to put the cNaN script
if ~isempty(incfg.cNaN)
    disp('******** Removing Bad Channels *******')
    Chans2change = incfg.cNaN;
    dirABS  = outDirABS;
    [ EEG ] = eeg_convertChans2nan( EEG,Chans2change,dirABS );
    subFileLbl = [subFileLbl,'-cNaN'];
end

%% Auto artifact rejection Raw data
rejRawCell = {[],'na'};
if incfg.ar_raw == 1
    disp('******** Running Auto AR the Dataset *******')
    cfg =[];
    cfg.outputABS = outDirABS;
    cfg.iterations = {'A','B'};
    [ EEG, rejRawCell ] = eeg_autoRejRaw( cfg, EEG );
end
%% Check for onset blinks
rejBlinks = [];
if incfg.ar_blink == 1
    disp('******** Running Auto Onset Blinks on the Dataset *******')
    cfg =[];
    cfg.outputABS = outDirABS;
    [ EEG, ~,rejBlinks] = eeg_removeBlinkEpochs( cfg, EEG);
end
%% Auto artifact rejection ICA data
rejICACell = {[],'na'};
if incfg.ar_ica == 1
    cfg =[];
    cfg.outputABS = outDirABS;
    [ EEG, rejICACell ] = eeg_autoRejICA( cfg, EEG );
end
%% Merge reject datasets
newFileName   = [subFileLbl,'-allrej'];
pause(15);
mergeSetFiles = vertcat(rejRawCell,{rejBlinks, 'Blink'},rejICACell);
eeg_mergeSETFiles( mergeSetFiles, newFileName, outDirABS )


end

