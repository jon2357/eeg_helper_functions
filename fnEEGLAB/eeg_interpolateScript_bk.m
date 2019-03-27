function [EEG] = eeg_interpolateScript(EEG, wkdir)

if nargin < 1
    [FileName,PathName,~] = uigetfile('.set','Select a Epoched SET for Electrode Interpolation');
    file2use = [PathName FileName]; disp(file2use)
    %Load EEG .set file *(step before creating an ERP)
    eeglab;pause(.25);
    EEG = pop_loadset('filename',file2use);
    EEG = eeg_checkset( EEG );
    wkdir = PathName;
end

if nargin < 2; wkdir = [];end

if isfield(EEG.etc,'chans4intpol')
    Electrode2Interpolate = EEG.etc.chans4intpol;
    
    ExternalElectrodes = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','Horz','Blink'};
    
    % Find electrode Indicies
    disp('Getting Electrode Indices')
    chanLabels = {EEG.chanlocs.labels};
    keepInds   = find(~ismember(chanLabels, ExternalElectrodes) > 0);
    interpolateIndex = find(ismember(chanLabels, Electrode2Interpolate) > 0);
    
    %remove External Electrode
    disp('Removing External Electrodes from interpolation matrix')
    EEG1 = pop_select( EEG,'channel',chanLabels(keepInds));%#ok
    
    %Interpolate Channel:
    disp('Interpolating Electrode/s')
    EEG1 = pop_interp(EEG1, interpolateIndex, 'spherical');
    
    %place interpolated data back into original data file
    disp('Copying Interpolated electrode/s into dataset')
    EEG.data(interpolateIndex,:,:) = EEG1.data(interpolateIndex,:,:);
    
    %Save EEG Data File
    if ~isempty(wkdir)
        disp('Saving New Dataset')
        EEG.setname = [EEG.setname '-InPol'];
        EEG = pop_saveset( EEG, 'filename',[wkdir EEG.setname '.set']);
        disp(['** New file created: ' [wkdir EEG.setname '.set'] ' **'])
    end
else
    disp('No channels selected for interpolation in EEG data structure');
end

end