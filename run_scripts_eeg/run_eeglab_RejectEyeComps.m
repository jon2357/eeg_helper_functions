
[FileNam,PathNam,~] = uigetfile('.set','Select an ICA file');
file2use = [PathNam FileNam]; disp(file2use)


loc = find(file2use == '\' | file2use == '/');
FileName = file2use(loc(end)+1:end);
PathName = file2use(1:loc(end));
eeglab;
%% append the following to the set name
newlabel = '-rmEye';

%% Load and display components of selected file
EEG = pop_loadset('filename',FileName,'filepath',PathName);
EEG = eeg_checkset( EEG );
disp('Number of Trials')
disp(EEG.trials)
if isempty(EEG.icachansind); error('No ICA components found. Select a file with ICA components');end
EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
%% Auto find eye channels
try
    horzIndx  = 41; blinkIndx = 42;
    
    hData = reshape(EEG.data(horzIndx,:,:),1,[]);
    bData = reshape(EEG.data(blinkIndx,:,:),1,[]);
    hVal = nan(1,size(EEG.icaact,1));
    bVal = nan(1,size(EEG.icaact,1));
    for iICA = 1:size(EEG.icaact,1);
        icaChk = reshape(EEG.icaact(iICA,:,:),1,[]);
        
        hVal(iICA) = abs(corr(hData',icaChk'));
        bVal(iICA) = abs(corr(bData',icaChk'));
    end
    [maxHval, maxHindx] = max(hVal);
    [maxBval, maxBindx] = max(bVal);
    disp(['Blink Comp: ',num2str(maxBindx),' | Corr: ',num2str( maxBval)]);
    disp(['Horz Comp: ' ,num2str(maxHindx),' | Corr: ',num2str( maxHval)]);
    EEG.etc.bComp = [maxBindx,maxBval];
    EEG.etc.hComp = [maxHindx,maxHval];
    EEG.etc.bhCorr =[bVal',hVal'];
    
    if maxBval > .5 && maxHval > .5
        EEG.reject.gcompreject([maxHindx,maxBindx]) = 1;
    elseif maxBval > .5
        EEG.reject.gcompreject(maxBindx) = 1;
    elseif maxHval > .5
        EEG.reject.gcompreject(maxHindx) = 1;
    end
    disp(['Blink Comp: ',num2str(maxBindx),' | Corr: ',num2str( maxBval)]);
    disp(['Horz Comp: ' ,num2str(maxHindx),' | Corr: ',num2str( maxHval)]);
catch
end
%% create plots
pop_eegplot( EEG, 1, 1, 1);
pop_eegplot( EEG, 0, 1, 1);
pop_selectcomps(EEG, 1:size(EEG.icawinv,2) );


%% Wait for acknowledgement before continuing script
f = figure('Name','Close to Continue');
h = uicontrol('Position',[20 20 200 40],'String','Continue',...
    'Callback','uiresume(gcbf)');
%disp('This will print immediately');
uiwait(gcf);
%disp('This will print after you click Continue');
close(f);

%% reject componets
comps2rej = find(EEG.reject.gcompreject == 1);
disp(['Removing Components: ' num2str(comps2rej)]);

%% Removing from actual data
EEG = pop_subcomp( EEG, comps2rej, 0);
EEG = eeg_checkset( EEG );
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Removed Eye Components :' num2str(comps2rej)]));
EEG.setname = [FileName(1:end-4) newlabel];

%% Create a new dataset with eye components removed
EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',PathName);
disp(['** New file created: ' EEG.setname '.set | In: ' PathName '  **'])
disp('Number of Trials')
disp(EEG.trials)
close('all')
%eeglab redraw

%% Log the process
try
    logABS = fileparts(which(mfilename));
    fn_LOG_output('single',logABS, mfilename, fullfile(PathName,[EEG.setname '.set']))
catch
end
eeglab redraw
disp('Done')