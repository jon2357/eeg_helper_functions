function [ fdtp_stat ] = fdtp_stats_between( incfg, conCell )
% Within subject helper function
% conCell = 1 x N cell array with each cell containing a data structure
% representing the data for that condition (could be between subjects or
% trials).

%required fields for each data structure condition:
%       data: fieldtrip data structure with a condition averaged
%       label: string value with the condition label
%       n: number of epochs that went into the subject average

%Other fields that may be of use later
%       group,subject,sess

if ~isfield(incfg,'parameter');incfg.parameter = 'powspctrm'; end
if ~isfield(incfg,'statistic');   incfg.statistic   = 'indepsamplesT'; end
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

%this would be a great place to put subject, group, sess, or other info you
%want to save with the stats data structure
if ~isfield(incfg,'info');incfg.info = []; end

%% Run checks and setup internal variables
if isstruct(conCell); conCell = {conCell}; end
if ~iscell(conCell); error('Input should be a cell array of data structures'); end

lbl_head = incfg.lbl_head;
output_folder_base = incfg.output_folder_base;
freq_array = incfg.freq_array;
time_array = incfg.time_array;

if ~isempty(incfg.info) && isstruct(incfg.info)
    tF = fieldnames(incfg.info);
    for iFF = 1:length(tF)
        fdtp_stat.(tF{iFF}) = incfg.info.(tF{iFF});
    end
end
fdtp_stat.output_folder = output_folder_base;

%% Format condition output and calculate metrics for each condition

required_fields = {'label','n','data'};

if exist('conDetails','var'); clear conDetails; end
for iCon = 1:length(conCell)
    chkCon = conCell{iCon};
    con_fields = fieldnames(chkCon);
    add_fields = con_fields(~ismember(con_fields,required_fields));

    if sum(ismember(con_fields,required_fields)) ~= length(required_fields)
        error('Missing required fields, check input');
    end
      
    for ii = 1:length(add_fields)
        curr_vals = {chkCon.(add_fields{ii})};
        use_vals = curr_vals;
        if iscell(curr_vals{1})
            for i = 1:length(curr_vals)
                use_vals{i} =  curr_vals{i}{1};
            end
        end
        if length(unique(use_vals)) == 1
            use_vals = curr_vals{1};
        end
       
        conDetails(iCon).(add_fields{ii}) = use_vals; %#ok
    end

    conDetails(iCon).label = strjoin(unique({chkCon.label}),',');
    conDetails(iCon).datapts = length({chkCon.data});
    conDetails(iCon).n_mean = mean([chkCon.n]);
    conDetails(iCon).n_std = std([chkCon.n]);
    conDetails(iCon).n_lim = [min([chkCon.n]), max([chkCon.n])];
    conDetails(iCon).grand = ft_freqgrandaverage([],chkCon.data);
end

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
%% Run Within Subject Stats
stat_count = 0;

con1indx = 1; con2indx = 2; 

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
        [ stat ] = fdtp_permStatistics(cfg, {conCell{con1indx}.data},{conCell{con2indx}.data});
        
        stat_count = stat_count + 1;
        statDS(stat_count).cond_index = [con1indx, con2indx];
        statDS(stat_count).freq_range = freq_array(iFreg,:);
        statDS(stat_count).freq_avg   = freq_avg;
        statDS(stat_count).time_range = time_array(iTime,:);
        statDS(stat_count).time_avg   = time_avg;
        statDS(stat_count).stat = stat;
    end
end

%% Create difference metrics and data points for the contrasts of interest

conFields = fieldnames(conDetails);
conFieldsUse = conFields(~ismember(conFields,{'n_mean','n_std','n_lim','grand','datapts'}));

if exist('diffstruct','var'); clear diffstruct; end

con1indx = 1; con2indx = 2; 
conSelect = conDetails([con1indx, con2indx]);

diffstruct.cond_index = [con1indx, con2indx];
for iDiff = 1:length(conFieldsUse)
    chkDiff = {conSelect.(conFieldsUse{iDiff})};
    if isequal(chkDiff{con1indx},chkDiff{con2indx})
        diffstruct.(conFieldsUse{iDiff}) = chkDiff{con1indx};
    else
        diffstruct.(conFieldsUse{iDiff}) =chkDiff;
    end
end

diffstruct.datapts = [conSelect.datapts];
diffstruct.n_mean = mean([conSelect.n_mean]);
diffstruct.n_std = std([conSelect.n_std]);
diffstruct.n_lim = [min([conSelect.n_lim]), max([conSelect.n_lim])];

cfg = []; cfg.operation = 'subtract'; cfg.parameter = incfg.parameter ;
diffstruct.grand = ft_math(cfg, conSelect(con1indx).grand,conSelect(con2indx).grand);

%% Create a stats data structure (that includes the kitchen sink)

fdtp_stat.cond = conDetails;
fdtp_stat.contrast = diffstruct;
fdtp_stat.stat = statDS;

%% Save and output figures
if ~isempty(output_folder_base)
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
    
    out_base = fullfile(output_folder_base,str_tmp);
    
    % Save the data
    if ~exist(out_base,'dir'); mkdir(out_base); end
    
    file_out_base = [str_tmp,fdtp_stat.contrast.label];
    saveData  = fullfile(out_base,[file_out_base,'.mat']);
    disp(['HP: Saving: ',saveData]);
    save(saveData,'fdtp_stat');
    
    contrast_label = fdtp_stat.contrast.label;
    contrast_data = fdtp_stat.contrast.grand;
    
    %Print out data values
    for ii = 1:size(freq_array,1)
        cfg = [];
        cfg.frequency   = freq_array(ii,:);
        cfg.avgoverfreq = 'yes';
        [pdata] = ft_selectdata(cfg, contrast_data);
        
        plotLabel = contrast_label;
        out_fld = fullfile(out_base,'freq_vals');
        fdtp_plot_heatmap( pdata, plotLabel, 'freq', 'powspctrm', 1, out_fld  );
    end
    
    % Prints out stats
    for ii = 1:length(fdtp_stat.stat)
        stat_dat = fdtp_stat.stat(ii).stat;
        stat_lbl = [str_tmp,contrast_label];
        out_fld = fullfile(out_base,'freq_stat');
        fdtp_stat_output( stat_dat, stat_lbl,...
            'freq', 'stat', 1, 1, out_fld );
    end
end

