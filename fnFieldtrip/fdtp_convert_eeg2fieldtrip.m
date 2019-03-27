function [ fdtp_data,fdtp_sub ] = fdtp_convert_eeg2fieldtrip( EEG )

%% Backup eeglab information
all_fields  = fieldnames(EEG); do_not_copy = {'data','icaact'};
copy_fields = all_fields(~ismember(all_fields,do_not_copy));
for iCopy = 1:length(copy_fields)
    EEGLAB.(copy_fields{iCopy}) = EEG.(copy_fields{iCopy});
end 

%% Process EEG.epoch to return a data structure for each epoch 
[ data_epoch ] = eeg_select_from_epoch( EEG.epoch);

%% Convert to fieldtrip data structure
fdtp_data = eeglab2fieldtrip( EEG, 'preprocessing', 'none' );
fdtp_data.dimord = 'rpt_chan_time';

fdtp_data.trialinfo = data_epoch';
fdtp_data.etc.eeglab = EEGLAB;
fdtp_sub.eeglab = EEGLAB;

%% transfer some EEGLAB labels to the trial info data structure
transfer_labels = {'subject','group', 'condition', 'session'};

for iF = 1:length(transfer_labels)
    if ~isfield(fdtp_data.trialinfo,transfer_labels{iF})
        for iT = 1:length(fdtp_data.trialinfo)
            if isfield(EEG,transfer_labels{iF})
                fdtp_data.trialinfo(iT).(transfer_labels{iF}) = EEG.(transfer_labels{iF});
            end
        end
    end
end
end

