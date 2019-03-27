function [ pat, sD ] = ap_run_cv( incfg, pat )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% incfg = [];
% 
% %If we want to select spesific trials and remove them {label,identity}
% %(only removes trials with a NaN value in the spesified field)
% incfg.rm_ev_field = {...
%     'study_scene',{'strcmp(cond_str, ''study'') & scene_id > 0'};...
%     'study_only',{'strcmp(cond_str, ''study'')'};...
%     };
% 
% % function requires regressors are added fields (place each regressor on a
% % new row {label,identity}, current only supports one regressor
% incfg.regressor = {...
%     'scene_reg',{'scene_str'};...
%     };
% 
% %Selectors can exist or be added (place each selector on a new row)
% %{label,identity},current only supports one selector
% incfg.selector = {'block_num',{}}; %leaving the second field empty just uses that field
% 
% %Pattern spesifications {'iter'} will iterate across all datapoints on a
% %dim and an empty set will use all the datapoints on that dim
% incfg.params = {...
%     'chanbins',{{'Fp1','Fp2','Fz','Cz'},{'Pz','PO4','P4','P8'}},...
%     'timebins',[]',...
%     'freqbins',[4 7; 8 12; 16 26],...
%     };

if ~isfield(incfg,'number_of_reps');incfg.number_of_reps= 10; end
if ~isfield(incfg,'train_sampling');incfg.train_sampling= 'under'; end
if ~isfield(incfg,'rm_ev_field');   incfg.rm_ev_field   = {}; end
if ~isfield(incfg,'regressor');     incfg.regressor     = {}; end
if ~isfield(incfg,'selector');      incfg.selector      = {}; end
if ~isfield(incfg,'params');        incfg.params        = {'chanbins',{},'timebins',[],'freqbins',[]}; end
if ~isfield(incfg,'folder_output_path'); incfg.folder_output_path = ''; end
if ~isfield(incfg,'auto_output_folder'); incfg.auto_output_folder = 1; end
if ~isfield(incfg,'new_source'); incfg.new_source  = ''; end
if ~isfield(incfg,'add_fld_suffix'); incfg.add_fld_suffix  = ''; end

if ~isfield(incfg,'etc'); incfg.etc = []; end
if ~isfield(incfg,'return_each_cv'); incfg.return_each_cv = 0; end

if iscell(incfg.add_fld_suffix); incfg.add_fld_suffix = incfg.add_fld_suffix{1}; end

tic
sD = [];
sD.incfg = incfg;
sD.etc = incfg.etc;
sD.orig_name = pat.name;
sD.orig_file = pat.file;
sD.orig_source = pat.source;
sD.new_source = incfg.new_source;
sD.add_fld_suffix = incfg.add_fld_suffix;
disp(['HP - AP: Cross Validition: ', sD.orig_file]);

if isempty(sD.new_source)
    sD.new_source = sD.orig_source;
end


%% Modify dataset /
% Remove unwanted events
if isfield(incfg,'rm_ev_field') && ~isempty(incfg.rm_ev_field)
    inSetup = incfg.rm_ev_field;
    [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
    tmpV = horzcat(sav_proc{1,:}); rmIndex = sum(tmpV,2);
    cfg = []; cfg.event_index = find(~isnan(rmIndex) == 1);
    [ pat ] = ap_reduce_pat( cfg, pat );
    sD.rm_ev_field = sav_proc;
end
% Setup selector
if isfield(incfg,'selector') && ~isempty(incfg.selector)
    inSetup = incfg.selector;
    [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
    sD.selector = sav_proc;
end

% Setup Regressor
if isfield(incfg,'regressor') && ~isempty(incfg.regressor)
    inSetup = incfg.regressor;
    [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
    sD.regressor = sav_proc;
end

sD.reg_levels = length(sD.regressor{2});
sD.sel_levels = length(sD.selector{2});
sD.chance_val= 100/sD.reg_levels/100;

%% Setup analysis labeling and default info

label_str = cell(1,3);
iterlbl = cell(1,3);
for iP = 1:2:size(incfg.params,2)
    tKey = incfg.params{iP}; tVal = incfg.params{iP+1};
    if strcmpi(tKey,'chanbins'); indx = 1; uLetter = 'c'; patDim = 'chan'; end
    if strcmpi(tKey,'timebins'); indx = 2; uLetter = 't'; patDim = 'time'; end
    if strcmpi(tKey,'freqbins'); indx = 3; uLetter = 'f'; patDim = 'freq'; end
    
    if strcmp(tVal,'iter')
        val_label = num2str(length(pat.dim.(patDim).mat));
    elseif isempty(tVal)
        val_label = '1';
        label_str{indx} = 'all';
    elseif iscell(tVal)
        val_label = num2str(length(tVal));
    elseif isnumeric(tVal)
        val_label = num2str(size(tVal,1));
    else
        val_label = 'err';
    end
    
    iterlbl{indx} = [uLetter,'(',val_label,')'];
end

analysis_type = ['cv(',num2str(sD.sel_levels),')'];

sD.iter_label_cell = iterlbl;
sD.analysis_type = analysis_type;
sD.reg_label = ['r(',incfg.regressor{1,1},'[',num2str(sD.reg_levels),'])'];
sD.sel_label = ['s(',incfg.selector{1,1},'[',num2str(sD.sel_levels),'])'];

sD.proc_label = horzcat(analysis_type,sD.reg_label,sD.iter_label_cell{:});

%% Setup output folder
if ~isempty(incfg.folder_output_path)
    sD.folder_output_path = incfg.folder_output_path;
else
    slashLoc = find(sD.orig_file == '/' | sD.orig_file == '\');
    sD.folder_output_path = fullfile(sD.orig_file(1:slashLoc(end)),'cross_val');
end

if incfg.auto_output_folder == 1
    sD.folder_output_path = fullfile(sD.folder_output_path,sD.proc_label);
end

if ~isempty(sD.add_fld_suffix)
    sD.folder_output_path = [sD.folder_output_path,sD.add_fld_suffix];
end

if ~exist(sD.folder_output_path,'dir'); mkdir(sD.folder_output_path); end
%% Setup classification Parameters

% initialize the 'params' data structure
params = struct();

params.res_dir = fullfile(sD.folder_output_path,'res');
if ~exist(params.res_dir,'dir'); mkdir(params.res_dir); end
% this is a field specified in the events for my pattern,
% indicating stimulus category
%params.regressor={'scene_id'};
params.regressor=incfg.regressor(:,1);

% Select field to use as cross validation
params.selector=incfg.selector(:,1);

%Other parameters?
params.train_sampling = incfg.train_sampling; %'under'; % 'under', 'over'
params.n_reps = incfg.number_of_reps; %500

%Classfification Type (not changing so no need to add in default values)
params.train_args=struct('penalty',10);
params.f_train=@train_logreg;
params.f_test=@test_logreg;
params.f_perfmet = @perfmet_maxclass;

% Setup pattern bins and what not
[pat, bins] = patBins(pat,incfg.params{:});
params.iter_cell= bins;

params.info.etc = incfg.etc;
params.info.dim = pat.dim;
params.info.bins = bins;

sD.params = params;

sD.file = ['sD_',sD.proc_label,sD.new_source,'.mat'];
sD.path = fullfile(sD.folder_output_path,sD.file);

%% Save details (first round, can probably skip)
%disp(['HP - AP: Saving: ',sD.path]); save(sD.path,'sD')
        
%% Run classifier
        [pat, res] = classify_pat(pat,sD.proc_label, params);
        %pat_perf = create_perf_pattern(pat,sD.proc_label,'stat_type','acts');

        % Save classification pattern file
        [ evDS ] = ap_add_activations( pat.dim.ev.mat, res );
        sD.ev = evDS;
%         sD.dim.chan = pat.dim.chan;
%         sD.dim.time = pat.dim.time;
%         sD.dim.freq = pat.dim.freq;
       
        %% Grab metrics averaged across the cross validation
        rS = size(res.iterations);
        tmpPerf = nan(rS(2:end));
        tmpPerfC = cell(prod(rS(2:end)),11);
        for i1 = 1:prod(rS(2:end))
            [d1,d2,d3,d4] = ind2sub(rS(2:end),i1);
            tmpIT = res.iterations(:,d1,d2,d3,d4);
            tmpPerf(d1,d2,d3,d4) = nanmean([tmpIT.perf]);
            
            tmpPerfC{i1,1} = tmpPerf(d1,d2,d3,d4);
            tmpPerfC{i1,2} = ['c',num2str(d1),'t',num2str(d2),'f',num2str(d3)];
            
            
            %Chan
            if ~isempty(label_str{1})
                tmpPerfC{i1,3} = label_str{1};
                tmpPerfC{i1,6} = length(pat.dim.chan.mat);
            else
                tmpPerfC{i1,3} = pat.dim.chan.mat(d1).label;
                tmpPerfC{i1,6} = length(sD.params.iter_cell{2}{d1});
            end
            %Time
            if ~isempty(label_str{2})
                tmpPerfC{i1,4} = label_str{2}; 
                tmpPerfC{i1,7} = length(pat.dim.time.mat);
            else
                tmpIndexVals = sD.params.iter_cell{3}{d2};
                tmpRangeVals = round([pat.dim.time.mat(tmpIndexVals).range],2);
                tmpPerfC{i1,4} = [num2str(min(tmpRangeVals)),'to',num2str(max(tmpRangeVals))];
                tmpPerfC{i1,7} = length(tmpIndexVals);
            end
            %Freq
            if ~isempty(label_str{3})
                tmpPerfC{i1,5} = label_str{3};
                tmpPerfC{i1,8} = length(pat.dim.freq.mat);
            else
                tmpIndexVals = sD.params.iter_cell{4}{d3};
                tmpRangeVals = round([pat.dim.freq.mat(tmpIndexVals).range],2);
                tmpPerfC{i1,5} = [num2str(min(tmpRangeVals)),'to',num2str(max(tmpRangeVals))];
                tmpPerfC{i1,8} = length(tmpIndexVals);
            end

            patFeatures = (tmpPerfC{i1,6}*tmpPerfC{i1,7}*tmpPerfC{i1,8});
            tmpPerfC{i1,9} = patFeatures;
            tmpPerfC{i1,10} = [...
                'c(',num2str(tmpPerfC{i1,6}),')',...
                't(',tmpPerfC{i1,4},')',...
                'f(',tmpPerfC{i1,5},')',...
                'pf(',num2str(tmpPerfC{i1,9}),')',...
                ];
            tmpPerfC{i1,11} = {...
                ['c(',num2str(tmpPerfC{i1,6}),')'],...
                ['t(',tmpPerfC{i1,4},')'],...
                ['f(',tmpPerfC{i1,5},')'],...
                ['pf(',num2str(tmpPerfC{i1,9}),')'],...
                };
        end
        sD.perf_mat = tmpPerf;
        sD.perf_cell_labels = {'perf','index',...
            'chan_lbl','time_lbl','freq_lbl',...
            'chan_n',  'time_n',  'freq_n',...
            'features_n','label'};
        sD.perf_cell = tmpPerfC;
        
        %% Grab metrics for each cross validation
        sD.perf_crossval = [];
        if incfg.return_each_cv == 1
        tmpPerfC= cell(numel(res.iterations),6);
        for iP = 1:numel(res.iterations)
            [d1,d2,d3,d4] = ind2sub(size(res.iterations),iP);
            tmpPerfC{iP,1} = ['d[',num2str(d1),'_',num2str(d2),'_',num2str(d3),...
                '_',num2str(d4),']'];
            tmpPerfC{iP,2} = res.iterations(iP).perf;
            tmpPerfC{iP,3} = d1;
            tmpPerfC{iP,4} = pat.dim.chan.mat(d2).label;
            tmpPerfC{iP,5} = round(pat.dim.time.mat(d3).range,2);
            tmpPerfC{iP,6} = round(pat.dim.freq.mat(d4).range,2);
        end
        sD.perf_crossval = tmpPerfC;
        end
        
%% Save details 
sD.proc_seconds = toc;
disp(['HP - AP: Saving: ',sD.path]); save(sD.path,'sD')
end

