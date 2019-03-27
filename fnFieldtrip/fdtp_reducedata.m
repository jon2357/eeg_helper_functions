function [ t_data, f_data ] = fdtp_reducedata( incfg, data )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if 1 == 0
    data = dataC(1).data;
    incfg = [];
    incfg.frequency   = [4 7; 8 12; 16 24; 30 50];
    incfg.avgoverfreq = 'yes';
end

% if ~isfield(incfg,'channel');     incfg.channel = {}; end
% if ~isfield(incfg,'avgoverchan'); incfg.avgoverchan = []; end
%
if ~isfield(incfg,'latency');     incfg.latency = []; end
if ~isfield(incfg,'avgovertime'); incfg.avgovertime = 'yes';end

if ~isfield(incfg,'frequency');   incfg.frequency   = [];end
if ~isfield(incfg,'avgoverfreq'); incfg.avgoverfreq = 'yes';end

if ~isfield(incfg,'nanmean'); incfg.nanmean = 'yes';end

%% Get Frequency averages
f_data = data;
clear outData;
if ~isempty(incfg.frequency)
    disp('Reducing Frequency');
    useRange = incfg.frequency;
    %clear outData
    for iFreq = 1:size(useRange,1)
        if max(f_data.freq) > min(useRange(iFreq,:))
            cfg = [];
            cfg.frequency   = useRange(iFreq,:);
            cfg.avgoverfreq = incfg.avgoverfreq;
            cfg.nanmean = incfg.nanmean;
            outData(iFreq) = ft_selectdata(cfg, data);
        end
    end
    % Combine fieldtrip Data Structures
    new_dim_vals = [outData.freq];
    new_powspctrm = cat(2,outData.powspctrm);
    new_cfg = outData.cfg;
    new_cfg.frequency = useRange;
    
    % Update data
    f_data.freq = new_dim_vals;
    f_data.powspctrm = new_powspctrm;
    f_data.cfg = new_cfg;
end

%% Get Frequency averages
t_data = f_data;
clear outData;
if ~isempty(incfg.latency)
    disp('Reducing Time');
    useRange = incfg.latency;
    %clear outData
    for iTime = 1:size(useRange,1)
        if max(t_data.time) > min(useRange(iTime,:))
            cfg = [];
            cfg.latency   = useRange(iTime,:);
            cfg.avgovertime = incfg.avgovertime;
            cfg.nanmean = incfg.nanmean;
            outData(iTime) = ft_selectdata(cfg, t_data);
        end
    end
    % Combine fieldtrip Data Structures
    new_dim_vals = [outData.time];
    new_powspctrm = cat(3,outData.powspctrm);
    new_cfg = outData.cfg;
    new_cfg.time = useRange;
    
    % Update data
    t_data.time = new_dim_vals;
    t_data.powspctrm = new_powspctrm;
    t_data.cfg = new_cfg;
end

ft_checkdata(t_data);
