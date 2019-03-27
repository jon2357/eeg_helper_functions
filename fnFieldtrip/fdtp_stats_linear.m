function [ fdtp_stat ] = fdtp_stats_linear( incfg, conStruct )
% Correlations and linear relationship helper function
% conStruct = 1 x N cell array with each cell containing a data structure
% representing the data for that condition 

%required fields for each data structure condition:
%       data: fieldtrip data structure with a condition averaged
%       label: string value with the condition label
%       n: number of epochs that went into the subject average
%       int_label: a label for the value
%       int_value: the value we want to test a linear relationship with

if ~isfield(incfg,'compare_groups'); incfg.compare_groups = 1; end
if ~isfield(incfg,'parameter');   incfg.parameter = 'powspctrm'; end
if ~isfield(incfg,'statistic');   incfg.statistic   = 'correlationT'; end %{'indepsamplesregrT','correlationT'};
% 'indepsamplesregrT'       independent samples regression coefficient T-statistic,
% 'correlationT'            Correlation

if ~isfield(incfg,'correctm');    incfg.correctm    = 'cluster'; end % 'no','cluster'
if ~isfield(incfg,'clusteralpha');incfg.clusteralpha = .05;end
if ~isfield(incfg,'useNeighbors');incfg.useNeighbors = 'yes'; end
if ~isfield(incfg,'minNb');       incfg.minNb       = 1; end

if ~isfield(incfg,'freq_array');incfg.freq_array = []; end
% freq_array = []; %[4 7; 8 12; 16 26];

if ~isfield(incfg,'time_array');incfg.time_array = []; end
%time_array = [];% [0 .5; .5 1; 1 1.5];

if ~isfield(incfg,'chan_cell');incfg.chan_cell = {}; end
%chan_cell = {};% {'Fz','Cz','Pz'}; 

if ~isfield(incfg,'use_reduced_time');incfg.use_reduced_time = 0; end
if ~isfield(incfg,'use_reduced_freq');incfg.use_reduced_freq = 0; end

if ~isfield(incfg,'lbl_head');incfg.lbl_head = ''; end

if ~isfield(incfg,'output_folder_base');incfg.output_folder_base = []; end

%this would be a great place to put subject, group, sess, or other info you
%want to save with the stats data structure
if ~isfield(incfg,'info');incfg.info = []; end

%% Run checks and setup internal variables
lbl_head = incfg.lbl_head;
output_folder_base = incfg.output_folder_base;
freq_array = incfg.freq_array;
time_array = incfg.time_array;
chan_cell  = incfg.chan_cell;
use_reduced_time = incfg.use_reduced_time;
use_reduced_freq = incfg.use_reduced_freq;
compare_groups = incfg.compare_groups;

if ~isempty(incfg.info) && isstruct(incfg.info)
    tF = fieldnames(incfg.info);
    for iFF = 1:length(tF)
        fdtp_stat.(tF{iFF}) = incfg.info.(tF{iFF});
    end
end
fdtp_stat.output_folder = output_folder_base;

%% Define statistic default values and variables
% Setup time point defaults
if isempty(time_array)
    time_array = 'all'; time_avg = 'no'; time_n = 1;
else
    time_avg = 'yes'; time_n = size(time_array,1);
end

%Setup frequency defaults
if isempty(freq_array)
    freq_array = 'all'; freq_avg = 'no'; freq_n = 1;
else
    freq_avg = 'yes'; freq_n = size(freq_array,1);
end

%Setup channel defaults
if isempty(chan_cell)
    chan_cell = 'all'; chan_avg = 'no';
else
    chan_avg = 'yes'; 
end

%Reduce data
if (use_reduced_freq || use_reduced_time)  && (strcmpi(freq_avg,'yes') || strcmpi(time_avg,'yes'))
    rcfg = [];
    if strcmpi(freq_avg,'yes') && use_reduced_freq
        rcfg.frequency   = freq_array;
        rcfg.avgoverfreq = 'yes';
        freq_array = 'all'; freq_avg = 'no'; freq_n = 1;
    end
    
    if strcmpi(time_avg,'yes') && use_reduced_time
        rcfg.latency = time_array;
        rcfg.avgovertime = 'yes';
        time_array = 'all'; time_avg = 'no'; time_n = 1;
    end
    
    if isstruct(rcfg)
        if exist('rCell','var'); clear rCell; end
        for ii = 1:length(conStruct)
            rCell(ii) = conStruct(ii);
            [ rCell(ii).data ] = fdtp_reducedata( rcfg, rCell(ii).data );
        end
    end
    conStruct = rCell;
    
    
end

required_fields = {'label','n','data','int_label','int_value' };

if exist('conDetails','var'); clear conDetails; end


con_fields = fieldnames(conStruct);
add_fields = con_fields(~ismember(con_fields,required_fields));

if sum(ismember(con_fields,required_fields)) ~= length(required_fields)
    error('Missing required fields, check input');
end

for ii = 1:length(add_fields)
    curr_vals = {conStruct.(add_fields{ii})};
    use_vals = curr_vals;
    if iscell(curr_vals{1})
        for i = 1:length(curr_vals)
            use_vals{i} =  curr_vals{i}{1};
        end
    end
    
    if mean(~cellfun(@isnumeric,use_vals)) == 1 && length(unique(use_vals)) == 1
        use_vals = curr_vals{1};
    end
    
    conDetails.(add_fields{ii}) = use_vals;
end

conDetails.label = strjoin(unique({conStruct.label}),',');
conDetails.datapts = length({conStruct.data});
conDetails.n_mean = mean([conStruct.n]);
conDetails.n_std = std([conStruct.n]);
conDetails.n_lim = [min([conStruct.n]), max([conStruct.n])];
conDetails.grand = ft_freqgrandaverage([],conStruct.data);
conDetails.int_label = conStruct.int_label;
conDetails.int_value = [conStruct.int_value];
conDetails.int_mean = mean([conStruct.int_value]);
conDetails.int_std = std([conStruct.int_value]);
conDetails.int_lim = [min([conStruct.int_value]), max([conStruct.int_value])];

%% Run Stats
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
        scfg = [];
        scfg.run_test = incfg.statistic;
        scfg.parameter   = 'powspctrm';
        scfg.correctm  = incfg.correctm;
        scfg.clusteralpha = incfg.clusteralpha;
        scfg.useNeighbors = incfg.useNeighbors;
        scfg.minNb = incfg.minNb;
        scfg.frequency    = freq_use;
        scfg.avgoverfreq  = freq_avg;
        scfg.latency      = time_use;
        scfg.avgovertime  = time_avg;
        scfg.chanIndx    = chan_cell;
        scfg.avgoverchan = chan_avg; 
        scfg.nanmean = 'yes';
        [regStat, corrStat] = fdtp_correlation(scfg,{conStruct.data},[conStruct.int_value]);
        
        stat_count = stat_count + 1;
        statDS(stat_count).freq_range = freq_array(iFreg,:);
        statDS(stat_count).freq_avg   = freq_avg;
        statDS(stat_count).time_range = time_array(iTime,:);
        statDS(stat_count).time_avg   = time_avg;
        statDS(stat_count).chan_cell  = chan_cell;
        statDS(stat_count).chan_avg   = chan_avg;
        statDS(stat_count).statistic  = incfg.statistic;
        statDS(stat_count).correctm  = incfg.correctm;
        if ~isempty(regStat) && isempty(corrStat)
            statDS(stat_count).stat  = regStat;
        elseif isempty(regStat) && ~isempty(corrStat)
            statDS(stat_count).stat = corrStat;
        elseif ~isempty(regStat) && ~isempty(corrStat)
            statDS(stat_count).stat(1) = corrStat;
            statDS(stat_count).stat{2} = corrStat;
        end
    end
end



%% Create a stats data structure (that includes the kitchen sink)

fdtp_stat.cond = conDetails;
fdtp_stat.stat = statDS;

%% Plotting
if ~isempty(output_folder_base)
    %Create labeling defaults
    label_con = fdtp_stat.cond.label;
    label_int = fdtp_stat.cond.int_label;
    contrast_label = ['[',label_con,']'];
    if iscell(label_con) && length(label_con) > 1
        contrast_label = ['[',strjoin(label_con,']vs['),']'];
    end
    label_mod = ['(',label_int,'_X_',contrast_label,')'];
    
    % Create Info labeling
    str_grp = ''; str_sub_n = ''; str_sess = '';
    
    if isfield(fdtp_stat,'sess') && iscell(fdtp_stat.sess)
        str_sessV  = strjoin(unique(fdtp_stat.sess),'_');
        str_grp = ['sess(',str_sessV,')'];
    end
    if isfield(fdtp_stat,'group') && iscell(fdtp_stat.group)
        str_grpV = strjoin(unique(fdtp_stat.group),'_');
        str_grp = ['grp(',str_grpV,')'];
    end
    if isfield(fdtp_stat,'subject') && iscell(fdtp_stat.subject)
        str_sub_nV = num2str(length(fdtp_stat.subject));
        str_sub_n = ['sub(',str_sub_nV,')'];
    end
    auto_str = [str_sess,str_grp,str_sub_n];
    if ~isempty(auto_str); auto_str = ['_',auto_str]; end
    str_tmp = [lbl_head,auto_str]; 
    
    % Verify / Create output folder
    out_base = fullfile(output_folder_base,str_tmp);
    if ~exist(out_base,'dir'); mkdir(out_base); end
    % Save the data
    file_out_base = [str_tmp,label_mod];
    saveData  = fullfile(out_base,[file_out_base,'.mat']);
    [ dir2out, file2out ] = fn_IncrementFileStructure('file', saveData );
    saveData = fullfile(dir2out,file2out);
    disp(['HP: Saving: ',saveData]);  save(saveData,'fdtp_stat');
    
    % Prints out stats
    for ii = 1:length(fdtp_stat.stat)
        stat_dat = fdtp_stat.stat(ii).stat;
        stat_lbl = [str_tmp,label_mod];
        
        out_fld = fullfile(out_base,'freq_sig');
        fdtp_stat_output( stat_dat, stat_lbl,...
            'freq', 'rho', 1, 1, out_fld );
        
        plotfield = 'rho';
        out_fld = fullfile(out_base,['freq_',plotfield]);
        fdtp_stat_output( stat_dat, stat_lbl,...
            'freq', plotfield, 0, 1, out_fld );
    end
end
end

