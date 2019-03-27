function [ HP ] = hp_update_from_fltp( data, HP, add_replace_fields )
%Update the HP from the fieldtrip info

if nargin < 3; add_replace_fields = []; end

% Update Channel information
if isfield(HP,'data_chan') && isfield(data,'label')
    HP.data_chan = HP.data_chan(ismember({HP.data_chan.label},data.label));
else
    HP.data_chan = [];
    for ii = 1:length(data.label)
        HP.data_chan(ii).index = ii;
        HP.data_time(ii).label = data.label{ii};
    end
end

% Update time series information
if isfield(data,'time')
    HP.data_time = [];
    for ii = 1:length(data.time)
        HP.data_time(ii).index = ii;
        HP.data_time(ii).value = data.time(ii);
        if iscell(data.time(ii))
            HP.data_time(ii).label = num2str(round(data.time{ii},3));
        elseif isnumeric(data.time(ii))
            HP.data_time(ii).label = num2str(round(data.time(ii),3));
        end
        HP.data_time(ii).measurement = 'sec';
    end
end

%Update frequency information
if isfield(data,'freq')
    HP.data_freq = [];
    for ii = 1:length(data.freq)
        HP.data_freq(ii).index = ii;
        HP.data_freq(ii).value = data.freq(ii);
        HP.data_freq(ii).label = num2str(round(data.freq(ii),1));
        HP.data_freq(ii).measurement = 'Hz';
    end
end

% Uses the data structure 'add_replace_fields' to replace or add to the HP
% data structure

if ~isempty(add_replace_fields)
    proc_fields = fieldnames(add_replace_fields);
    for ii = 1:length(proc_fields)
        HP.(proc_fields{ii}) = add_replace_fields.(proc_fields{ii});
    end
end
end

