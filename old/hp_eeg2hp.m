function [ data, HP ] = hp_eeg2hp( EEG )




%% Create EEGLAB info data structure
all_fields  = fieldnames(EEG); do_not_copy = {'data','icaact'};
copy_fields = all_fields(~ismember(all_fields,do_not_copy));
for iCopy = 1:length(copy_fields)
    EEGLAB.(copy_fields{iCopy}) = EEG.(copy_fields{iCopy});
end
main_fields = {'setname','filename','filepath','subject',...
    'group', 'condition', 'session'};
for iCopy = 1:length(main_fields)
    HP.(copy_fields{iCopy}) = EEG.(copy_fields{iCopy});
end

%channels
HP.data_chan = EEG.chanlocs;
for ii = 1:length(HP.data_chan)
    HP.data_chan(ii).label = HP.data_chan(ii).labels;
    HP.data_chan(ii).index = ii;
end

%Time
struct_time = struct();
struct_time(length(EEG.times)) = struct();
for ii = 1:length(EEG.times)
    struct_time(ii).index = ii;
    struct_time(ii).value = EEG.times(ii);
    struct_time(ii).label= num2str(round(EEG.times(ii)));
    struct_time(ii).measurement= 'ms';
end
HP.data_time = struct_time;

%Epochs
[ HP.data_epoch ] = eeg_select_from_epoch( EEG.epoch);

% Back up
HP.EEGLAB = EEGLAB;

% Create used fields
HP.sys = [];
HP.proc = [];
HP.behav = [];


%% Convert to fieldtrip data structure
data = eeglab2fieldtrip( EEG, 'preprocessing', 'none' );
data.dimord = 'rpt_chan_time';

% If we need to turn the epoch data structure into a cell array
% pEpoch = HP.data_epoch;
% ep_fields = fieldnames(pEpoch);
% ti = cell(length(ep_fields),length(pEpoch));
% for iE = 1:length(pEpoch)
%     for iF = 1:length(ep_fields)
%     ti{iE,iF} = pEpoch(iE).(ep_fields{iF});
%     end
% end
% data.trialhead = ep_fields;
% data.trialinfo = ti;

data.trialinfo = HP.data_epoch';

transfer_labels = {'subject','group', 'condition', 'session'};

for iF = 1:length(transfer_labels)
    if ~isfield(data.trialinfo,transfer_labels{iF})
        for iT = 1:length(data.trialinfo)
            if isfield(EEG,transfer_labels{iF})
                data.trialinfo(iT).(transfer_labels{iF}) = EEG.(transfer_labels{iF});
            end
        end
    end
end

end

