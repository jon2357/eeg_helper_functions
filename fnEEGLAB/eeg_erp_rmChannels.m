function [ EEGERP ] = eeg_erp_rmChannels(incfg, EEGERP )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1;incfg = []; end
if ~isfield(incfg,'remChans');
    incfg.remChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8', 'Horz','Blink'};
end
if ~isfield(incfg,'filelabel');  incfg.filelabel = '-rmEX'; end
if ~isfield(incfg,'outputABS');  incfg.outputABS = []; end
if ~isfield(incfg,'fType');      incfg.fType  = 'erp'; end
if ~isfield(incfg,'wkDir');      incfg.wkDir  = []; end

remChans = incfg.remChans;
addlbl   = incfg.filelabel;
fType    = incfg.fType;
wkDir = incfg.wkDir;

if nargin < 2;EEGERP = []; end
if isempty(EEGERP)
    [FileName,PathName,~] = uigetfile('.erp','Select an ERP file to remove EXG channels');
    file2use = [PathName FileName]; disp(file2use)
    loc  = strfind(file2use,'\');
    PathName = file2use(1:loc(end));
    FileName = file2use(loc(end)+1:end);
    eeglab; pause(.25);
    EEGERP = pop_loaderp( 'filename', FileName, 'filepath', PathName );
    wkDir = PathName;
end

chanList  = {EEGERP.chanlocs.labels};
keepInds  = find(~ismember(chanList, remChans) > 0);

disp('Removing Electrodes')
disp(remChans)
% Update file name

if strcmpi(fType,'erp')
    % Update file name
    EEGERP.erpname  = [EEGERP.erpname,addlbl];
    EEGERP.filename = [EEGERP.erpname '.erp'];
    
    % Update file data
    EEGERP.bindata  = EEGERP.bindata(keepInds,:,:);
    EEGERP.binerror = EEGERP.binerror(keepInds,:,:);
    EEGERP.nchan    = length(keepInds);
    EEGERP.chanlocs = EEGERP.chanlocs(1:length(keepInds));
    
    %Save new ERP file
    if ~isempty(wkDir)
        disp(['** Creating New File: ' wkDir '\' EEGERP.erpname '.erp **'])
        EEGERP = pop_savemyerp(EEGERP, 'erpname', EEGERP.erpname, 'filename', EEGERP.filename, 'filepath', wkDir, 'Warning', 'off');
    end
    
elseif strcmpi(fType,'eeg')
    % Update file name
    EEGERP.setname  = [EEGERP.setname,addlbl];
    EEGERP.filename = [EEGERP.setname '.set'];
    
    % Update file data
    EEGERP.data   = EEGERP.data(keepInds,:,:);
    EEGERP.nbchan = length(keepInds);
    EEGERP.chanlocs = EEGERP.chanlocs(keepInds);
    EEGERP = pop_editset(EEGERP, 'comments', char(EEGERP.comments,['Removed Chans: ' datestr(now) '; ' remChans{1:length(remChans)}]));
    
    %Save new EEG file
    if ~isempty(wkDir)
        EEGERP = pop_saveset( EEGERP, 'filename',[EEGERP.setname '.set'],'filepath',wkDir);
        disp(['** Creating New File: ' wkDir '\' EEGERP.setname '.set **'])
    end
    
end
end

