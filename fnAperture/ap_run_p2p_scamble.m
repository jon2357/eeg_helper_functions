function [ npat, sD ] = ap_run_p2p_scamble( incfg, patTrain, patTest )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% incfg = [];
% 
% % If we want to select spesific trials and remove them {label,identity}
% % (only removes trials with a NaN value in the spesified field)
% incfg.rm_ev_field{1} = {...
%     'scenes_only',{'scene_id > 0'};...
%     };
% incfg.rm_ev_field{2} = {...
%    'valinv_only',{'~strcmp(e_cond_str, ''neu'') & ~strcmp(e_cond_str, ''req'')'}; %only use valid an invalid trials
%    'valinvneu_only',{'~strcmp(e_cond_str, ''neu'')'};
%    'valinvreq_only',{'~strcmp(e_cond_str, ''req'')'};
%    };
% 
% % Selectors can exist or be added (place each selector on a new row)
% % {label,identity}, also a great place to create an identical field in both datasets
% incfg.selector{1} = {...
%     'cue_type',{'scene_str'}
%     %'scene_type',{'scene_str'}
%     };
% incfg.selector{2} = {...
%      'cue_type',{'e_cue_str'}
%      %'scene_type',{'e_scene_str'};
%     }
% % function requires regressors are added fields (place each regressor on a
% % new row {label,identity}, current only supports one regressor
% incfg.regressor = {...
%     'Rcue',{'cue_type'};...
%     };
% %Pattern spesifications {'iter'} will iterate across all datapoints on a
% %dim and an empty set will use all the datapoints on that dim
% incfg.params = {...
%     'chanbins',{{'Fp1','Fp2','Fz','Cz'},{'Pz','PO4','P4','P8'}},...
%     'timebins',[]',...
%     'freqbins',[4 7; 8 12; 16 26],...
%     };

if 0 == 1
    patTrain_file = 'Z:\Jon\proj\cuep\cuep_matlab_data\101\proc_fam_ap_1\ya101fam_ap_bs(none)_studyTrials_c(32)t(25)f(3).mat';
    patTest_file  = 'Z:\Jon\proj\cuep\cuep_matlab_data\101\proc_enc_ap_1\ya101enc_ap_bs(none)_c(32)t(45)f(3).mat';
    
    inData = load(patTrain_file); fieldn = fieldnames(inData);
    patTrain = inData.(fieldn{1});
    inData = load(patTest_file); fieldn = fieldnames(inData);
    patTest = inData.(fieldn{1});
            
    
    
    cfg.reduce_pat.chans   = {};
cfg.reduce_pat.time    = {[0 1.5]};
cfg.reduce_pat.freq    = {};

%% setup pattern analysis
cfg.rm_ev_field{1} = {'scenes_only',{'(scene_id > 0) & (cond_id == 10)'}};
cfg.rm_ev_field{2} = {...
    'valinv_only',{'~strcmp(e_cond_str, ''neu'') & ~strcmp(e_cond_str, ''req'')'}; %only use valid an invalid trials
    };
%Selectors can exist or be added (place each selector on a new row) {label,identity}
cfg.selector{1} = {'cue_type',{'scene_str'}}; %'scene_type',{'scene_str'}    | 'cue_type',{'scene_str'}
cfg.selector{2} = {'cue_type',{'e_cue_str'}}; %'scene_type',{'e_scene_str'}; | 'cue_type',{'e_cue_str'}

% function requires regressors are added fields (place each regressor on a new row {label,identity}
cfg.regressor = {'Rcue',{'cue_type'}}; %'Rscene',{'scene_type'} |  'Rcue',{'cue_type'};...

tmpA = 0:.5:1.5;
tmpTimeBins = [min(tmpA), tmpA(1:end-1);max(tmpA), tmpA(2:end)]';

cfg.params = {...
        'chanbins',{},...
        'timebins',tmpTimeBins,...
        'freqbins',[4 26; 4 7; 8 12; 16 26],...
     };
 incfg = cfg;
    incfg.reduce_pat.chans   = {};
    incfg.reduce_pat.time    = {[0 1.0]};
    incfg.reduce_pat.freq    = {[4 26]};
    
     incfg.params = {...
        'chanbins',{},...
        'timebins',[0 0.1;.1 .2; .2 .3],...
        'freqbins',[4 7; 8 12; 16 26],...
     };
 
 incfg.rm_ev_field{1} = {'scenes_only',{'scene_id > 0'}};
 incfg.rm_ev_field{2} = {...
     'valinv_only',{'~strcmp(e_cond_str, ''neu'') & ~strcmp(e_cond_str, ''req'')'}; %only use valid an invalid trials
     };
 incfg.selector{1} = {'cue_type',{'scene_str'}};
 incfg.selector{2} = {'cue_type',{'e_cue_str'}};
 incfg.regressor   = {'Rcue',{'cue_type'}};
end

if ~isfield(incfg,'number_of_reps');incfg.number_of_reps= 1; end
if ~isfield(incfg,'train_sampling');incfg.train_sampling= 'under'; end

if ~isfield(incfg,'rm_ev_field');   incfg.rm_ev_field   = {}; end
if ~isfield(incfg,'regressor');     incfg.regressor     = {}; end
if ~isfield(incfg,'selector');      incfg.selector      = {}; end
if ~isfield(incfg,'params');        incfg.params        = {'chanbins',{},'timebins',[],'freqbins',[]}; end

if ~isfield(incfg,'reduce_pat'); incfg.reduce_pat     = struct; end
%cell arrays index 1 = test, index 2 = train (if no index 2, then it uses 
% the values passed in with index 1 (training info)); see 'ap_reduce_pat'
if ~isfield(incfg.reduce_pat,'chans'); incfg.reduce_pat.chans   = {}; end  
if ~isfield(incfg.reduce_pat,'time');  incfg.reduce_pat.time    = {}; end
if ~isfield(incfg.reduce_pat,'time_avg_or_limit');  incfg.reduce_pat.time_avg_or_limit    = {2}; end
if ~isfield(incfg.reduce_pat,'freq');  incfg.reduce_pat.freq    = {}; end
if ~isfield(incfg.reduce_pat,'freq_avg_or_limit');  incfg.reduce_pat.freq_avg_or_limit    = {2}; end

if ~isfield(incfg,'folder_output_path'); incfg.folder_output_path = ''; end
if ~isfield(incfg,'auto_output_folder'); incfg.auto_output_folder = 1; end
if ~isfield(incfg,'new_source'); incfg.new_source  = ''; end
if ~isfield(incfg,'add_fld_suffix'); incfg.add_fld_suffix  = ''; end
if ~isfield(incfg,'etc'); incfg.etc = []; end

% Useful for matching dimension values (this will update training pattern
% with testing pattern values after squaring up the dimensions.
if ~isfield(incfg,'force_dim_match'); incfg.force_dim_match = {}; end %{'time','freq','chan'}

% For running a scambled label to determine chance
if ~isfield(incfg,'number_of_scramble');incfg.number_of_scramble = []; end

if ~iscell(incfg.force_dim_match); incfg.force_dim_match = {incfg.force_dim_match};end
if iscell(incfg.add_fld_suffix); incfg.add_fld_suffix = incfg.add_fld_suffix{1}; end

fNames = fieldnames(incfg.reduce_pat);
for iFN = 1:length(fNames)
    if ~iscell(incfg.reduce_pat.(fNames{iFN}))
        incfg.reduce_pat.(fNames{iFN}) = {incfg.reduce_pat.(fNames{iFN})};
    end
    if isempty(incfg.reduce_pat.(fNames{iFN}))
        incfg.reduce_pat.(fNames{iFN}) = {{}};
    end
    
    if length(incfg.reduce_pat.(fNames{iFN})) == 1
        incfg.reduce_pat.(fNames{iFN}){2} = incfg.reduce_pat.(fNames{iFN}){1};
    end
end

tic
sD = [];
sD.incfg = incfg;
sD.etc = incfg.etc;

sD.orig_name{1}  = patTrain.name;
sD.orig_file{1}  = patTrain.file;
sD.orig_source{1}= patTrain.source;

sD.orig_name{2}  = patTest.name;
sD.orig_file{2}  = patTest.file;
sD.orig_source{2}= patTest.source;

sD.new_source = incfg.new_source;
sD.add_fld_suffix = incfg.add_fld_suffix;
disp(['HP - AP: Pat 2 Pat: ', sD.orig_file{1} ,' --> ', sD.orig_file{2}]);

if isempty(sD.new_source)
    sD.new_source = sD.orig_source{2};
end


%% Modify datasets 
for iL = 1:2
    pat = []; 
    if iL == 1; pat = patTrain; end
    if iL == 2; pat = patTest; end
    
    % Remove unwanted events
    if isfield(incfg,'rm_ev_field') && ~isempty(incfg.rm_ev_field)
        inSetup = incfg.rm_ev_field{iL};
        [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
        tmpV = horzcat(sav_proc{1,:}); rmIndex = sum(tmpV,2);
        cfg = []; cfg.event_index = find(~isnan(rmIndex) == 1);
        [ pat ] = ap_reduce_pat( cfg, pat );
        sD.rm_ev_field{iL} = sav_proc;
    end
    % Setup selector
    if isfield(incfg,'selector') && ~isempty(incfg.selector)
        inSetup = incfg.selector{iL};
        [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
        sD.selector{iL} = sav_proc;
    end
    
    % Setup Regressor
    if isfield(incfg,'regressor') && ~isempty(incfg.regressor)
        inSetup = incfg.regressor;
        [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup );
        sD.regressor{iL} = sav_proc;
    end
    
    sD.reg_levels{iL} = length(sD.regressor{iL}{2});
    sD.sel_levels{iL} = length(sD.selector{iL}{2});
    sD.chance_val{iL}= 100/sD.reg_levels{iL}/100;
    
    % Reduce pattern files to match
    sD.orig_dims{iL} = size(pat.mat);
    cfg = [];
    cfg.chan = incfg.reduce_pat.chans{iL};
    cfg.time_range = incfg.reduce_pat.time{iL};
    cfg.time_avg_or_limit = incfg.reduce_pat.time_avg_or_limit{iL};
    cfg.freq_range = incfg.reduce_pat.freq{iL};
    cfg.freq_avg_or_limit = incfg.reduce_pat.freq_avg_or_limit{iL};
    [ pat ] = ap_reduce_pat( cfg, pat );
    sD.reduce_dims{iL} = size(pat.mat);
                
    % Setup default relabeling
    tmpSource = pat.source;
    def_start = regexpi(pat.source,'_c(');
    if ~isempty(def_start);tmpSource = pat.source(1:def_start-1); end
    
    lbl_c = ['c(',num2str(length(pat.dim.chan.mat)),')'];
    lbl_t = ['t(',num2str(length(pat.dim.time.mat)),')'];
    lbl_f = ['f(',num2str(length(pat.dim.freq.mat)),')'];
    lbl_suffix_reduce = ['_',lbl_c,lbl_t,lbl_f];
    pat.source = [tmpSource,lbl_suffix_reduce];
                
    if iL == 1; patTrain = pat; end
    if iL == 2; patTest = pat; end
end
trSize = size(patTrain.mat);
teSize = size(patTest.mat);
if trSize(2:end) ~= teSize(2:end)
    error(['Pattern Dims do not match (chan,time,freq): ',...
        'Train( ',num2str(size(patTrain.mat)),') Test( ',...
        num2str(size(patTest.mat)),')']);
end

if ~isempty(incfg.force_dim_match) 
    if ismember('chan',incfg.force_dim_match); patTrain.dim.chan = patTest.dim.chan; end
    if ismember('time',incfg.force_dim_match); patTrain.dim.time = patTest.dim.time;end
    if ismember('freq',incfg.force_dim_match); patTrain.dim.freq = patTest.dim.freq;end
end
%% Setup analysis labeling and default info

label_str = cell(1,3);
iterlbl = cell(1,3);
for iP = 1:2:size(incfg.params,2)
    tKey = incfg.params{iP}; tVal = incfg.params{iP+1};
    if strcmpi(tKey,'chanbins'); indx = 1; uLetter = 'c'; patDim = 'chan'; end
    if strcmpi(tKey,'timebins'); indx = 2; uLetter = 't'; patDim = 'time'; end
    if strcmpi(tKey,'freqbins'); indx = 3; uLetter = 'f'; patDim = 'freq'; end
    
    if strcmp(tVal,'iter')
        val_label = num2str(length(patTest.dim.(patDim).mat));
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

analysis_type = 'p2p_';

sD.iter_label_cell = iterlbl;
sD.analysis_type = analysis_type;
sD.reg_label = ['r(',incfg.regressor{1,1},'[',num2str(sD.reg_levels{1}),'])'];
sD.sel_label = ['s(',incfg.selector{1,1}{1},'[',num2str(sD.sel_levels{1}),'])'];

sD.proc_label = horzcat(analysis_type,sD.reg_label,sD.iter_label_cell{:});

%% Setup output folder
if ~isempty(incfg.folder_output_path)
    sD.folder_output_path = incfg.folder_output_path;
else
    slashLoc = find(sD.orig_file{2} == '/' | sD.orig_file{2} == '\');
    sD.folder_output_path = fullfile(sD.orig_file{2}(1:slashLoc(end)),'pat2pat');
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
% params.selector=incfg.selector(:,1);

%Other parameters?
params.train_sampling = incfg.train_sampling; %'under'; % 'under', 'over'
params.n_reps = incfg.number_of_reps; %500

%Classfification Type (not changing so no need to add in default values)
params.train_args=struct('penalty',10);
params.f_train=@train_logreg;
params.f_test=@test_logreg;
params.f_perfmet = @perfmet_maxclass;

% Setup pattern bins and what not
 [tmp_pat, bins] = patBins(patTrain,incfg.params{:});
 params.iter_cell= bins;

params.info.etc = incfg.etc;
params.info.dim = tmp_pat.dim;
params.info.bins = bins;

sD.params = params;

sD.file = ['sD_',sD.proc_label,sD.new_source,'.mat'];
sD.path = fullfile(sD.folder_output_path,sD.file);

%% Save details (first round, can probably skip)
%disp(['HP - AP: Saving: ',sD.path]); save(sD.path,'sD')
        
%% scramble 
sD.scramble = [];

if ~isempty(incfg.number_of_scramble) && incfg.number_of_scramble > 0
    sD.scramble.rdm_seed = rng('shuffle');
    sEV = pat.dim.ev.mat;
    orig_reg = [sEV.(incfg.regressor{1})];
    
    random_mat = nan(incfg.number_of_scramble,length(orig_reg)); %rows = random index, columns = randomized values
    for iRdm = 1:incfg.number_of_scramble
        tmpRdm_index = randperm(length(orig_reg));
        random_mat(iRdm,:) = orig_reg(tmpRdm_index);
    end
    sD.scramble.field = (incfg.regressor{1});
    sD.scramble.orig_reg = orig_reg;
    sD.scramble.random_mat = random_mat;
end

%% Run classifier (scambled the training data)
if ~isempty(incfg.number_of_scramble) && incfg.number_of_scramble > 0
    resIterCell = cell(1,size(random_mat,1));
    itpat = patTrain;
    for iRdm = 1:size(random_mat,1)
        for ii = 1:length(itpat.dim.ev.mat)
            itpat.dim.ev.mat(ii).(incfg.regressor{1}) = random_mat(iRdm,ii);
        end
        
        SDtmp = sD;
        SDtmp.proc_label = [sD.proc_label,'scram(',num2str(iRdm),')'];
        disp(['Randomization of regressors: ',num2str(iRdm),...
            '/', num2str(size(random_mat,1)),': ;',SDtmp.proc_label]);
        [npat,res]  = classify_pat2pat_mod(itpat, patTest, sD.proc_label, params);
        
        file2del = fullfile(params.res_dir,['stat_',SDtmp.proc_label,'_',itpat.source,'.mat']);
        if exist(file2del,'file'); delete(file2del); end
        resIterCell{iRdm} = reshape([res.iterations.perf],size(res.iterations));
    end
    tmpRdmPerf = cat(length(size(resIterCell{1}))+1,resIterCell{:});
    sD.scramble.perf = tmpRdmPerf;
    tmpRdmPerfmu = nanmean(tmpRdmPerf,length(size(tmpRdmPerf)));
    for i = 1:numel(res.iterations)
        res.iterations(i).perf = tmpRdmPerfmu(i);
    end
    SD.proc_label = [sD.proc_label,'scram(mu',num2str(size(random_mat,1)),')'];
    file2save = fullfile(params.res_dir,['stat_',SD.proc_label,'_',pat.source,'.mat']);
    save(file2save,'res');
else
    [npat,res]  = classify_pat2pat_mod(patTrain, patTest, sD.proc_label, params);
    %[npat, res] = classify_pat(pat,sD.proc_label, params);
end
        %pat_perf = create_perf_pattern(pat,sD.proc_label,'stat_type','acts');

        % Save classification pattern file
        [ evDS ] = ap_add_activations( npat.dim.ev.mat, res );
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
                tmpPerfC{i1,6} = length(npat.dim.chan.mat);
            else
                tmpPerfC{i1,3} = npat.dim.chan.mat(d1).label;
                tmpPerfC{i1,6} = length(sD.params.iter_cell{2}{d1});
            end
            %Time
            if ~isempty(label_str{2})
                tmpPerfC{i1,4} = label_str{2}; 
                tmpPerfC{i1,7} = length(npat.dim.time.mat);
            else
                tmpIndexVals = sD.params.iter_cell{3}{d2};
                tmpRangeVals = round([npat.dim.time.mat(tmpIndexVals).range],2);
                tmpPerfC{i1,4} = [num2str(min(tmpRangeVals)),'to',num2str(max(tmpRangeVals))];
                tmpPerfC{i1,7} = length(tmpIndexVals);
            end
            %Freq
            if ~isempty(label_str{3})
                tmpPerfC{i1,5} = label_str{3};
                tmpPerfC{i1,8} = length(npat.dim.freq.mat);
            else
                tmpIndexVals = sD.params.iter_cell{4}{d3};
                tmpRangeVals = round([npat.dim.freq.mat(tmpIndexVals).range],2);
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
                
%% Save details 
sD.proc_seconds = toc;
disp(['HP - AP: Saving: ',sD.path]); save(sD.path,'sD')
end

