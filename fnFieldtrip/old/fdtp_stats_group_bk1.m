function [ fdtp_stat ] = fdtp_stats_group( incfg, conDS )
% Within subject helper function
% conDS = data structure array, where each index represents a participant
% c1_* = condition 1 info, c2_* = condition 2 info

%required fields:
%       c1_data: fieldtrip data structure with a condition averaged
%       c1_label: string value with the condition label
%       c1_n: number of epochs that went into the subject average
%
%       c2_data: fieldtrip data structure with a condition averaged
%       c2_label: string value with the condition label
%       c2_n: number of epochs that went into the subject average
%Other fields that may be of use later
%       group,subject,
if ~isfield(incfg,'statistic');   incfg.statistic   = 'depsamplesT'; end
% 'depsamplesT'             dependent samples T-statistic,(for compairing within subject conditions)
% 'indepsamplesT'           independent samples T-statistic,(for compairing between groups or trials)

if ~isfield(incfg,'correctm');    incfg.correctm    = 'cluster'; end % 'no','cluster'
if ~isfield(incfg,'clusteralpha');incfg.clusteralpha = .05;end
if ~isfield(incfg,'useNeighbors');incfg.useNeighbors = 'yes'; end

if ~isfield(incfg,'freq_array');incfg.freq_array = []; end
% freq_array = []; %[4 7; 8 12; 16 26];

if ~isfield(incfg,'time_array');incfg.time_array = []; end
%time_array = [];% [0 .5; .5 1; 1 1.5];

if ~isfield(incfg,'lbl_head');incfg.lbl_head = ''; end
if ~isfield(incfg,'output_folder_base');incfg.output_folder_base = []; end

lbl_head = incfg.lbl_head;
output_folder_base = incfg.output_folder_base;

%% Run Function
freq_array = incfg.freq_array;
time_array = incfg.time_array;

required_fields = {'c1_label','c1_n','c1_data','c2_label','c2_n','c2_data'};
conDS_fields = fieldnames(conDS);
cp_fields = conDS_fields(~ismember(conDS_fields,required_fields));

for ii = 1:length(cp_fields)
    curr_field = cp_fields{ii};
    curr_vals = {conDS.(curr_field)};
    fdtp_stat.(curr_field) = curr_vals;
end

fdtp_stat.c1_label = strjoin(unique({conDS.c1_label}),'-');
fdtp_stat.c1_n_mean= mean([conDS.c1_n]);
fdtp_stat.c1_n_std = std([conDS.c1_n]);
fdtp_stat.c1_n_lim = [min([conDS.c1_n]), max([conDS.c1_n])];
fdtp_stat.c1_grand = ft_freqgrandaverage([],conDS.c1_data);

fdtp_stat.c2_label = strjoin(unique({conDS.c2_label}),'-');
fdtp_stat.c2_n_mean= mean([conDS.c2_n]);
fdtp_stat.c2_n_std = std([conDS.c2_n]);
fdtp_stat.c2_n_lim = [min([conDS.c2_n]), max([conDS.c2_n])];
fdtp_stat.c2_grand = ft_freqgrandaverage([],conDS.c2_data);

fdtp_stat.d_label = ['[',fdtp_stat.c1_label,']vs[',fdtp_stat.c2_label,']'];
cfg = [];
cfg.operation = 'subtract';
cfg.parameter = 'powspctrm';
fdtp_stat.d_grand = ft_math(cfg, fdtp_stat.c1_grand,fdtp_stat.c2_grand);

%% Setup Within subject stats
if isempty(time_array)
    time_array = 'all'; time_avg = 'no'; time_n = 1;
else
    time_avg = 'yes'; time_n = size(time_array,1);
end
if isempty(freq_array)
    freq_array = 'all'; freq_avg = 'no'; freq_n = 1;
else
    freq_avg = 'yes'; freq_n = size(freq_array,1);
end

%% Run Within Subject Stats
stat_count = 0;
if exist('statDS','var'); clear statDS; end
for iTime = 1:time_n
    if isnumeric(time_array)
        time_use = time_array(iTime,:);
    else
        time_use = time_array;
    end
    for iFreg = 1:freq_n
        if isnumeric(freq_array)
            freq_use = freq_array(iFreg,:);
        else
            freq_use = freq_array;
        end
        
        % Run Stats
        cfg = [];
        cfg.statistic = incfg.statistic;
        cfg.correctm  = incfg.correctm;
        cfg.clusteralpha = incfg.clusteralpha;
        cfg.useNeighbors = incfg.useNeighbors;
        cfg.frequency    = freq_use;
        cfg.avgoverfreq  = freq_avg;
        cfg.latency      = time_use;
        cfg.avgovertime  = time_avg;
        [ stat ] = fdtp_permStatistics(cfg, {conDS.c1_data},{conDS.c2_data});
        
        stat_count = stat_count + 1;
        statDS(stat_count).freq_range = freq_array(iFreg,:);
        statDS(stat_count).time_range = time_array(iTime,:);
        statDS(stat_count).stat = stat;
    end
end

fdtp_stat.stat = statDS;

fdtp_stat.conDS.c1_label ={conDS.c1_label};
fdtp_stat.conDS.c1_n ={conDS.c1_n};
fdtp_stat.conDS.c2_label ={conDS.c2_label}; 
fdtp_stat.conDS.c2_n ={conDS.c2_n};



%% Save and output figures
if ~isempty(output_folder_base)
    str_grp = ''; str_sub_n = ''; str_sess = '';
    if isfield(fdtp_stat,'group') && iscell(fdtp_stat.group)
        str_grp = strjoin(unique(fdtp_stat.group),'_');
    end
    if isfield(fdtp_stat,'subject') && iscell(fdtp_stat.subject)
        str_sub_n = num2str(length(fdtp_stat.subject));
    end
    if isfield(fdtp_stat,'sess') && iscell(fdtp_stat.sess)
        str_sess  = strjoin(unique(fdtp_stat.sess),'_');
    end
    
    str_tmp = [lbl_head,str_sess,'_grp(',str_grp,')sub(',str_sub_n,')'];
    out_base = fullfile(output_folder_base,str_tmp);
    
    % Save the data
    if ~exist(out_base,'dir'); mkdir(out_base); end
    file_out_base = [str_tmp,fdtp_stat.d_label];
    saveData  = fullfile(out_base,[file_out_base,'.mat']);
    disp(['HP: Saving: ',saveData]);
    save(saveData,'fdtp_stat');
    
    %Print out data values
    for ii = 1:size(freq_array,1)
        cfg = [];
        cfg.frequency   = freq_array(ii,:);
        cfg.avgoverfreq = 'yes';
        [pdata] = ft_selectdata(cfg, fdtp_stat.d_grand);
        
        plotLabel = fdtp_stat.d_label;
        out_fld = fullfile(out_base,'freq_vals');
        fdtp_plot_heatmap( pdata, plotLabel, 'freq', 'powspctrm', 1, out_fld  );
    end
    % Prints out stats
    for ii = 1:length(fdtp_stat.stat)
        stat_dat = fdtp_stat.stat(ii).stat;
        stat_lbl = [str_tmp,fdtp_stat.d_label];
        out_fld = fullfile(out_base,'freq_stat');
        fdtp_stat_output( stat_dat, stat_lbl,...
            'freq', 'stat', 1, 1, out_fld );
    end
end

