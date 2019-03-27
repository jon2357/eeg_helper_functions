function [ fdtp_stat ] = fdtp_stats_group_within(incfg, subDS, contrast_cell )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    incfg = [];
    incfg.statistic = 'depsamplesT';
    incfg.correctm  = 'no';
    incfg.clusteralpha = .1;
    incfg.useNeighbors= 'yes';
    
    contrast_cell = {...
        'vis_hitHigh','vis_missHitLow';...
        'vis_hit','vis_cr';...
        };
end
% subDS = struct(); %struct array of subject datasets with fields
% subDS(iS).sel_cond = cell array with a label in each column
% subDS(iS).sel_data = cell array with a dataset in each column

% contrast_cell = {...
%     'cond1','cond2';...
%     'cond1','cond3';...
%     'cond2','cond3';...
%     };
%    incfg = [];

%% Running Statistics
if ~isfield(incfg,'statistic');   incfg.statistic   = 'depsamplesT'; end
%   incfg.statistic     = [] <-- Default;
%                         'indepsamplesT'           independent samples T-statistic,(for compairing between groups or trials)
%                         'indepsamplesF'           independent samples F-statistic,
%                         'indepsamplesregrT'       independent samples regression coefficient T-statistic,
%                         'indepsamplesZcoh'        independent samples Z-statistic for coherence,
%                         'depsamplesT'             dependent samples T-statistic,(for compairing within subject conditions)
%                         'depsamplesFmultivariate' dependent samples F-statistic MANOVA,
%                         'depsamplesregrT'         dependent samples regression coefficient T-statistic,
%                         'actvsblT'                activation versus baseline T-statistic.

if ~isfield(incfg,'correctm');    incfg.correctm    = 'cluster'; end
if ~isfield(incfg,'clusteralpha');incfg.clusteralpha = .05;end
% apply multiple-comparison correction:
% incfg.correctm       = 'no', 'max', cluster', 'bonferroni', 'holm', 'hochberg', 'fdr' (default = 'no')
if ~isfield(incfg,'useNeighbors');incfg.useNeighbors= 'yes'; end
%% Output the data
if ~isfield(incfg,'folder_output_path');  incfg.folder_output_path = []; end
% incfg.folder_output_path = string variable with the absolute path to
% where we want to output the data
if ~isfield(incfg,'set_name');            incfg.set_name = []; end
% Change the set_name if you like, otherwise it makes its own
if ~isfield(incfg,'print_summary_stats'); incfg.print_summary_stats = 1; end

%% stuff
set_name = incfg.set_name;
folder_output_path  = incfg.folder_output_path;
print_summary_stats = incfg.print_summary_stats;

%% Run Within Subject Stats

% Create a difference plot for each
stat_count = 0; %clear fdtp_stat
for iCon = 1:size(contrast_cell)
    tic
    cond_labels = contrast_cell(iCon,:);
    cond_cell = {}; cond_count = 0;
    for iS = 1:length(subDS)
        indxOrder = zeros(1,2);
        % find the index numbers in order requested
        for iiC = 1:2
            tmpIndx = find(ismember(subDS(iS).sel_cond,cond_labels{iiC}));
            % check if there is an actual dataset
            if ~isempty(subDS(iS).sel_data{tmpIndx}); indxOrder(iiC) = tmpIndx; end
        end
        % if data is found for both Create cell array to pass data into
        if sum(indxOrder > 0) == 2
            cond_count = cond_count + 1;
            cond_cell{1}{cond_count} = subDS(iS).sel_data{indxOrder(1)};
            cond_cell{2}{cond_count} = subDS(iS).sel_data{indxOrder(2)};
        end
    end
    
    %% Create a grand average and difference wave for the dataset
    if ~isempty(cond_cell)
        [grandavg1] = ft_freqgrandaverage([],cond_cell{1}{:});
        [grandavg2] = ft_freqgrandaverage([],cond_cell{2}{:});
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.operation = 'subtract';
        granddiff = ft_math(cfg, grandavg1, grandavg2);
        
        % Run Stats
        cfg = [];
        cfg.statistic = incfg.statistic;
        cfg.correctm  = incfg.correctm;
        cfg.clusteralpha = incfg.clusteralpha;
        cfg.useNeighbors = incfg.useNeighbors;
        [ stat ] = fdtp_permStatistics(cfg, cond_cell{1},cond_cell{2});
        
        tmpfdtp = [];
        tmpfdtp.stat_date  = fix(clock);
        tmpfdtp.statistic  = cfg.statistic;
        tmpfdtp.multi_comp = cfg.correctm;
        tmpfdtp.stat_label = ['(',cond_labels{1},')vs(',cond_labels{2},')'];
        tmpfdtp.stat_c1 = cond_labels{1};
        tmpfdtp.n_c1 = length(cond_cell{1});
        tmpfdtp.stat_c2 = cond_labels{2};
        tmpfdtp.n_c2 = length(cond_cell{2});
        tmpfdtp.cond_labels = cond_labels;
        tmpfdtp.stat = stat;
        tmpfdtp.proc_time = toc;
        tmpfdtp.ga_c1 = grandavg1;
        tmpfdtp.ga_c2 = grandavg2;
        tmpfdtp.ga_diff = granddiff;
        
        stat_count = stat_count + 1;
        fdtp_stat(stat_count) = tmpfdtp;
        
    end
    
end

if ~isempty(folder_output_path)
    % Save the stats files
    if isempty(set_name)
        if isfield(subDS,'group')
            grpstr = strjoin(unique({subDS.group}),'_');
        else
            grpstr = 'na';
        end
        grp_lbl  = grpstr;
        stat_lbl = ['sub(',num2str(length(subDS)),')con(', num2str(length(fdtp_stat)),')'];
        set_name = ['grp(',grp_lbl,')',stat_lbl,'within'];
    end
    
    path_file_output = fullfile(folder_output_path,set_name);
    if ~exist(path_file_output,'dir'); mkdir(path_file_output);end
    save(fullfile(path_file_output,[set_name,'.mat']), 'fdtp_stat');
    
    if print_summary_stats == 1
        for ii = 1:length(fdtp_stat)
            pStat = fdtp_stat(ii).stat;
            if ~isempty(pStat)
                new_labels = {fdtp_stat(ii).stat_label};
                fld_out = fullfile(path_file_output,'freq');
                fdtp_stat_output( pStat, new_labels,...
                    'freq', 'stat', 1, 1, fld_out );
            end
        end
    end
    
end

