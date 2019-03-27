function [ ERP] = eeg_fn_createERPLAB( incfg, EEG)
%% random code to create a subject averaged file
% erpname = 'test';
% wkDir   = pwd;
% baselineVal = [-600 -100];
% incfg.procType   = 'erp'  | 'tfft' default: 'erp'

if ~isfield(incfg,'lpFilt');       incfg.lpFilt    = []; end
if ~isfield(incfg,'erpname');      incfg.erpname   = []; end
if ~isfield(incfg,'wkDir');        incfg.wkDir     = []; end
if ~isfield(incfg,'baselineVal');  incfg.baselineVal  = []; end
if ~isfield(incfg,'tfftTime');     incfg.tfftTime   = [EEG.times(1),EEG.times(end)]; end
if ~isfield(incfg,'addbins');      incfg.addbins    = []; end
if ~isfield(incfg,'procType');     incfg.procType   = 'erp'; end
if ~isfield(incfg,'interpolate');  incfg.interpolate   = 'no'; end
if ~isfield(incfg,'saveEEG');      incfg.saveEEG   = 'no'; end
if ~isfield(incfg,'rmChans');      incfg.rmChans   = []; end

lpFilt      = incfg.lpFilt;
erpname     = incfg.erpname;
wkDir       = incfg.wkDir;
baselineVal = incfg.baselineVal;
tfftTime    = incfg.tfftTime;
addbins     = incfg.addbins;
procType    = incfg.procType;
interpolate = incfg.interpolate;
saveEEG     = incfg.saveEEG;
rmChans     = incfg.rmChans;

if exist(wkDir,'dir') == 0; mkdir(wkDir); end

%% interpolate channels if need be
if strcmpi(interpolate,'yes')
    [EEG] = eeg_interpolateScript(EEG, wkDir);
end
%% Remove spesified baseline
if ~isempty(baselineVal)
    EEG = pop_rmbase( EEG, baselineVal);
    EEG = eeg_checkset( EEG );
end
%% Save EEG if requested
if strcmpi(saveEEG,'yes')
    EEG.setname = erpname;
    EEG = pop_saveset( EEG, 'filename',fullfile(wkDir,[EEG.setname,'.set']));
    disp(['** New file created: ' fullfile(wkDir,[EEG.setname,'.set']) ' **'])
end


%% Create subject averaged ERPLAB file (ERP and TFFT)

%ERP
if strcmpi(procType, 'erp')
    EEG = pop_syncroartifacts(EEG, 'Direction','bidirectional'); %Update EVENTLIST data structure with Rejected epochs
    ERP = pop_averager( EEG , 'Criterion', 'all', 'ExcludeBoundary', 'on', 'SEM', 'on' );
    if ~isempty(addbins)
        ERP = pop_binoperator( ERP, addbins);
    end
    if ~strcmpi(rmChans,'no')
        ERP = eeg_erp_rmChannels(rmChans, ERP );
    end
    if ~isempty(lpFilt)
        erpname = [erpname,'_LP(',num2str(lpFilt),')'];
        ERP = pop_filterp( ERP,  1:ERP.nchan , 'Cutoff',  lpFilt, 'Design', 'butter', 'Filter', 'lowpass', 'Order',  2 );
    end
    
    ERP = pop_savemyerp(ERP, 'erpname', erpname, 'filename',[erpname,'.erp'], 'filepath', wkDir, 'Warning', 'off');
    
    % print out number of trials per bin:
    ABSpathFile = fullfile(wkDir,[erpname,'.txt']);
    outCell = [ERP.bindescr' num2cell(ERP.ntrials.accepted')];
    fn_print_OutCell_v1( outCell, ABSpathFile )
end

%TFFT
if strcmpi(procType, 'tfft')
    EEG = pop_syncroartifacts(EEG, 'Direction','bidirectional'); %Update EVENTLIST data structure with Rejected epochs
    ERP = pop_averager( EEG , 'Compute', 'TFFT','Criterion', 'all', 'ExcludeBoundary', 'on', 'SEM', 'on', 'TaperWindow', {'hanning' tfftTime} );
    
    if ~isempty(addbins)
        ERP = pop_binoperator( ERP, addbins);
    end
    
    if ~strcmpi(rmChans,'no')
        ERP = eeg_erp_rmChannels(rmChans, ERP );
    end
    
    ERP = pop_savemyerp(ERP, 'erpname', [erpname,'-TFFT'], 'filename',[erpname,'-TFFT.erp'], 'filepath', wkDir, 'Warning', 'off');
    
    % print out number of trials per bin:
    ABSpathFile = fullfile(wkDir,[erpname,'-TFFT.txt']);
    outCell = [ERP.bindescr' num2cell(ERP.ntrials.accepted')];
    fn_print_OutCell_v1( outCell, ABSpathFile )

end

end