% Script is designed to ask for an epoched EEG file and will have you
% perform a manual artifact rejection on the dataset. It will open up a
% pause window, do not click continue until you have marked all trials for
% rejection and closed the epoch window. Will work for both pre and post
% ICA manual rejection, post ICA will open up the component view as well as
% the epoch view.

% Then it will create a new data set without the rejected trials, and will save which trial number
% were rejected.
%       For pre ICA trial numbers  = EEG.etc.preICArejectedTrials
%       For post ICA trial numbers = EEG.etc.postICArejectedTrials

% Finally it will take the current file name and append "-mAR" to the end
% of the set and file name. and save the new dataset in the same directory
% as the opened epoched file.

eeglab
%% Select an Epoched set file for artifact rejection
[FileName,PathName,~] = uigetfile('.set','Select a Epoched SET file');
file2use = [PathName FileName]; disp(file2use)

%% Load Epoched Dataset
EEG = pop_loadset('filename',FileName,'filepath',PathName);
EEG = eeg_checkset( EEG );

%% Setup Saving parameters
if isempty(EEG.icaweights)
    newlabel = '-mAR';
else
    newlabel = '-icAR';
end

if ~isempty(EEG.icaweights); EEG.etc.numEpochPreMAR = EEG.trials; end
if  isempty(EEG.icaweights); EEG.etc.numEpochPreMARica = EEG.trials; end

%% modulate Horz Eye and Blink Channels by reducing power in half
modeye = 1; modeye_value = 3;
if modeye == 1
    HorzBlink = {'EXG1','EXG2','EXG3','EXG4','Horz','Blink'};
    chans = {EEG.chanlocs.labels};
    inds2half  = find(ismember(chans, HorzBlink) > 0);
    EEG.data(inds2half,:,:) = EEG.data(inds2half,:,:) /modeye_value;
end
%% Voltage check after ica
%if 1 == 1
if ~isempty(EEG.icaweights)
    EEG = pop_rmbase(EEG, [ (EEG.xmin*1000) (EEG.xmax*1000)]); %rebaseline all the data to the whole epoch (may have adjusted after blink removal)
    allexChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','Horz','Blink'};
    adjustedThresChans = {'Fp1', 'Fp2', 'F7', 'F8', 'T7', 'T8'};
    adjustedThreshold_ind = find(ismember(chans, adjustedThresChans) > 0);
    
    if isfield(EEG.etc,'chans4intpol')
        inds2proc  = find(~ismember(chans, [allexChans adjustedThresChans EEG.etc.chans4intpol]) > 0);
    else
        inds2proc  = find(~ismember(chans, [allexChans adjustedThresChans]) > 0);
    end
    
    runAutoRej_select = 0;
    if runAutoRej_select == 1
        % reject by kurtosis
        % EEG = pop_rejkurt(EEG,1,[inds2proc adjustedThreshold_ind] ,6,6,1,0);
        % EEG.reject.rejmanual = EEG.reject.rejkurt ;
        % EEG.reject.rejmanualE = EEG.reject.rejkurtE;
        %
        % EEG = pop_jointprob(EEG,1,[inds2proc adjustedThreshold_ind] ,6,6,1,0);
        % EEG.reject.rejmanual   = EEG.reject.rejjp ;
        % EEG.reject.rejmanualE = EEG.reject.rejjpE;
        %rej by slope
        if isempty(EEG.reject.rejmanual);EEG.reject.rejmanual = zeros(1,EEG.trials);end
        if isempty(EEG.reject.rejmanualE);EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);end
        chans2run = [inds2proc adjustedThreshold_ind];
        
        for i = 1:length(chans2run)
            %cutOff = max(range(EEG.data(chans2run(i),:,:),2))/1.3;
            %cutOff = iqr(range(EEG.data(chans2run(i),:,:),2))*5;
            cutOff = prctile(range(EEG.data(chans2run(i),:,:),2),95);
            %disp(cutOff)
            EEG = pop_rejtrend(EEG,1,chans2run(i) ,EEG.pnts,cutOff ,.3,1,0,0);
            EEG.reject.rejmanualE(chans2run(i),:) = EEG.reject.rejconstE(chans2run(i),:);
        end
        
        
        disp(find(EEG.reject.rejmanual ==1));
        
        
        [EEG, adjIndexes] = pop_eegthresh( EEG, 1, adjustedThreshold_ind, -150, 150, EEG.xmin, EEG.xmax, 1, 0);
        adjEpochRej = EEG.reject.rejthreshE;
        [EEG, Indexes] = pop_eegthresh( EEG, 1, inds2proc, -100, 100, EEG.xmin, EEG.xmax, 1, 0);
        epochRej   = EEG.reject.rejthreshE;
        allthreshRej = adjEpochRej + epochRej;
        
        rejAuto = allthreshRej +  EEG.reject.rejconstE;
        EEG.reject.rejthreshE = allthreshRej > 0;
        EEG.reject.rejmanualE = rejAuto > 0 ;
        EEG.reject.rejmanual  = sum(EEG.reject.rejmanualE) > 1;
    end
end
%% Display and select trials based on components
if 1 == 0
    if ~isempty(EEG.icaweights)
        pop_eegplot( EEG, 0, 1, 0 );
        
        % Pause script and wait for trial selection
        f = figure;
        uicontrol('Position',[20 20 200 40],'String','Continue','Callback','uiresume(gcbf)');
        uiwait(gcf); close(f);
        
        %update trials to show up on trial rejection
        
        if isempty(EEG.reject.rejmanual);EEG.reject.rejmanual = zeros(1,EEG.trials);end
        if isempty(EEG.reject.rejmanualE);EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);end
        icaTrials2rej = find(EEG.reject.icarejmanual == 1);
        EEG.reject.rejmanual(icaTrials2rej) = 1;
        
        %EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
    end
end
%% Display raw EEG trials for rejection and ICA comparison
pop_eegplot( EEG, 1, 1, 0);

% Pause script and wait for trial selection
f = figure('Name','Close to Continue');
h = uicontrol('Position',[20 20 200 40],'String','Continue','Callback','uiresume(gcbf)');
uiwait(gcf); close(f);

%update trials to reject
trials2rej = find(EEG.reject.rejmanual > 0);
trials2keep = find(EEG.reject.rejmanual == 0);
%trials2rej = unique([find(EEG.reject.rejmanual > 0) find(EEG.reject.rejthresh > 0) find(EEG.reject.rejconst > 0)]);
%% Save trial numbers for those removed
if ~isfield(EEG.etc,'rmCount'); EEG.etc.rmCount = {};end
addc = size(EEG.etc.rmCount,1)+1;
EEG.etc.rmCount(addc,:) = {['visChk',newlabel],length(trials2rej)};
EEG = pop_editset(EEG, 'comments', char(EEG.comments,['Removing Artifacts: ' num2str(length(trials2rej))]));

%% return eye channels to original amplitude
if modeye == 1; EEG.data(inds2half,:,:) = EEG.data(inds2half,:,:) *modeye_value;end

%% Reject trials and create a new dataset
EEG1 = EEG;
EEG = pop_rejepoch( EEG, trials2rej ,0);

if ~isfield(EEG.etc,'tCount'); EEG.etc.tCount = {};end
addc = size(EEG.etc.tCount,1)+1;
EEG.etc.tCount(addc,:) = {['visChk',newlabel],EEG.trials};

%% If there is a bufferzone on each trial, remove corrosponding buffer zones
if isfield(EEG,'buff')
    disp('Adjusting buffer Zones')
    EEG.buff.preData  = EEG.buff.preData(:,:,~ismember((1:size(EEG.buff.preData,3)), trials2rej)) ; %Remove prebuffer data
    EEG.buff.postData = EEG.buff.postData(:,:,~ismember((1:size(EEG.buff.postData,3)), trials2rej));  %Remove postbuffer data
    
    if mean([size(EEG.buff.preData,3) size(EEG.buff.postData,3) ]) == size(EEG.data,3) ~= 1
        error('EEG.buff and EEG.data not in sync');
    end
end

%% Save file
EEG.setname = [EEG.setname newlabel];
EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',PathName);
disp(['** New file created: ' EEG.setname '.set | In: ' PathName '  **'])

if ~isempty(EEG.icaweights)
    [EEG] = eeg_interpolateScript(EEG, PathName);
end
%% Save rejected epochs
if ~isempty(trials2rej)
    EEG1 = pop_rejepoch( EEG1, trials2keep ,0);
    EEG1.setname = [EEG1.setname newlabel];
    EEG1.setname = [EEG1.setname,'-rej'];
    EEG1 = pop_saveset( EEG1, 'filename',[EEG1.setname '.set'],'filepath',PathName);
    disp(['** New file created: ' EEG1.setname '.set | In: ' PathName '  **'])
end
%% Log the process
try
    logABS = fileparts(which(mfilename));
    fn_LOG_output('single',logABS, mfilename, fullfile(PathName,[EEG.setname '.set']))
catch
end
eeglab redraw

try
    disp(['Num PreAutoBlink Trials: ',num2str(EEG.etc.trialsPreAutoBlink),' Current Trials: ',num2str(EEG.trials) ])
catch
end
try
    disp(['Num Original Trials: ',num2str(EEG.etc.numEpochStart),' Current Trials: ',num2str(EEG.trials) ])
catch
end
try
    disp('Trial Break Downs');disp(EEG.etc.tCount);
catch
end
disp('Done')