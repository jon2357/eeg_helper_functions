function [EEG ] = eeg_single_sub(incfg, EEG_ABS )
% Processes single subject using ERPLAB bin epoching functions

if 1 == 0
    %clear all;
    EEG_ABS = 'C:\eegtest\testData.set';
    incfg = [];
    incfg.group   = 'con';
    incfg.subject = 1;
    incfg.outputABS = 'C:\eegtest';
    incfg.subFileLbl = 'con1';
    incfg.epochRange = [-1000 3000];
    incfg.lowFreq  = .5;
    incfg.highFreq = 125;
    incfg.reSamp   = 256;
    incfg.session = 1;
    incfg.binFile = 'C:\eegtest\test-Bins.txt';
    incfg.cNaN = {'FC5'};
    incfg.logABS = 'C:\eegtest';
else
    %% Check if there is any input
    if nargin < 1; incfg = [];end
    if nargin < 2; error('requires EEG');end
end


%% Define Defaults
if ~isfield(incfg,'group');      incfg.group = []; end
if ~isfield(incfg,'subject');    incfg.subject = []; end
if ~isfield(incfg,'outputABS');  incfg.outputABS = []; end
if ~isfield(incfg,'subFileLbl'); incfg.subFileLbl = []; end
if ~isfield(incfg,'epochRange'); incfg.epochRange = []; end %in milliseconds
if ~isfield(incfg,'lowFreq');    incfg.lowFreq = []; end   %freq: .5, ERP: .01 | .05
if ~isfield(incfg,'highFreq');   incfg.highFreq = []; end  %freq: 125, ERP: 40
if ~isfield(incfg,'reSamp');     incfg.reSamp = []; end    % 256
if ~isfield(incfg,'session');    incfg.session = 1; end
if ~isfield(incfg,'cNaN');       incfg.cNaN = {}; end    %cell array with channels to clear (NaN) the data from
if ~isfield(incfg,'binFile');    incfg.binFile = {}; end
if ~isfield(incfg,'logABS');     incfg.logABS = {}; end

try
    %% Setup Path locations and file header
    loc  = sort(unique([strfind(EEG_ABS,'\'), strfind(EEG_ABS,'/')]));
    
    if isempty(incfg.outputABS);
        tmp_wkDir = EEG_ABS(1:loc(end));
        incfg.outputABS = tmp_wkDir;
    end
    
    if isempty(incfg.subFileLbl)
        tmp_file  = EEG_ABS(loc(end)+1:end);
        extLoc   = find(tmp_file == '.');
        incfg.subFileLbl = tmp_file(1:extLoc-1);
    end
    
    %% If output direcetory doesn't exist this will create it
    if exist(incfg.outputABS ,'dir') ~= 7; mkdir(incfg.outputABS);end
    
    %% Load EEG file
    if ~exist('EEG','var'); eeglab; end
    EEG = pop_loadset('filename',EEG_ABS);
    EEG = eeg_checkset( EEG );
    
    %% preprocess the continuous data file
    disp('******** Preprocessing the Dataset *******')
    cfg = [];
    cfg.setname   = [incfg.subFileLbl,'-preEpoch'];
    cfg.outputABS = incfg.outputABS;
    cfg.lowFreq   = incfg.lowFreq;
    cfg.highFreq  = incfg.highFreq;
    cfg.reSamp    = incfg.reSamp;
    cfg.addfield.subject = incfg.subject;
    cfg.addfield.group   = incfg.group;
    cfg.addfield.session = incfg.session;
    [EEG, ~ ] = eeg_preprocessing_script( cfg, EEG );
    
    %% Epoch the Dataset
    disp('******** Epoch Dataset *******')
    cfg = [];
    cfg.outputABS  = incfg.outputABS;
    cfg.setname    = incfg.subFileLbl;
    cfg.epochRange = incfg.epochRange;
    cfg.cNaN       = incfg.cNaN;
    cfg.binFile    = incfg.binFile;
    [ EEG ] = eeg_epoch_script( cfg, EEG );
    
    %% Run Automatic Artifact Rejection on Epoched data
    disp('******** Running Auto Artifact Rejection *******')
    cfg = [];
    cfg.outputABS  = incfg.outputABS;
    [ EEG ] = eeg_epoch_auto_artifact( cfg, EEG );
    %% Remove Eye Components
    % this is a manual part
    
    %% Double check Epoch files and manually reject uncorrected trials
    % this is a manual part
    
    %% After manual AR
    % Use the file to do stats / erp / TF analysis
    %% Logging
    fn_LOG_output('single',incfg.logABS, mfilename, EEG_ABS)
catch ME
    fn_LOG_output('error', incfg.logABS, mfilename, EEG_ABS, ME)
end

end
